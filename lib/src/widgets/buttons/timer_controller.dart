import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camerawesome/camerawesome_plugin.dart';

/// A production-quality timer controller for camera countdown functionality
class TimerController {
  // Available timer duration options in seconds
  static const List<int> availableDurations = [0, 3, 5, 10];

  // Timer state
  bool _isTimerActive = false;
  int _currentTimerSeconds = 0;
  int _selectedTimerDuration = 0; // 0 means no timer
  Timer? _countdownTimer;

  final AwesomeTheme? themeApp;

  // Callback to notify when timer completes
  final Function(CameraState) onTimerComplete;

  // Callback to notify when timer state changes
  final Function() onTimerStateChanged;

  // Constructor
  TimerController({
    required this.onTimerComplete,
    required this.onTimerStateChanged,
    required this.themeApp,
  });

  // Public getters
  bool get isTimerActive => _isTimerActive;
  int get currentTimerSeconds => _currentTimerSeconds;
  int get selectedTimerDuration => _selectedTimerDuration;

  // Dispose resources
  void dispose() {
    // cancel without notifying—avoids calling setState on a defunct element
    cancelTimer(notify: false);
  }

  // Set timer duration
  void setTimerDuration(int seconds) {
    if (availableDurations.contains(seconds)) {
      _selectedTimerDuration = seconds;
      onTimerStateChanged();
    }
  }

  // Reset timer settings completely
  void resetTimer() {
    cancelTimer();
    _selectedTimerDuration = 0;
    onTimerStateChanged();
  }

  // Start timer countdown
  void startTimerCountdown(CameraState state) {
    // If no timer set, trigger action immediately
    if (_selectedTimerDuration <= 0) {
      onTimerComplete(state);
      return;
    }

    // Cancel any existing timer
    cancelTimer();

    // Set initial timer value
    _isTimerActive = true;
    _currentTimerSeconds = _selectedTimerDuration;
    onTimerStateChanged();

    // Create the timer
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_currentTimerSeconds > 1) {
        _currentTimerSeconds--;
        onTimerStateChanged();
      } else {
        // Timer completed, cancel it
        cancelTimer();

        // Trigger the completion callback
        onTimerComplete(state);

        // Reset the timer selection after successful completion
        _selectedTimerDuration = 0;
        onTimerStateChanged();
      }
    });
  }

  // Cancel the active timer without resetting selection
  void cancelTimer({bool notify = true}) {
    if (_countdownTimer?.isActive ?? false) {
      _countdownTimer!.cancel();
    }

    _isTimerActive = false;
    _currentTimerSeconds = 0;
    if (notify) {
      onTimerStateChanged();
    }
  }

  // Build an elegant dropdown for timer selection
  Widget buildElegantTimerSelector(BuildContext context) {
    final theme = Theme.of(context);

    return Theme(
      data: theme.copyWith(
        popupMenuTheme: PopupMenuThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          color: Colors.black87,
        ),
      ),
      child: Stack(
        alignment: Alignment.topRight,
        children: [
          PopupMenuButton<int>(
            offset: const Offset(0, 0),
            tooltip: 'Timer',
            icon: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(0),
              child: Icon(
                Icons.timer,
                color: _selectedTimerDuration > 0 ? Colors.amber : Colors.white,
              ),
            ),
            onSelected: (duration) {
              setTimerDuration(duration);
            },
            itemBuilder: (context) => [
              for (final duration in availableDurations)
                PopupMenuItem<int>(
                  value: duration,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.transparent,
                    ),
                    padding:
                        const EdgeInsets.symmetric(vertical: 0, horizontal: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          duration == 0 ? 'Off' : '${duration}s',
                          style: TextStyle(
                            color: duration == _selectedTimerDuration
                                ? Colors.amber
                                : Colors.white,
                            fontWeight: duration == _selectedTimerDuration
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        if (duration == _selectedTimerDuration)
                          Container(
                            height: 8,
                            width: 8,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.amber,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          ),

          // Add a reset button when timer is selected
        ],
      ),
    );
  }
}
