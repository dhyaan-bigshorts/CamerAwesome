import 'package:flutter/material.dart';

/// Manages a list of playback speeds and notifies listeners when the
/// selected speed changes.
class SpeedController extends ChangeNotifier {
  /// The available playback speeds (e.g. 1×, 1.5×, 2×).
  final List<double> speeds;

  double _currentSpeed;

  /// The currently selected playback speed.
  double get currentSpeed => _currentSpeed;

  /// Create a [SpeedController].
  ///
  /// [speeds] must not be empty, and [initialSpeed] must be one of [speeds].
  SpeedController({
    this.speeds = const [1.0, 1.5, 2.0, 3.0],
    double initialSpeed = 1.0,
  })  : assert(speeds.isNotEmpty, 'Speeds list cannot be empty'),
        assert(
          speeds.contains(initialSpeed),
          'initialSpeed must be one of the provided speeds',
        ),
        _currentSpeed = initialSpeed;

  /// Set playback speed to [speed], if it exists in [speeds].
  void setSpeed(double speed) {
    if (speeds.contains(speed) && speed != _currentSpeed) {
      _currentSpeed = speed;
      notifyListeners();
    }
  }

  /// Reset speed back to 1×.
  void reset() {
    setSpeed(1.0);
  }
}

/// A widget that displays the current speed and, when tapped,
/// shows a dropdown menu of all available speeds.
///
/// Hooks into [SpeedController] to rebuild automatically.

/// A horizontal overlay selector for playback speeds.
/// Tapping the current speed shows an overlay row of all speeds,
/// with the selected one highlighted in amber.
class SpeedOverlaySelector extends StatefulWidget {
  final SpeedController controller;
  final double fontSize;
  final EdgeInsetsGeometry padding;

  const SpeedOverlaySelector({
    Key? key,
    required this.controller,
    this.fontSize = 14.0,
    this.padding = const EdgeInsets.only(top: 12),
  }) : super(key: key);

  @override
  _SpeedOverlaySelectorState createState() => _SpeedOverlaySelectorState();
}

class _SpeedOverlaySelectorState extends State<SpeedOverlaySelector> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  void _toggleOverlay() {
    if (_overlayEntry == null) {
      _showOverlay();
    } else {
      _removeOverlay();
    }
  }

  void _showOverlay() {
    _overlayEntry = OverlayEntry(builder: (context) {
      return GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _removeOverlay,
        child: Stack(
          children: [
            CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              // Align the follower’s top-right to the target’s bottom-right
              targetAnchor: Alignment.bottomRight,
              followerAnchor: Alignment.topRight,
              offset: const Offset(0, 8), // small vertical gap
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(8),
                color: Colors.black87,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: widget.controller.speeds.map((speed) {
                      final isSelected =
                          speed == widget.controller.currentSpeed;
                      return GestureDetector(
                        onTap: () {
                          widget.controller.setSpeed(speed);
                          _removeOverlay();
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color:
                                isSelected ? Colors.amber : Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${speed}×',
                            style: TextStyle(
                              fontSize: widget.fontSize,
                              color: isSelected ? Colors.black : Colors.white,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });

    Overlay.of(context)!.insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: AnimatedBuilder(
        animation: widget.controller,
        builder: (_, __) => GestureDetector(
          onTap: _toggleOverlay,
          child: Container(
            padding: widget.padding,
            child: Text(
              '${widget.controller.currentSpeed}×',
              style: TextStyle(
                fontSize: widget.fontSize,
                fontWeight: FontWeight.bold,
                color: widget.controller.currentSpeed > 1.0
                    ? Colors.amber
                    : Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
