import 'package:camera_app/new_to_keep/delete_confimation.dart';
import 'package:camerawesome/src/widgets/buttons/timer_controller.dart';
import 'package:camera_app/new_to_keep/video_progress_indicator.dart';
import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:camerawesome/pigeon.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'dart:io';
import 'package:video_player/video_player.dart';
import 'package:sizer/sizer.dart';

import 'new_to_keep/app_config.dart';

// Constants for consistent aspect ratio
const kPreferredAspectRatio = CameraAspectRatios.ratio_16_9;
const kPreferredAspectRatioValue = 16.0 / 9.0;

void main() {
  runApp(
    Sizer(
      builder: (context, orientation, deviceType) {
        return MaterialApp(home: const CameraAwesomeApp());
      },
    ),
  );
}

class CameraAwesomeApp extends StatelessWidget {
  const CameraAwesomeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Multi Video Recorder',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.dark,
      ),
      home: const CameraPage(),
    );
  }
}

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  // Store all recorded video paths
  final List<String> _recordedVideos = [];
  bool _justRecorded = false;

  List<int> _preselectedVideoDurations = [30, 45, 60, 120];

  int _selectedDurationInSeconds = 120; // default 2 minutes

  bool _usingUltra = false;
  bool _hasUltraWide = false; // Track if device has ultra-wide capability
  final _cameraApi = CameraInterface();

  late TimerController _timerController;

  @override
  void initState() {
    super.initState();
    _checkUltraWideSupport();
    _timerController = TimerController(
      themeApp: AwesomeTheme(bottomActionsBackgroundColor: Colors.transparent),
      onTimerComplete: _handleTimerComplete,
      onTimerStateChanged: () {
        // Refresh UI when timer state changes
        if (mounted) setState(() {});
      },
    );
  }

  // Check if the device has ultra-wide camera support
  Future<void> _checkUltraWideSupport() async {
    try {
      final sensors = await _cameraApi.getBackSensors();
      final hasUltraWide = sensors.any(
          (sensor) => sensor?.sensorType == PigeonSensorType.ultraWideAngle);

      if (mounted) {
        setState(() {
          _hasUltraWide = hasUltraWide;
        });
      }

      if (!hasUltraWide && mounted) {
        // ScaffoldMessenger.of(context).showSnackBar(
        //   const SnackBar(
        //     content: Text('Ultra-wide camera not available on this device'),
        //     duration: Duration(seconds: 3),
        //   ),
        // );
      }

      debugPrint('Ultra-wide camera available: $_hasUltraWide');
    } catch (e) {
      debugPrint('Error checking camera sensors: $e');
    }
  }

  // 1. State variable to track durations
  final List<Duration> _recordedVideosDurations = [];

  Future<Duration> getVideoDuration(String path) async {
    try {
      final controller = VideoPlayerController.file(File(path));
      await controller.initialize();
      final duration = controller.value.duration;
      await controller.dispose();
      return duration;
    } catch (e) {
      debugPrint('Error getting video duration: $e');
      return Duration.zero;
    }
  }

  bool _showDeleteConfirmation = false;
  bool noMoreRecordings = false;
  @override
  Widget build(BuildContext context) {
    AppConfig _appConfig = AppConfig(context);
    return Stack(
      children: [
        Scaffold(
          body: CameraAwesomeBuilder.awesome(
            theme:
                AwesomeTheme(bottomActionsBackgroundColor: Colors.transparent),
            saveConfig: SaveConfig.video(
              videoOptions: VideoOptions(
                enableAudio: true,
                ios: CupertinoVideoOptions(
                  fps: 30,
                  codec: CupertinoCodecType.h264,
                ),
                android: AndroidVideoOptions(
                  bitrate: 1200000,
                  fallbackStrategy: QualityFallbackStrategy.lower,
                ),
                quality: VideoRecordingQuality.fhd,
              ),
              mirrorFrontCamera: true,
            ),
            sensorConfig: SensorConfig.single(
              sensor: Sensor.position(
                SensorPosition.back,
              ),
              flashMode: FlashMode.auto,
              aspectRatio: kPreferredAspectRatio,
              zoom: 0.0,
            ),

            enablePhysicalButton: true,
            onMediaCaptureEvent: (event) {
              // Only handle video events
              if (!event.isVideo) return;

              switch (event.status) {
                case MediaCaptureStatus.capturing:
                  // Reset the justRecorded flag when starting a new recording
                  if (mounted) {
                    setState(() => _justRecorded = false);
                  }
                  break;
                case MediaCaptureStatus.success:
                  event.captureRequest.when(
                    single: (single) async {
                      final videoPath = single.file?.path;
                      if (videoPath != null && mounted) {
                        // Get actual duration from video file
                        final duration = await getVideoDuration(videoPath);

                        setState(() {
                          _recordedVideos.add(videoPath);
                          _recordedVideosDurations.add(duration);
                          _justRecorded = true;
                        });
                      }
                    },
                    multiple: (multiple) {
                      multiple.fileBySensor.forEach((key, value) {
                        final path = value?.path;
                        if (path != null && mounted) {
                          setState(() {
                            _recordedVideos.add(path);
                          });
                        }
                      });

                      if (mounted) {
                        setState(() => _justRecorded = true);
                      }
                    },
                  );
                  break;
                case MediaCaptureStatus.failure:
                  break;
              }
            },
            onMediaTap: (media) {
              // Handle media tap if needed
            },

            topActionsBuilder: (state) {
              // Get the current sensor position using the correct property path

              return AwesomeTopActions(
                state: state,
                padding: EdgeInsets.only(
                    left: AppConfig(context).deviceWidth(2),
                    top: AppConfig(context).deviceHeight(1),
                    right: AppConfig(context).deviceWidth(2)),
                children: [
                  VideoRecordingProgress(
                    state: state is VideoRecordingCameraState ? state : null,
                    previousRecordingsDurations: _recordedVideosDurations,
                    maxDuration: _selectedDurationInSeconds / 60.0,
                    stop: () {
                      if (state is VideoRecordingCameraState) {
                        state.stopRecording();
                        setState(() {
                          noMoreRecordings = true;
                        });
                      }
                    },
                  ),
                ],
                ultraWide: [
                  Visibility(
                    visible: _hasUltraWide,
                    child: IconButton(
                      icon: Icon(
                        Icons.filter_center_focus,
                        color: _usingUltra ? Colors.amber : Colors.white,
                      ),
                      tooltip: _usingUltra ? 'Ultra-wide on' : 'Ultra-wide off',
                      onPressed: () {
                        // flip your boolean
                        setState(() => _usingUltra = !_usingUltra);
                        // now call into the native side with the new sensor list
                        _cameraApi.setSensor(
                          _usingUltra
                              ? [
                                  PigeonSensor(
                                      type: PigeonSensorType.ultraWideAngle,
                                      position: PigeonSensorPosition.back)
                                ]
                              : [
                                  PigeonSensor(
                                      type: PigeonSensorType.wideAngle,
                                      position: PigeonSensorPosition.back)
                                ],
                        );
                      },
                    ),
                  ),
                  Visibility(
                    visible:
                        _recordedVideos.isEmpty && state is VideoCameraState,
                    child: Center(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            final currentIndex = _preselectedVideoDurations
                                .indexOf(_selectedDurationInSeconds);
                            final nextIndex = (currentIndex + 1) %
                                _preselectedVideoDurations.length;
                            _selectedDurationInSeconds =
                                _preselectedVideoDurations[nextIndex];
                          });
                        },
                        child: Container(
                          width: _appConfig.deviceWidth(15),
                          height: _appConfig.deviceHeight(5),
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.black12,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _selectedDurationInSeconds >= 60
                                ? "${_selectedDurationInSeconds ~/ 60} min"
                                : "${_selectedDurationInSeconds} sec",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (state is VideoCameraState)
                    _timerController.buildElegantTimerSelector(context)
                ],
              );
            },

            // Use custom layout builders to provide the reset functionality
            middleContentBuilder: (state) {
              return Column(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (state is PhotoCameraState && state.hasFilters)
                    AwesomeFilterWidget(state: state)
                  else if (!kIsWeb && Platform.isAndroid)
                    AwesomeZoomSelector(
                      state: state,
                      theme: AwesomeTheme(
                        bottomActionsBackgroundColor: Colors.transparent,
                      ),
                    ),

                  // always reserve the same space, but only show the IconButton when needed

                  Visibility(
                    visible: _recordedVideos.isNotEmpty,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 16.0, bottom: 16.0),
                      child: IconButton(
                        icon: const Icon(Icons.backspace, color: Colors.white),
                        tooltip: 'Delete last video',
                        onPressed: _showDeleteConfirmationDialog,
                      ),
                    ),
                  ),
                ],
              );
            },

            bottomActionsBuilder: (state) {
              // For recording state, we don't show the Next button
              if (state is VideoRecordingCameraState) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AwesomeBottomActions(
                      state: state,
                    ),
                  ],
                );
              }

              return Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AwesomeBottomActions(
                    state: state,
                    captureButton: ProductionCaptureButton(
                      state: state,
                      timerController: _timerController,
                      onTap: () {
                        if (!noMoreRecordings) {
                          if (state is VideoRecordingCameraState) {
                            // Already recording, stop recording
                            state.stopRecording();
                          } else if (!_timerController.isTimerActive) {
                            // Not recording and timer not active, start timer or record
                            _timerController.startTimerCountdown(state);
                          } else {
                            // Timer is active, cancel it
                            _timerController.cancelTimer();
                          }
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Max duration allowed while recording has been reached'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                    ),
                    right: (_justRecorded)
                        ? Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: ElevatedButton(
                              onPressed: _navigateToGallery,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 12),
                              ),
                              child: const Text(
                                'Next',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          )
                        : Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: ElevatedButton(
                              onPressed: null, // ← null disables it
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors
                                    .blue, // enabled color (ignored when disabled)
                                disabledBackgroundColor: Colors.white
                                    .withOpacity(0.4), // what you actually see
                                disabledForegroundColor: Colors
                                    .black, // text/icon color when disabled
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                              ),
                              child: const Text(
                                'Next',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  // color here is overridden by disabledForegroundColor
                                ),
                              ),
                            ),
                          ),
                  ),
                ],
              );
            },
          ),
        ), // The overlay - when showing it completely blocks interaction with anything underneath
        if (_showDeleteConfirmation && _recordedVideos.isNotEmpty)
          DeleteConfirmationOverlay(
            // videoPath: _recordedVideos.last,
            onConfirm: _deleteLastVideo,
            onCancel: _cancelDelete,
          ),

        if (_timerController.isTimerActive)
          Scaffold(
              backgroundColor: Colors.transparent,
              body: Center(
                child: Container(
                  height: 150,
                  width: 150,
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Text(
                      '${_timerController.currentTimerSeconds}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 80,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              )),
      ],
    );
  }

  void dispose() {
    _timerController.dispose();
    super.dispose();
  }

  void _handleTimerComplete(CameraState state) {
    // Use the same pattern as in AwesomeCaptureButton
    state.when(
      onPhotoMode: (photoState) => photoState.takePhoto(),
      onVideoMode: (videoState) {
        videoState.startRecording();
        _timerController.cancelTimer();
      },
      onVideoRecordingMode: (videoState) {
        // Already recording, do nothing
      },
      onPreparingCamera: (preparingState) {
        // Camera not ready
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Camera is not ready yet'),
            duration: Duration(seconds: 2),
          ),
        );
      },
    );
  }

  // Show confirmation dialog
  void _showDeleteConfirmationDialog() {
    if (_recordedVideos.isEmpty) return;
    setState(() => _showDeleteConfirmation = true);
  }

// Cancel deletion
  void _cancelDelete() {
    setState(() => _showDeleteConfirmation = false);
  }

  // Function to delete the last recorded video
  void _deleteLastVideo() {
    if (_recordedVideos.isNotEmpty) {
      final lastVideoPath = _recordedVideos.last;

      // Remove from the list first
      setState(() {
        _recordedVideos.removeLast();

        if (_recordedVideosDurations.isNotEmpty) {
          _recordedVideosDurations.removeLast();
        }
        noMoreRecordings = false;

        // If no videos left, reset the flag
        if (_recordedVideos.isEmpty) {
          _justRecorded = false;
        }
        _showDeleteConfirmation = false;
      });

      // Attempt to delete the file from storage
      try {
        final file = File(lastVideoPath);
        if (file.existsSync()) {
          file.deleteSync();

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Last recording deleted'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        debugPrint('Error deleting video file: $e');
      }
    }
  }

  void _navigateToGallery() {
    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (context) => VideoGalleryPage(
          videos: _recordedVideos,
        ),
      ),
    )
        .then((_) {
      // Reset the "just recorded" flag when returning from gallery
    });
  }
}

// Gallery page to view and play recorded videos
class VideoGalleryPage extends StatelessWidget {
  final List<String> videos;

  const VideoGalleryPage({
    super.key,
    required this.videos,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Recorded Videos'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: videos.isEmpty
            ? const Center(child: Text('No videos recorded yet'))
            : GridView.builder(
                padding: const EdgeInsets.all(8),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio:
                      kPreferredAspectRatioValue, // Using constant
                ),
                itemCount: videos.length,
                itemBuilder: (context, index) {
                  final videoPath = videos[index];
                  return VideoThumbnail(
                    videoPath: videoPath,
                    onTap: () => _navigateToVideoPlayer(context, videoPath),
                  );
                },
              ),
      ),
    );
  }

  void _navigateToVideoPlayer(BuildContext context, String videoPath) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => VideoPlayerPage(videoPath: videoPath),
      ),
    );
  }
}

// Video thumbnail widget
class VideoThumbnail extends StatelessWidget {
  final String videoPath;
  final VoidCallback onTap;

  const VideoThumbnail({
    super.key,
    required this.videoPath,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: kPreferredAspectRatioValue,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Use a container with a color as placeholder
            Container(
              color: Colors.black54,
              child: Center(
                child: Text(
                  'Video ${videoPath.split('/').last}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
            ),
            // Play icon overlay
            const Center(
              child: Icon(
                Icons.play_circle_fill,
                size: 50,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Video player page
class VideoPlayerPage extends StatefulWidget {
  final String videoPath;

  const VideoPlayerPage({
    super.key,
    required this.videoPath,
  });

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage>
    with WidgetsBindingObserver {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _isPlaying = false;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeVideoPlayer();
  }

  void _initializeVideoPlayer() async {
    try {
      // Create a VideoPlayerController for a file
      final controller = VideoPlayerController.file(File(widget.videoPath));
      _controller = controller;

      // Initialize the controller and update state when done
      await controller.initialize();

      if (_isDisposed || !mounted) {
        // Widget was disposed during initialization
        return;
      }

      // Add listener to update state when video status changes
      controller.addListener(_videoPlayerListener);

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Error initializing video player: $e');
      if (mounted && !_isDisposed) {
        _showErrorSnackBar('Failed to load video: $e');
      }
    }
  }

  void _videoPlayerListener() {
    if (_isDisposed || !mounted || _controller == null) return;

    final playing = _controller!.value.isPlaying;
    if (playing != _isPlaying) {
      setState(() {
        _isPlaying = playing;
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    // Pause video playback when app goes to background
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      if (controller != null && controller.value.isPlaying) {
        controller.pause();
      }
    }
  }

  @override
  void dispose() {
    _isDisposed = true;

    WidgetsBinding.instance.removeObserver(this);

    // Clean up the controller when the widget is disposed
    final controller = _controller;
    if (controller != null) {
      controller.removeListener(_videoPlayerListener);
      controller.pause();
      controller.dispose();
    }
    _controller = null;

    super.dispose();
  }

  Future<void> _playPause() async {
    if (_controller == null) return;

    // VideoPlayerController.dataSource returns a uri‐style string:
    var src = _controller!.dataSource;

    // If it’s a local file, strip the "file://" scheme off:
    if (src.startsWith('file://')) {
      src = src.replaceFirst('file://', '');
    }

    // Now make sure that file actually exists:
    final videoFile = File(src);
    if (!await videoFile.exists()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Video file not found at $src')),
      );
      return;
    }

    // Save to gallery
    final result = await ImageGallerySaverPlus.saveFile(src);
    if (_controller == null || !_isInitialized || _isDisposed || !mounted)
      return;

    try {
      if (_controller!.value.isPlaying) {
        _controller!.pause();
      } else {
        _controller!.play();
      }
    } catch (e) {
      debugPrint('Error toggling play/pause: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isDisposed) {
      return const SizedBox.shrink(); // Safety check
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Video Player'),
      ),
      body: Column(
        children: [
          if (_isInitialized && _controller != null)
            // Use a container to force the aspect ratio if needed
            AspectRatio(
              aspectRatio: _controller!.value.aspectRatio.isNaN
                  ? kPreferredAspectRatioValue
                  : _controller!.value.aspectRatio,
              child: VideoPlayer(_controller!),
            )
          else
            // Loading indicator while video initializes
            AspectRatio(
              aspectRatio:
                  kPreferredAspectRatioValue, // Consistent aspect ratio
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),

          // Playback controls
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Play/Pause button
                IconButton(
                  icon: Icon(
                    _isPlaying ? Icons.pause : Icons.play_arrow,
                    size: 40,
                  ),
                  onPressed:
                      _isInitialized && _controller != null ? _playPause : null,
                ),

                // Video position indicator
                if (_isInitialized && _controller != null)
                  Expanded(
                    child: VideoProgressIndicator(
                      _controller!,
                      allowScrubbing: true,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
              ],
            ),
          ),

          // Video details and external player option
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Playing: ${widget.videoPath.split('/').last}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),

                  // Open in external player button
                  ElevatedButton.icon(
                    onPressed: () => _openVideoExternally(widget.videoPath),
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Open in External Player'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Method to open video in external player
  void _openVideoExternally(String path) async {
    final file = File(path);
    if (!file.existsSync()) {
      debugPrint('Video file not found: $path');
      _showErrorSnackBar('Video file not found');
      return;
    }

    try {
      // Uncomment this to use url_launcher
      // final uri = Uri.file(path);
      // if (await canLaunchUrl(uri)) {
      //   await launchUrl(uri, mode: LaunchMode.externalApplication);
      // } else {
      //   debugPrint('Cannot launch external player for: $uri');
      //   _showErrorSnackBar('Cannot open external player');
      // }

      // For now, just show file info
      debugPrint('Video file size: ${file.lengthSync()} bytes');
    } catch (e) {
      debugPrint('Error opening video: $e');
      _showErrorSnackBar('Error: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    if (_isDisposed || !mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}
