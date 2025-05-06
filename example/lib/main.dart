import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:camerawesome/pigeon.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'dart:io';
import 'package:video_player/video_player.dart';

// Constants for consistent aspect ratio
const kPreferredAspectRatio = CameraAspectRatios.ratio_16_9;
const kPreferredAspectRatioValue = 16.0 / 9.0;

void main() {
  runApp(const CameraAwesomeApp());
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CameraAwesomeBuilder.awesome(
        theme: AwesomeTheme(bottomActionsBackgroundColor: Colors.transparent),
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
          sensor: Sensor.position(SensorPosition.back),
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
                single: (single) {
                  final videoPath = single.file?.path;
                  if (videoPath != null && mounted) {
                    setState(() {
                      _recordedVideos.add(videoPath);
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
        // Use custom layout builders to provide the reset functionality
        middleContentBuilder: (state) {
          return Column(
            children: [
              const Spacer(),
              // Add reset button before zoom controls

              if (state is PhotoCameraState && state.hasFilters)
                AwesomeFilterWidget(state: state)
              else if (!kIsWeb && Platform.isAndroid)
                AwesomeZoomSelector(state: state),
              AwesomeCameraModeSelector(state: state),
              if (_recordedVideos.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: IconButton(
                    icon: const Icon(
                      Icons.backspace, // ← use the backspace icon
                      color: Colors.white,
                    ),
                    tooltip: 'Delete last video',
                    onPressed: _deleteLastVideo,
                  ),
                ),
            ],
          );
        },
        bottomActionsBuilder: (state) {
          // For recording state, we don't show the Next button
          if (state is VideoRecordingCameraState) {
            return AwesomeBottomActions(
              state: state,
            );
          }

          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              AwesomeBottomActions(
                state: state,
                right: (_justRecorded)
                    ? Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: ElevatedButton(
                          onPressed: _navigateToGallery,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                          ),
                          child: const Text(
                            'Next',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      )
                    : null,
              ),
            ],
          );
        },
      ),
    );
  }

  // Function to delete the last recorded video
  void _deleteLastVideo() {
    if (_recordedVideos.isNotEmpty) {
      final lastVideoPath = _recordedVideos.last;

      // Remove from the list first
      setState(() {
        _recordedVideos.removeLast();

        // If no videos left, reset the flag
        if (_recordedVideos.isEmpty) {
          _justRecorded = false;
        }
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
