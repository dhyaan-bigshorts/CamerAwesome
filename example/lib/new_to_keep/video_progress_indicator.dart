import 'dart:async';
import 'package:camera_app/new_to_keep/app_config.dart';
import 'package:flutter/material.dart';
import 'package:camerawesome/src/orchestrator/models/media_capture.dart';
import 'package:camerawesome/src/orchestrator/states/video_camera_recording_state.dart';

/// Widget that displays recording progress including:
/// 1. Total recording time across multiple clips
/// 2. Current clip recording time (when actively recording)
/// 3. Visual progress indicator
class VideoRecordingProgress extends StatefulWidget {
  final VideoRecordingCameraState? state;
  final List<Duration> previousRecordingsDurations;
  final Color progressColor;
  final Color backgroundColor;
  final double height;
  final EdgeInsets padding;
  final double maxDuration;
  final double? currentSpeed;

  final VoidCallback? stop;

  const VideoRecordingProgress(
      {super.key,
      this.state,
      this.maxDuration = 2.0,
      this.previousRecordingsDurations = const [],
      this.progressColor = Colors.red,
      this.backgroundColor = Colors.black45,
      this.height = 5.0,
      this.currentSpeed,
      this.padding =
          const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      this.stop});

  @override
  State<VideoRecordingProgress> createState() => _VideoRecordingProgressState();
}

class _VideoRecordingProgressState extends State<VideoRecordingProgress> {
  Timer? _timer;
  Duration _currentDuration = Duration.zero;
  bool _isRecording = false;
  VideoState _videoState = VideoState.started;
  DateTime? _recordingStartTime;
  StreamSubscription? _stateSubscription;

  // Total duration of all previous recordings
  Duration get _totalPreviousDuration {
    if (widget.previousRecordingsDurations.isEmpty) {
      return Duration.zero;
    }
    return widget.previousRecordingsDurations.reduce((a, b) => a + b);
  }

  // Combined duration (previous + current)
  Duration get _totalDuration => _totalPreviousDuration + _currentDuration;

  @override
  void initState() {
    super.initState();
    if (widget.state != null) {
      _startListeningToRecordingState();
    }
  }

  @override
  void didUpdateWidget(VideoRecordingProgress oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Handle state changes
    if (oldWidget.state != widget.state) {
      _stopListening();

      if (widget.state != null) {
        _startListeningToRecordingState();
      } else {
        // Reset current recording state when state becomes null
        _stopTimer();
        setState(() {
          _isRecording = false;
          _currentDuration = Duration.zero;
        });
      }
    }
  }

  void _startListeningToRecordingState() {
    _stateSubscription = widget.state?.captureState$.listen((captureState) {
      if (captureState == null) {
        _updateRecordingState(false, VideoState.started);
        return;
      }

      final bool isRecording = captureState.isRecordingVideo;
      final VideoState? videoState = captureState.videoState;

      if (isRecording != _isRecording || videoState != _videoState) {
        _updateRecordingState(isRecording, videoState ?? VideoState.started);
      }
    });
  }

  void _stopListening() {
    _stateSubscription?.cancel();
    _stateSubscription = null;
  }

  void _updateRecordingState(bool isRecording, VideoState videoState) {
    setState(() {
      _isRecording = isRecording;
      _videoState = videoState;

      if (isRecording && videoState == VideoState.started) {
        if (_recordingStartTime == null) {
          _recordingStartTime = DateTime.now();
        }
        _startTimer();
      } else if (videoState == VideoState.paused) {
        _stopTimer();
      } else if (!isRecording) {
        _stopTimer();
        _recordingStartTime = null;
        _currentDuration = Duration.zero;
      }
    });
  }

  void _startTimer() {
    _stopTimer(); // Ensure we don't have multiple timers

    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (_recordingStartTime != null && mounted) {
        final elapsed = DateTime.now().difference(_recordingStartTime!);

        // Apply speed adjustment to the elapsed time
        final speedAdjustedElapsed = widget.currentSpeed != null
            ? Duration(
                microseconds:
                    (elapsed.inMicroseconds / widget.currentSpeed!).round())
            : elapsed;
        final total = _totalPreviousDuration + speedAdjustedElapsed;

        if (total.inMilliseconds >= (widget.maxDuration * 60 * 1000).toInt()) {
          // Stop recording when max duration is reached
          widget.stop!();
          _stopTimer();
          return;
        }

        setState(() {
          _currentDuration = speedAdjustedElapsed;
        });
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _stopTimer();
    _stopListening();
    super.dispose();
  }

  // Format duration as MM:SS.ms
  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    final milliseconds =
        ((duration.inMilliseconds % 1000) ~/ 10).toString().padLeft(2, '0');
    return '$minutes:$seconds.$milliseconds';
  }

  @override
  Widget build(BuildContext context) {
    final AppConfig appConfig = AppConfig(context);

    // Define your maximum recording length (in ms)
    final int maxMs = (widget.maxDuration * 60 * 1000).toInt();

    // 1) Compute cumulative end times of each previous clip
    final cumulative = <int>[];
    var sum = 0;
    for (final d in widget.previousRecordingsDurations) {
      sum += d.inMilliseconds;
      cumulative.add(sum.clamp(0, maxMs));
    }

    // 2) Current clip adds its own run if recording
    final currentMs = _currentDuration.inMilliseconds.clamp(0, maxMs);
    final totalMs = (sum + currentMs).clamp(0, maxMs);

    // 3) Fraction of total for the gradient fill
    final fillFactor = totalMs / maxMs;

    return SizedBox(
      width: appConfig.deviceWidth(96),
      child: Padding(
        padding: widget.padding,
        child: LayoutBuilder(builder: (ctx, constraints) {
          final barWidth = constraints.maxWidth;
          return Stack(
            children: [
              // Background rail
              Container(
                width: barWidth,
                height: widget.height,
                decoration: BoxDecoration(
                  color: widget.backgroundColor,
                  borderRadius: BorderRadius.circular(widget.height / 2),
                ),
              ),

              // Gradient fill
              FractionallySizedBox(
                widthFactor: fillFactor,
                child: Container(
                  height: widget.height,
                  decoration: BoxDecoration(
                    gradient:
                        widget.state != null && _videoState == VideoState.paused
                            ? const LinearGradient(
                                colors: [Colors.amber, Colors.amberAccent],
                              )
                            : const LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: <Color>[
                                  Color(0xff03FCFE),
                                  Color(0xff03FCFE),
                                  Color(0xff599BEF),
                                  Color(0xff8868E7),
                                  Color(0xffB33ADF),
                                  Color(0xffE300DD),
                                ],
                              ),
                    borderRadius: BorderRadius.circular(widget.height / 2),
                  ),
                ),
              ),

              // Ticks at each previous-clip boundary
              for (final clipEnd in cumulative)
                Positioned(
                  left: (clipEnd / maxMs) * barWidth - 1,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 2,
                    color: Colors.white,
                  ),
                ),
            ],
          );
        }),
      ),
    );
  }
}
