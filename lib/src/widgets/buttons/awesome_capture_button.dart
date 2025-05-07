import 'package:camerawesome/src/widgets/buttons/timer_controller.dart';
import 'package:flutter/material.dart';
import 'package:camerawesome/camerawesome_plugin.dart';

/// A production-ready capture button that supports both instant capture
/// and “delayed” capture via a TimerController.
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

class _ProductionCaptureButtonState extends State<ProductionCaptureButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
      lowerBound: 0.0,
      upperBound: 1.0,
    )..addListener(() => setState(() {}));

    // If you want the pulse to start when video state changes, listen:
    widget.state.captureState$.listen((capture) {
      final isRecording = capture?.isRecordingVideo ?? false;
      if (isRecording) {
        _pulseController.repeat(reverse: true);
      } else {
        _pulseController.stop();
        _pulseController.reset();
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _handleTap() {
    widget.state.when(
      onPhotoMode: (photo) => photo.takePhoto(),
      onVideoMode: (video) {
        video.startRecording();
        _pulseController.repeat(reverse: true);
      },
      onVideoRecordingMode: (recording) {
        recording.stopRecording();
        _pulseController.stop();
        _pulseController.reset();
      },
      onPreparingCamera: (_) {},
    );
  }

  @override
  Widget build(BuildContext context) {
    final isRecording = widget.state is VideoRecordingCameraState;
    final tc = widget.timerController;
    final showCountdown = tc != null && tc.isTimerActive && !isRecording;
    final double pulse = isRecording ? 1 + 0.05 * _pulseController.value : 1.0;
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
          Transform.scale(
            scale: pulse,
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
