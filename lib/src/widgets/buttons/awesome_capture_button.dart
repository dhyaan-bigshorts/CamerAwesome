import 'dart:async';

import 'package:camerawesome/src/widgets/buttons/timer_controller.dart';
import 'package:flutter/material.dart';
import 'package:camerawesome/camerawesome_plugin.dart';

/// A production-ready capture button that supports both instant capture
/// and "delayed" capture via a TimerController.
class ProductionCaptureButton extends StatefulWidget {
  final CameraState state;
  final TimerController? timerController;
  final double size;
  final Color idleColor;
  final Color recordingColor;
  final Color borderColor;
  final double borderWidth;
  final VoidCallback? onTap;

  const ProductionCaptureButton({
    Key? key,
    required this.state,
    this.timerController,
    this.size = 80.0,
    this.idleColor = Colors.white,
    this.recordingColor = Colors.red,
    this.borderColor = Colors.white,
    this.borderWidth = 4.0,
    this.onTap,
  }) : super(key: key);

  @override
  _ProductionCaptureButtonState createState() =>
      _ProductionCaptureButtonState();
}

class _ProductionCaptureButtonState extends State<ProductionCaptureButton> {
  // Simple animation state
  double _pulseScale = 1.0;
  bool _isRecording = false;
  Timer? _pulseTimer;
  StreamSubscription? _captureSubscription;
  bool _isMounted = true;

  @override
  void initState() {
    super.initState();
    _subscribeToCaptureState();
  }

  void _subscribeToCaptureState() {
    // Cancel any existing subscription first
    _captureSubscription?.cancel();

    // Create new subscription with safeguards
    _captureSubscription = widget.state.captureState$.listen((capture) {
      if (!_isMounted) return;

      final isRecording = capture?.isRecordingVideo ?? false;

      if (isRecording && !_isRecording) {
        _isRecording = true;
        _startPulseAnimation();
      } else if (!isRecording && _isRecording) {
        _isRecording = false;
        _stopPulseAnimation();
      }
    });
  }

  void _startPulseAnimation() {
    // Cancel any existing timer
    _pulseTimer?.cancel();

    // Set up a repeating timer for the pulse effect
    _pulseTimer = Timer.periodic(const Duration(milliseconds: 800), (timer) {
      if (!_isMounted) {
        timer.cancel();
        return;
      }

      setState(() {
        // Toggle between normal and expanded
        _pulseScale = _pulseScale > 1.0 ? 1.0 : 1.05;
      });
    });
  }

  void _stopPulseAnimation() {
    _pulseTimer?.cancel();
    _pulseTimer = null;

    if (_isMounted) {
      setState(() {
        _pulseScale = 1.0;
      });
    }
  }

  @override
  void dispose() {
    _isMounted = false;
    _pulseTimer?.cancel();
    _captureSubscription?.cancel();
    _captureSubscription = null;
    super.dispose();
  }

  @override
  void didUpdateWidget(ProductionCaptureButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the state changed, resubscribe
    if (oldWidget.state != widget.state) {
      _subscribeToCaptureState();
    }
  }

  void _handleTap() {
    widget.state.when(
      onPhotoMode: (photo) => photo.takePhoto(),
      onVideoMode: (video) {
        video.startRecording();
        setState(() {
          _isRecording = true;
        });
        _startPulseAnimation();
      },
      onVideoRecordingMode: (recording) {
        recording.stopRecording();
        setState(() {
          _isRecording = false;
        });
        _stopPulseAnimation();
      },
      onPreparingCamera: (_) {},
    );
  }

  @override
  Widget build(BuildContext context) {
    final isRecording = widget.state is VideoRecordingCameraState;
    final tc = widget.timerController;
    final showCountdown = tc != null && tc.isTimerActive && !isRecording;
    final double innerSize = widget.size - widget.borderWidth * 2;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 1) Outer ring
          Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: widget.borderColor,
                width: widget.borderWidth,
              ),
            ),
          ),

          // 2) Animated inner
          AnimatedScale(
            scale: _pulseScale,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onTap ?? _handleTap,
                customBorder: const CircleBorder(),
                splashColor: Colors.white24,
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: showCountdown
                        // ► Countdown
                        ? Text(
                            '${tc!.currentTimerSeconds}',
                            key: const ValueKey('countdown'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : isRecording
                            // ■ Recording square
                            ? Container(
                                key: const ValueKey('recording'),
                                width: innerSize * 0.5,
                                height: innerSize * 0.5,
                                decoration: BoxDecoration(
                                  color: widget.recordingColor,
                                  shape: BoxShape.rectangle,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              )
                            // ● Idle circle
                            : Container(
                                key: const ValueKey('idle'),
                                width: innerSize * 0.9,
                                height: innerSize * 0.9,
                                decoration: BoxDecoration(
                                  color: widget.idleColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A dedicated photo capture button with simpler animation mechanics
class PhotoCaptureButton extends StatefulWidget {
  final CameraState state;
  final TimerController? timerController;
  final double size;
  final Color idleColor;
  final Color captureColor;
  final Color borderColor;
  final double borderWidth;
  final VoidCallback? onTap;

  const PhotoCaptureButton({
    Key? key,
    required this.state,
    this.timerController,
    this.size = 80.0,
    this.idleColor = Colors.white,
    this.captureColor = Colors.amber,
    this.borderColor = Colors.white,
    this.borderWidth = 4.0,
    this.onTap,
  }) : super(key: key);

  @override
  _PhotoCaptureButtonState createState() => _PhotoCaptureButtonState();
}

class _PhotoCaptureButtonState extends State<PhotoCaptureButton> {
  bool _isAnimating = false;
  double _scaleValue = 1.0;
  StreamSubscription? _captureSubscription;
  bool _isMounted = true;

  @override
  void initState() {
    super.initState();
    _subscribeToCaptureState();
  }

  void _subscribeToCaptureState() {
    // Cancel any existing subscription first
    _captureSubscription?.cancel();

    // Create new subscription with safeguards
    _captureSubscription = widget.state.captureState$.listen((capture) {
      if (!_isMounted) return;

      // Check if we're capturing an image
      final isCapturing = capture != null &&
          !capture.isVideo &&
          capture.status == MediaCaptureStatus.capturing;

      if (isCapturing && !_isAnimating) {
        _playSimpleShutterEffect();
      }
    });
  }

  // Simple timer-based animation without AnimationController
  void _playSimpleShutterEffect() async {
    if (!_isMounted) return;

    // Set flag to prevent multiple animations
    _isAnimating = true;

    try {
      // Shrink
      setState(() {
        _scaleValue = 0.85; // 15% smaller
      });

      // Wait
      await Future.delayed(const Duration(milliseconds: 150));
      if (!_isMounted) return;

      // Expand back
      setState(() {
        _scaleValue = 1.0;
      });

      // Wait for animation to complete
      await Future.delayed(const Duration(milliseconds: 150));
    } catch (e) {
      print('Simple animation error: $e');
    } finally {
      // Always reset the flag
      if (_isMounted) {
        setState(() {
          _isAnimating = false;
        });
      }
    }
  }

  @override
  void dispose() {
    // Mark as unmounted first
    _isMounted = false;

    // Clean up subscription
    _captureSubscription?.cancel();
    _captureSubscription = null;

    super.dispose();
  }

  @override
  void didUpdateWidget(PhotoCaptureButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the state changed, resubscribe
    if (oldWidget.state != widget.state) {
      _subscribeToCaptureState();
    }
  }

  void _handleTap() {
    // Use the onTap callback if provided
    if (widget.onTap != null) {
      widget.onTap!();
      return;
    }

    // Otherwise use default behavior
    widget.state.when(
      onPhotoMode: (photo) {
        photo.takePhoto();
        _playSimpleShutterEffect();
      },
      onVideoMode: (_) {},
      onVideoRecordingMode: (_) {},
      onPreparingCamera: (_) {},
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isPhotoMode = widget.state is PhotoCameraState;
    final double innerSize = widget.size - widget.borderWidth * 2;

    // Timer-related state
    final tc = widget.timerController;
    final showCountdown = tc != null && tc.isTimerActive;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 1) Outer ring
          Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isPhotoMode
                    ? widget.borderColor
                    : widget.borderColor.withOpacity(0.5),
                width: widget.borderWidth,
              ),
            ),
          ),

          // 2) Inner button with simple scale animation
          AnimatedScale(
            scale: _scaleValue,
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeInOut,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: isPhotoMode ? _handleTap : null,
                customBorder: const CircleBorder(),
                splashColor: Colors.white24,
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: showCountdown
                        // Countdown timer display
                        ? Text(
                            '${tc!.currentTimerSeconds}',
                            key: const ValueKey('countdown'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        // Normal photo button
                        : Container(
                            key: const ValueKey('idle'),
                            width: innerSize * 0.9,
                            height: innerSize * 0.9,
                            decoration: BoxDecoration(
                              color: isPhotoMode
                                  ? widget.idleColor
                                  : widget.idleColor.withOpacity(0.5),
                              shape: BoxShape.circle,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ),

          // 3) Photo icon overlay (optional, only shown when not in photo mode)
          if (!isPhotoMode)
            Icon(
              Icons.camera_alt,
              color: Colors.black.withOpacity(0.5),
              size: innerSize * 0.4,
            ),
        ],
      ),
    );
  }
}
