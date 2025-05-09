import 'dart:io';
import 'dart:math';

import 'package:camera_app/new_to_keep/delete_confimation.dart';
import 'package:camera_app/new_to_keep/image_progress_indicator.dart';
import 'package:camera_app/new_to_keep/speed_controller.dart';
import 'package:camera_app/new_to_keep/video_processor.dart';
import 'package:camera_app/test/image_showing_logic.dart';
import 'package:camera_app/test/videoplayinglogic.dart';
import 'package:camerawesome/src/widgets/buttons/timer_controller.dart';
import 'package:camera_app/new_to_keep/video_progress_indicator.dart';
import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:camerawesome/pigeon.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:sizer/sizer.dart';

import 'new_to_keep/app_config.dart';

// Constants for consistent aspect ratio
const kPreferredAspectRatio = CameraAspectRatios.ratio_16_9;
const kPreferredAspectRatioValue = 16.0 / 9.0;

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  void _openCamera(
    BuildContext context, {
    required bool photoMode,
    required int maxImages,
    CameraAspectRatios? aspect,
    required bool isVideo,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CameraLauncher(
          isPhoto: photoMode,
          maxImages: maxImages,
          initialAspectRatio: aspect ?? CameraAspectRatios.ratio_16_9,
          isVideo: isVideo,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pick your camera')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () => _openCamera(
                context,
                photoMode: true,
                maxImages: 1,
                isVideo: true,
              ),
              child: const Text('Ssup'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _openCamera(
                context,
                photoMode: false,
                aspect: CameraAspectRatios.ratio_16_9,
                isVideo: true,
                maxImages: 0, // videos only
              ),
              child: const Text('Snip'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _openCamera(
                context,
                photoMode: true,
                aspect: CameraAspectRatios.ratio_4_3,
                maxImages: 20,
                isVideo: false,
              ),
              child: const Text('Shot (max 20)'),
            ),
          ],
        ),
      ),
    );
  }
}

class CameraLauncher extends StatelessWidget {
  final bool isPhoto;
  final CameraAspectRatios initialAspectRatio;
  final int maxImages;
  final bool isVideo;

  const CameraLauncher(
      {Key? key,
      required this.isPhoto,
      this.initialAspectRatio = CameraAspectRatios.ratio_16_9,
      required this.maxImages,
      required this.isVideo})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<CameraPageState>(
      create: (_) => CameraPageState()
        ..isPhotoMode = isPhoto
        ..isVideo = isVideo
        ..maxImages = maxImages
        ..preselectedAspectRatio = initialAspectRatio,
      child: CameraAwesomeApp(), // <-- no `const`, no `builder:` needed
    );
  }
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

/// CameraState - A ChangeNotifier class to manage all camera state
class CameraPageState extends ChangeNotifier {
  // Camera settings
  bool usingUltra = false;
  bool hasUltraWide = false;
  bool audioEnabled = true;
  bool isFilterSelectionOpen = false;
  bool showDeleteConfirmation = false;
  bool showDeleteImageConfirmationDialog = false;
  bool isProcessingVideos = false;
  bool noMoreRecordings = false;
  bool justRecorded = false;
  bool justCaptured = false;
  bool isPhotoMode = false;
  bool isVideo = true;
  bool isPhoto = false;

  // Durations
  final List<int> preselectedVideoDurations = [30, 45, 60, 120];
  int selectedDurationInSeconds = 120; // default 2 minutes

  int maxImages = 20;

  final List<CameraAspectRatios> aspectRatios = [
    CameraAspectRatios.ratio_16_9,
    CameraAspectRatios.ratio_4_3,
    CameraAspectRatios.ratio_1_1
  ];
  CameraAspectRatios preselectedAspectRatio = CameraAspectRatios.ratio_16_9;

  // Filter settings
  AwesomeFilter selectedFilter = AwesomeFilter.None;
  final List<AwesomeFilter> filters = [
    // Basic filter
    AwesomeFilter.None,
    // Monochrome Filters
    AwesomeFilter.BlackWhiteGradient,
    AwesomeFilter.Inkwell,
    AwesomeFilter.Moon,
    // Cool Tone Filters
    AwesomeFilter.CoolToneGradient,
    AwesomeFilter.DeepSeaGradient,
    AwesomeFilter.TechGradient,
    AwesomeFilter.Hudson,
    // Warm Tone Filters
    AwesomeFilter.WarmToneGradient,
    AwesomeFilter.SunsetGradient,
    AwesomeFilter.MintChocolateGradient,
    AwesomeFilter.Walden,
    // Vibrant Filters
    AwesomeFilter.HighContrastGradient,
    AwesomeFilter.NeonGradient,
    AwesomeFilter.RainbowVibrance,
    AwesomeFilter.Clarendon,
    // Balanced RGB Filters
    AwesomeFilter.Sunrise,
    AwesomeFilter.Daylight,
    AwesomeFilter.Jungle,
    AwesomeFilter.Ocean,
    AwesomeFilter.Emerald,
    AwesomeFilter.Aurora,
    AwesomeFilter.DeepSpace,
    // Dual Tone Filters
    AwesomeFilter.DualToneGradient,
    AwesomeFilter.CyberGradient,
    AwesomeFilter.NebulaGradient,
    // Soft/Muted Filters
    AwesomeFilter.PastelGradient,
    AwesomeFilter.Gingham,
    AwesomeFilter.Crema,
    AwesomeFilter.Lark,
    AwesomeFilter.Reyes,
    AwesomeFilter.Sierra,
    AwesomeFilter.Willow,
  ];

  // Recorded content
  final List<String> recordedVideos = [];
  bool doesAllowMultiplePhotos = false;
  final List<String> recordedPhotos = [];
  final List<Duration> recordedVideosDurations = [];
  final List<double> recordedSpeeds = [];
  final List<AwesomeFilter> selectedFilters = [];

  // Helper functions with state updates
  void setUltraWide(bool value) {
    usingUltra = value;
    notifyListeners();
  }

  void setHasUltraWide(bool value) {
    hasUltraWide = value;
    notifyListeners();
  }

  void toggleAudio() {
    audioEnabled = !audioEnabled;
    notifyListeners();
  }

  void openFilterSelection() {
    isFilterSelectionOpen = true;
    notifyListeners();
  }

  void closeFilterSelection() {
    isFilterSelectionOpen = false;
    notifyListeners();
  }

  void setSelectedFilter(AwesomeFilter filter) {
    selectedFilter = filter;
    notifyListeners();
  }

  void cycleDuration() {
    final currentIndex =
        preselectedVideoDurations.indexOf(selectedDurationInSeconds);
    final nextIndex = (currentIndex + 1) % preselectedVideoDurations.length;
    selectedDurationInSeconds = preselectedVideoDurations[nextIndex];
    notifyListeners();
  }

  void cycleAspectRatio() {
    final currentIndex = aspectRatios.indexOf(preselectedAspectRatio);
    final nextIndex = (currentIndex + 1) % aspectRatios.length;
    preselectedAspectRatio = aspectRatios[nextIndex];
    notifyListeners();
  }

  void showDeleteConfirmationDialog() {
    if (recordedVideos.isEmpty) return;
    showDeleteConfirmation = true;
    notifyListeners();
  }

  void showDeleteImageDialog() {
    if (recordedPhotos.isEmpty) return;
    showDeleteImageConfirmationDialog = true;
    notifyListeners();
  }

  void cancelDelete() {
    showDeleteConfirmation = false;
    notifyListeners();
  }

  void cancelImageDelete() {
    showDeleteImageConfirmationDialog = false;
    notifyListeners();
  }

  void deleteLastVideo() {
    if (recordedVideos.isEmpty) return;

    final lastVideoPath = recordedVideos.last;

    // Remove from lists
    recordedVideos.removeLast();
    if (recordedVideosDurations.isNotEmpty) {
      recordedVideosDurations.removeLast();
    }
    if (recordedSpeeds.isNotEmpty) {
      recordedSpeeds.removeLast();
    }
    if (selectedFilters.isNotEmpty) {
      selectedFilters.removeLast();
    }

    noMoreRecordings = false;

    // If no videos left, reset the flag
    if (recordedVideos.isEmpty) {
      justRecorded = false;
    }
    showDeleteConfirmation = false;

    notifyListeners();

    // Delete the file (moved outside notifyListeners to avoid blocking UI)
    try {
      final file = File(lastVideoPath);
      if (file.existsSync()) {
        file.deleteSync();
      }
    } catch (e) {
      debugPrint('Error deleting video file: $e');
    }
  }

  void deleteLastImage() {
    if (recordedPhotos.isEmpty) return;

    final lastVideoPath = recordedPhotos.last;

    // Remove from lists
    recordedPhotos.removeLast();

    // If no videos left, reset the flag
    if (recordedPhotos.isEmpty) {
      justCaptured = false;
    }
    showDeleteImageConfirmationDialog = false;

    notifyListeners();

    // Delete the file (moved outside notifyListeners to avoid blocking UI)
    try {
      final file = File(lastVideoPath);
      if (file.existsSync()) {
        file.deleteSync();
      }
    } catch (e) {
      debugPrint('Error deleting video file: $e');
    }
  }

  void addRecordedVideo(
      String path, Duration duration, double speed, AwesomeFilter filter) {
    recordedVideos.add(path);
    recordedVideosDurations.add(duration);
    recordedSpeeds.add(speed);
    selectedFilters.add(filter);
    justRecorded = true;
    notifyListeners();
  }

  void addClickedPhoto(String path) {
    recordedPhotos.add(path);
    justCaptured = true;
    notifyListeners();
  }

  void resetJustCaptured() {
    justCaptured = false;
    notifyListeners();
  }

  void resetJustRecorded() {
    justRecorded = false;
    notifyListeners();
  }

  void setPhotoMode() {
    isPhotoMode = true;
    // clear out any prior video captures
    recordedVideos.clear();
    recordedVideosDurations.clear();
    recordedSpeeds.clear();
    selectedFilters.clear();
    justRecorded = false;

    notifyListeners();
  }

  void setVideoMode() {
    isPhotoMode = false;
    // clear out any prior photo captures
    recordedPhotos.clear();
    justCaptured = false;

    notifyListeners();
  }

  void setNoMoreRecordings(bool value) {
    noMoreRecordings = value;
    notifyListeners();
  }

  void setProcessingVideos(bool value) {
    isProcessingVideos = value;
    notifyListeners();
  }

  // Helper method for filter names
  String getFilterName(AwesomeFilter filter) {
    return filter.toString().split('.').last.replaceAll('_', ' ');
  }
}

/// Main CameraPage Widget
class CameraPage extends StatefulWidget {
  const CameraPage({Key? key}) : super(key: key);

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  final _cameraApi = CameraInterface();
  late SpeedController _speedController;
  late TimerController _timerController;
  late ScrollController _filterScrollController;

  @override
  void initState() {
    super.initState();

    _timerController = TimerController(
      themeApp: AwesomeTheme(bottomActionsBackgroundColor: Colors.transparent),
      onTimerComplete: _handleTimerComplete,
      onTimerStateChanged: () {
        // Only using setState for timer UI which is independent of our Provider
        if (mounted) setState(() {});
      },
    );

    _speedController = SpeedController(
      speeds: [0.5, 1.0, 1.5, 2.0],
      initialSpeed: 1.0,
    );

    _filterScrollController = ScrollController();

    // Initialize device capabilities
    _checkUltraWideSupport();
  }

  @override
  void dispose() {
    _timerController.cancelTimer(notify: false);
    _filterScrollController.dispose();
    super.dispose();
  }

  // Check if the device has ultra-wide camera support
  Future<void> _checkUltraWideSupport() async {
    try {
      final sensors = await _cameraApi.getBackSensors();
      final hasUltraWide = sensors.any(
          (sensor) => sensor?.sensorType == PigeonSensorType.ultraWideAngle);

      if (mounted) {
        final cameraState =
            Provider.of<CameraPageState>(context, listen: false);
        cameraState.setHasUltraWide(hasUltraWide);
      }

      debugPrint('Ultra-wide camera available: $hasUltraWide');
    } catch (e) {
      debugPrint('Error checking camera sensors: $e');
    }
  }

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

  void _handleTimerComplete(CameraState state) {
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

  void _showFilterBottomSheet(BuildContext context) {
    final cameraState = Provider.of<CameraPageState>(context, listen: false);
    final selectedIndex =
        cameraState.filters.indexOf(cameraState.selectedFilter);

    // Calculate scroll position after the bottom sheet is displayed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (selectedIndex != -1 && _filterScrollController.hasClients) {
        // Calculate the target position
        final itemWidth = 120.0;
        final screenWidth = MediaQuery.of(context).size.width;
        double targetPosition = max(0,
            (selectedIndex * itemWidth) - (screenWidth / 2) + (itemWidth / 2));

        // Scroll to the position
        _filterScrollController.jumpTo(targetPosition);
      }
    });

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: true,
      builder: (context) {
        return Consumer<CameraPageState>(
          builder: (context, state, _) {
            return Container(
              height: 200,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.8),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  // Handle indicator at top
                  Container(
                    width: 40,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 15),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                  ),

                  // Title
                  const Padding(
                    padding: EdgeInsets.only(bottom: 15),
                    child: Text(
                      'Select Filter',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  // Filter ListView
                  Expanded(
                    child: ListView.builder(
                      controller: _filterScrollController,
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: state.filters.length,
                      itemBuilder: (context, index) {
                        final isSelected =
                            state.selectedFilter == state.filters[index];
                        return GestureDetector(
                          onTap: () {
                            state.setSelectedFilter(state.filters[index]);
                          },
                          child: Container(
                            width: 100,
                            margin: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: isSelected
                                    ? Colors.blue
                                    : Colors.white.withOpacity(0.5),
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              color: isSelected
                                  ? Colors.blue.withOpacity(0.2)
                                  : Colors.transparent,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.filter,
                                  color:
                                      isSelected ? Colors.amber : Colors.white,
                                  size: 30,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  state.filters[index].name,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.amber
                                        : Colors.white,
                                    fontSize: 14,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    ).then((_) {
      cameraState.closeFilterSelection();
    });
  }

  Future<void> _navigateToImageGallery() async {
    final cameraState = Provider.of<CameraPageState>(context, listen: false);
    if (cameraState.recordedPhotos.isEmpty) return;

    if (!mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ImageGalleryPage(
          images: cameraState.recordedPhotos,
        ),
      ),
    );
  }

  void _performModeSwitch(CameraState state, bool toPhoto) {
    final cameraState = Provider.of<CameraPageState>(context, listen: false);
    if (toPhoto) {
      cameraState.setPhotoMode();
      state.setState(CaptureMode.photo);
    } else {
      cameraState.setVideoMode();
      state.setState(CaptureMode.video);
    }
  }

  void _showModeSwitchDialog(CameraState state, BuildContext context,
      {required bool toPhoto}) {
    final modeName = toPhoto ? 'Photo' : 'Video';
    final loseWhat = toPhoto ? 'all recorded videos' : 'all captured photos';

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Switch to $modeName mode?'),
        content: Text('You will lose $loseWhat if you continue.'),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(), // <— use dialogContext
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop(); // <— use dialogContext
              _performModeSwitch(state, toPhoto);
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  Future<void> _navigateToGallery() async {
    final cameraState = Provider.of<CameraPageState>(context, listen: false);
    if (cameraState.recordedVideos.isEmpty) return;

    cameraState.setProcessingVideos(true);

    try {
      // Apply filter to videos
      //todo
      // List<String> filteredVideos = await VideoFilter.applyFilterToVideos(
      //   videoPaths: cameraState.recordedVideos,
      //   filters: cameraState.selectedFilters,
      // );

      cameraState.setProcessingVideos(false);

      // Navigate to gallery with filtered videos
      if (!mounted) return;

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => VideoGalleryPage(
            videos: cameraState.recordedVideos,
            speeds: cameraState.recordedSpeeds,
          ),
        ),
      );
    } catch (e) {
      // Handle errors
      cameraState.setProcessingVideos(false);

      // Show error
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );

      // Navigate with original videos
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => VideoGalleryPage(
            videos: cameraState.recordedVideos,
            speeds: cameraState.recordedSpeeds,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CameraPageState>(
      builder: (context, cameraState, _) {
        return Stack(
          children: [
            Scaffold(
              body: CameraAwesomeBuilder.awesome(
                theme: AwesomeTheme(
                    bottomActionsBackgroundColor: Colors.transparent),
                availableFilters: cameraState.filters,
                defaultFilter: cameraState.selectedFilter,
                currentFilter: cameraState.selectedFilter,
                saveConfig: cameraState.isPhoto && cameraState.isVideo
                    ? SaveConfig.photoAndVideo(
                        initialCaptureMode: CaptureMode.video,
                        videoOptions: VideoOptions(
                          enableAudio: true,
                          ios: CupertinoVideoOptions(
                            fps: 60,
                            codec: CupertinoCodecType.h264,
                          ),
                          android: AndroidVideoOptions(
                            bitrate: 1200000,
                            fallbackStrategy: QualityFallbackStrategy.lower,
                          ),
                          quality: VideoRecordingQuality.fhd,
                        ),
                        mirrorFrontCamera: Platform.isIOS ? false : true,
                      )
                    : cameraState.isPhoto && !cameraState.isVideo
                        ? SaveConfig.photo(
                            mirrorFrontCamera: Platform.isIOS ? false : true,
                          )
                        : SaveConfig.video(
                            // initialCaptureMode: CaptureMode.video,
                            videoOptions: VideoOptions(
                              enableAudio: true,
                              ios: CupertinoVideoOptions(
                                fps: 60,
                                codec: CupertinoCodecType.h264,
                              ),
                              android: AndroidVideoOptions(
                                bitrate: 1200000,
                                fallbackStrategy: QualityFallbackStrategy.lower,
                              ),
                              quality: VideoRecordingQuality.fhd,
                            ),
                            mirrorFrontCamera: Platform.isIOS ? false : true,
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
                  // Handle both photo and video events
                  switch (event.status) {
                    case MediaCaptureStatus.capturing:
                      // Reset flags when starting to capture
                      cameraState.resetJustRecorded();
                      break;
                    case MediaCaptureStatus.success:
                      if (event.isVideo) {
                        // Handle video capture success
                        event.captureRequest.when(
                          single: (single) async {
                            final videoPath = single.file?.path;
                            if (videoPath != null) {
                              // Get actual duration from video file
                              final duration =
                                  await getVideoDuration(videoPath);

                              Duration adjustedDuration = Duration(
                                  milliseconds: (duration.inMilliseconds /
                                          _speedController.currentSpeed)
                                      .round());

                              cameraState.addRecordedVideo(
                                videoPath,
                                adjustedDuration,
                                _speedController.currentSpeed,
                                cameraState.selectedFilter,
                              );
                            }
                          },
                          multiple: (multiple) {
                            multiple.fileBySensor.forEach((key, value) {
                              final path = value?.path;
                              if (path != null) {
                                // Note: This is simplified since we don't have duration info
                                // You might want to process multiple videos differently
                                cameraState.recordedVideos.add(path);
                                cameraState.justRecorded = true;
                                cameraState.notifyListeners();
                              }
                            });
                          },
                        );
                      } else {
                        // Handle photo capture success
                        event.captureRequest.when(
                          single: (single) {
                            final photoPath = single.file?.path;
                            if (photoPath != null) {
                              // Handle the photo capture success - display a toast message
                              cameraState.addClickedPhoto(photoPath);

                              // Optionally, you could store the photo path if needed
                              // cameraState.addCapturedPhoto(photoPath, cameraState.selectedFilter);
                            }
                          },
                          multiple: (multiple) {
                            // Handle multiple photos if needed
                            multiple.fileBySensor.forEach((key, value) {
                              final path = value?.path;
                              if (path != null) {
                                // Handle multiple photo captures if needed
                                print('Multiple photo captured: $path');
                              }
                            });
                          },
                        );
                      }
                      break;
                    case MediaCaptureStatus.failure:
                      // Handle failure for both photo and video
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Capture failed'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                      break;
                  }
                },
                topActionsBuilder: (state) {
                  state.setFilter(cameraState.selectedFilter);

                  return AwesomeTopActions(
                    state: state,
                    padding: EdgeInsets.only(
                      left: AppConfig(context).deviceWidth(2),
                      top: AppConfig(context).deviceHeight(1),
                      right: AppConfig(context).deviceWidth(2),
                    ),
                    children: [
                      if (state.captureMode == CaptureMode.video)
                        VideoRecordingProgress(
                          state:
                              state is VideoRecordingCameraState ? state : null,
                          currentSpeed: _speedController.currentSpeed,
                          previousRecordingsDurations:
                              cameraState.recordedVideosDurations,
                          maxDuration:
                              cameraState.selectedDurationInSeconds / 60.0,
                          stop: () {
                            if (state is VideoRecordingCameraState) {
                              state.stopRecording();
                              cameraState.setNoMoreRecordings(true);
                            }
                          },
                        ),
                      if (state.captureMode == CaptureMode.photo)
                        // Somewhere in your build:
                        ImageProgressBar(
                          maxCount: cameraState.maxImages,
                          currentCount: cameraState.recordedPhotos.length,
                          backgroundColor: Colors.black45,
                          tickColor: Colors.white30,
                          height: 6,
                        ),
                    ],
                    ultraWide: [
                      if (state is PhotoCameraState)
                        GestureDetector(
                          onTap: () {
                            cameraState.cycleAspectRatio();
                            state.sensorConfig.setAspectRatio(
                                cameraState.preselectedAspectRatio);
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10.0),
                            child: Text(
                              cameraState.preselectedAspectRatio ==
                                      CameraAspectRatios.ratio_16_9
                                  ? "9:16"
                                  : cameraState.preselectedAspectRatio ==
                                          CameraAspectRatios.ratio_1_1
                                      ? "1:1"
                                      : "3:4",
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      Visibility(
                        visible: state is VideoCameraState,
                        child: GestureDetector(
                          onTap: () {
                            cameraState.toggleAudio();
                            CamerawesomePlugin.setAudioMode(
                                    cameraState.audioEnabled)
                                .catchError((error) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Error toggling microphone"),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Icon(
                              cameraState.audioEnabled
                                  ? Icons.volume_up
                                  : Icons.volume_off,
                            ),
                          ),
                        ),
                      ),
                      if (state is VideoCameraState)
                        SpeedOverlaySelector(controller: _speedController),
                      if (state is VideoCameraState ||
                          state is PhotoCameraState)
                        Visibility(
                          visible: cameraState.hasUltraWide,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: IconButton(
                              icon: Icon(
                                Icons.filter_center_focus,
                                color: cameraState.usingUltra
                                    ? Colors.amber
                                    : Colors.white,
                              ),
                              tooltip: cameraState.usingUltra
                                  ? 'Ultra-wide on'
                                  : 'Ultra-wide off',
                              onPressed: () {
                                cameraState
                                    .setUltraWide(!cameraState.usingUltra);
                                _cameraApi.setSensor(
                                  cameraState.usingUltra
                                      ? [
                                          PigeonSensor(
                                              type: PigeonSensorType
                                                  .ultraWideAngle,
                                              position:
                                                  PigeonSensorPosition.back)
                                        ]
                                      : [
                                          PigeonSensor(
                                              type: PigeonSensorType.wideAngle,
                                              position:
                                                  PigeonSensorPosition.back)
                                        ],
                                );
                              },
                            ),
                          ),
                        ),
                      if (state is VideoCameraState ||
                          state is PhotoCameraState)
                        Visibility(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: _timerController
                                .buildElegantTimerSelector(context),
                          ),
                        ),
                      if (cameraState.recordedVideos.isEmpty &&
                          state is VideoCameraState)
                        GestureDetector(
                          onTap: () => cameraState.cycleDuration(),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10.0),
                            child: Text(
                              cameraState.selectedDurationInSeconds >= 60
                                  ? "${cameraState.selectedDurationInSeconds ~/ 60} m"
                                  : "${cameraState.selectedDurationInSeconds} s",
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
                middleContentBuilder: (state) {
                  return Column(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (!kIsWeb && Platform.isAndroid)
                        AwesomeZoomSelector(
                          state: state,
                          theme: AwesomeTheme(
                            bottomActionsBackgroundColor: Colors.transparent,
                          ),
                        ),
                      Visibility(
                        visible: cameraState.recordedVideos.isNotEmpty &&
                            state is VideoCameraState,
                        child: Padding(
                          padding:
                              const EdgeInsets.only(top: 16.0, bottom: 16.0),
                          child: IconButton(
                            icon: const Icon(Icons.backspace,
                                color: Colors.white),
                            tooltip: 'Delete last video',
                            onPressed: cameraState.showDeleteConfirmationDialog,
                          ),
                        ),
                      ),
                      Visibility(
                        visible: cameraState.recordedPhotos.isNotEmpty &&
                            state is PhotoCameraState,
                        child: Padding(
                          padding:
                              const EdgeInsets.only(top: 16.0, bottom: 16.0),
                          child: IconButton(
                            icon: const Icon(Icons.backspace,
                                color: Colors.white),
                            tooltip: 'Delete last video',
                            onPressed: cameraState.showDeleteImageDialog,
                          ),
                        ),
                      ),
                    ],
                  );
                },
                bottomActionsBuilder: (state) {
                  if (cameraState.isFilterSelectionOpen) {
                    return Container();
                  }

                  // For recording state, we don't show the Next button
                  if (state is VideoRecordingCameraState) {
                    return Column(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: AwesomeBottomActions(
                            state: state,
                          ),
                        ),
                      ],
                    );
                  }

                  return Column(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AwesomeBottomActions(
                        state: state,
                        left: Column(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            if (state is VideoCameraState ||
                                state is PhotoCameraState)
                              IconButton(
                                icon: const Icon(Icons.filter,
                                    color: Colors.white),
                                tooltip: 'Filters',
                                padding: const EdgeInsets.only(
                                    bottom: 15.0, top: 15.0),
                                onPressed: () {
                                  cameraState.openFilterSelection();
                                  _showFilterBottomSheet(context);
                                },
                              ),
                            if (state is VideoCameraState ||
                                state is PhotoCameraState)
                              // No floating left in recording state
                              IconButton(
                                  onPressed: () => state.switchCameraSensor(),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 15.0),
                                  icon: Icon(Icons.repeat,
                                      color: Colors.white, size: 30))
                          ],
                        ),
                        captureButton: state.captureMode == CaptureMode.photo
                            ? PhotoCaptureButton(
                                state: state,
                                timerController:
                                    _timerController, // Pass the timer controller
                                onTap: () {
                                  if (cameraState.recordedPhotos.length <
                                      cameraState.maxImages) {
                                    if (!_timerController.isTimerActive) {
                                      // If timer is not active, start countdown timer
                                      _timerController
                                          .startTimerCountdown(state);
                                    } else {
                                      // If timer is active, cancel it
                                      _timerController.cancelTimer();
                                    }
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'You’ve reached the maximum number of images you can capture.',
                                        ),
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                  }
                                },
                              )
                            : ProductionCaptureButton(
                                state: state,
                                timerController: _timerController,
                                onTap: () {
                                  if (!cameraState.noMoreRecordings) {
                                    if (state is VideoRecordingCameraState) {
                                      // Already recording, stop recording
                                      state.stopRecording();
                                    } else if (!_timerController
                                        .isTimerActive) {
                                      // Not recording and timer not active, start timer or record
                                      _timerController
                                          .startTimerCountdown(state);
                                    } else {
                                      // Timer is active, cancel it
                                      _timerController.cancelTimer();
                                    }
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Max duration allowed while recording has been reached',
                                        ),
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                  }
                                },
                              ),
                        right: (state is VideoCameraState &&
                                    cameraState.justRecorded) ||
                                (state is PhotoCameraState &&
                                    cameraState.justCaptured)
                            ? Padding(
                                padding: const EdgeInsets.only(bottom: 16.0),
                                child: ElevatedButton(
                                  onPressed: state is PhotoCameraState &&
                                          cameraState.justCaptured
                                      ? _navigateToImageGallery
                                      : _navigateToGallery,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
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
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              )
                            : Padding(
                                padding: const EdgeInsets.only(bottom: 16.0),
                                child: ElevatedButton(
                                  onPressed: null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    disabledBackgroundColor:
                                        Colors.white.withOpacity(0.4),
                                    disabledForegroundColor: Colors.black,
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
                                    ),
                                  ),
                                ),
                              ),
                      ),
                      Visibility(
                        visible: cameraState.isPhoto && cameraState.isVideo,
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Toggle button for Photo/Video
                              GestureDetector(
                                // Toggle between photo and video modes
                                onTap: () {
                                  final isCurrentlyPhoto =
                                      cameraState.isPhotoMode;
                                  final hasMedia = isCurrentlyPhoto
                                      ? cameraState.recordedPhotos.isNotEmpty
                                      : cameraState.recordedVideos.isNotEmpty;

                                  if (hasMedia) {
                                    _showModeSwitchDialog(state, context,
                                        toPhoto: !isCurrentlyPhoto);
                                  } else {
                                    _performModeSwitch(
                                        state, !isCurrentlyPhoto);
                                  }
                                },

                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Photo option
                                      Text(
                                        'Photo',
                                        style: TextStyle(
                                          color: cameraState.isPhotoMode
                                              ? Colors.amber
                                              : Colors.white.withOpacity(0.7),
                                          fontWeight: cameraState.isPhotoMode
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                        ),
                                      ),

                                      // Divider
                                      Container(
                                        margin:
                                            EdgeInsets.symmetric(horizontal: 8),
                                        height: 15,
                                        width: 1,
                                        color: Colors.white.withOpacity(0.5),
                                      ),

                                      // Video option
                                      Text(
                                        'Video',
                                        style: TextStyle(
                                          color: !cameraState.isPhotoMode
                                              ? Colors.amber
                                              : Colors.white.withOpacity(0.7),
                                          fontWeight: !cameraState.isPhotoMode
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            // Delete confirmation overlay
            if (cameraState.showDeleteConfirmation &&
                cameraState.recordedVideos.isNotEmpty)
              DeleteConfirmationOverlay(
                onConfirm: cameraState.deleteLastVideo,
                onCancel: cameraState.cancelDelete,
              ),

            if (cameraState.showDeleteImageConfirmationDialog &&
                cameraState.recordedPhotos.isNotEmpty)
              DeleteConfirmationOverlay(
                onConfirm: cameraState.deleteLastImage,
                onCancel: cameraState.cancelImageDelete,
              ),

            // Timer display
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
                ),
              ),

            // Loading indicator for video processing
            if (cameraState.isProcessingVideos)
              Container(
                color: Colors.black54,
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Entry point modification to include Provider
void main() {
  runApp(
    Sizer(
      builder: (context, orientation, deviceType) {
        return MaterialApp(
          theme: ThemeData.dark(),
          home: const HomePage(),
        );
      },
    ),
  );
}
