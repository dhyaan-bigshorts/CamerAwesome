// Gallery page to view and play recorded videos
import 'dart:io';

import 'package:camera_app/main.dart';
import 'package:flutter/material.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:video_player/video_player.dart';

class VideoGalleryPage extends StatelessWidget {
  final List<String> videos;
  final List<double> speeds;

  const VideoGalleryPage({
    super.key,
    required this.videos,
    required this.speeds,
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
