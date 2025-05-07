import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:flutter/material.dart';
import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:flutter/material.dart';

class AwesomeZoomSelector extends StatefulWidget {
  final CameraState state;
  final AwesomeTheme? theme;

  /// If you really want to optionally override, otherwise leave null
  final double? maxWidth;
  const AwesomeZoomSelector({
    super.key,
    required this.state,
    this.theme,
    this.maxWidth,
  });

  @override
  _AwesomeZoomSelectorState createState() => _AwesomeZoomSelectorState();
}

class _AwesomeZoomSelectorState extends State<AwesomeZoomSelector> {
  double? _minZoom, _maxZoom;

  @override
  void initState() {
    super.initState();
    _loadZoomRange();
  }

  Future<void> _loadZoomRange() async {
    _minZoom = await CamerawesomePlugin.getMinZoom();
    _maxZoom = await CamerawesomePlugin.getMaxZoom();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_minZoom == null || _maxZoom == null) return const SizedBox.shrink();
    final theme = widget.theme ?? AwesomeThemeProvider.of(context).theme;

    // four candidate zoom levels
    const candidateLevels = [0.5, 1.0, 2.0, 4.0, 8.0];

    return StreamBuilder<double>(
      stream: widget.state.sensorConfig.zoom$,
      builder: (_, zoomSnap) {
        if (!zoomSnap.hasData) return const SizedBox.shrink();
        final currentNorm = zoomSnap.data!;
        // actual zoom factor
        final displayZoom = _minZoom! + currentNorm * (_maxZoom! - _minZoom!);

        // your fixed zoom‐level buttons
        const candidateLevels = [0.5, 1.0, 2.0, 4.0];
        final zoomLevels = candidateLevels
            .where((t) => t >= _minZoom! && t <= _maxZoom!)
            .toList();

        // pick the “selected” level = the greatest one <= displayZoom
        final selectedLevel = zoomLevels.lastWhere(
          (t) => displayZoom >= t,
          orElse: () => zoomLevels.first,
        );

        return Center(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: theme.buttonTheme.backgroundColor,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: zoomLevels.map((target) {
                final norm = (target - _minZoom!) / (_maxZoom! - _minZoom!);
                final isSelected = target == selectedLevel;

                // if this is the “selected” button, show live zoom
                final label = isSelected
                    ? "${displayZoom.toStringAsFixed(1)}×"
                    : "$target×";

                return GestureDetector(
                  onTap: () => widget.state.sensorConfig.setZoom(norm),
                  child: Container(
                    width: 48,
                    height: 32,
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white24 : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white70,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }
}

class _ZoomIndicatorLayout extends StatelessWidget {
  final double zoom;
  final double min;
  final double max;
  final SensorConfig sensorConfig;

  const _ZoomIndicatorLayout({
    required this.zoom,
    required this.min,
    required this.max,
    required this.sensorConfig,
  });

  @override
  Widget build(BuildContext context) {
    final displayZoom = (max - min) * zoom + min;
    if (min == 1.0) {
      // Assume there's only one lens for zooming purpose, only display current zoom
      return _ZoomIndicator(
        normalValue: 0.0,
        zoom: zoom,
        selected: true,
        min: min,
        max: max,
        sensorConfig: sensorConfig,
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Show 3 dots for zooming: min, 1.0X and max zoom. The closer one shows
        // text, the other ones a dot.
        _ZoomIndicator(
          normalValue: 0.0,
          zoom: zoom,
          selected: displayZoom < 1.0,
          min: min,
          max: max,
          sensorConfig: sensorConfig,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: _ZoomIndicator(
            normalValue: (1 - min) / (max - min),
            zoom: zoom,
            selected: !(displayZoom < 1.0 || displayZoom == max),
            min: min,
            max: max,
            sensorConfig: sensorConfig,
          ),
        ),
        _ZoomIndicator(
          normalValue: 1.0,
          zoom: zoom,
          selected: displayZoom == max,
          min: min,
          max: max,
          sensorConfig: sensorConfig,
        ),
      ],
    );
  }
}

class _ZoomIndicator extends StatelessWidget {
  final double zoom;
  final double min;
  final double max;
  final double normalValue;
  final SensorConfig sensorConfig;
  final bool selected;

  const _ZoomIndicator({
    required this.zoom,
    required this.min,
    required this.max,
    required this.normalValue,
    required this.sensorConfig,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    final baseTheme = AwesomeThemeProvider.of(context).theme;
    final baseButtonTheme = baseTheme.buttonTheme;
    final displayZoom = (max - min) * zoom + min;
    Widget content = AnimatedSwitcher(
      duration: const Duration(milliseconds: 100),
      transitionBuilder: (child, anim) {
        return ScaleTransition(scale: anim, child: child);
      },
      child: selected
          ? AwesomeBouncingWidget(
              key: ValueKey("zoomIndicator_${normalValue}_selected"),
              onTap: () {
                sensorConfig.setZoom(normalValue);
              },
              child: Container(
                color: Colors.transparent,
                padding: const EdgeInsets.all(0.0),
                child: AwesomeCircleWidget(
                  theme: baseTheme,
                  child: Text(
                    "${displayZoom.toStringAsFixed(1)}X",
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
            )
          : AwesomeBouncingWidget(
              key: ValueKey("zoomIndicator_${normalValue}_unselected"),
              onTap: () {
                sensorConfig.setZoom(normalValue);
              },
              child: Container(
                color: Colors.transparent,
                padding: const EdgeInsets.all(16.0),
                child: AwesomeCircleWidget(
                  theme: baseTheme.copyWith(
                    buttonTheme: baseButtonTheme.copyWith(
                      backgroundColor: baseButtonTheme.foregroundColor,
                      padding: EdgeInsets.zero,
                    ),
                  ),
                  child: const SizedBox(width: 6, height: 6),
                ),
              ),
            ),
    );

    // Same width for each dot to keep them in their position
    return SizedBox(
      width: 56,
      child: Center(
        child: content,
      ),
    );
  }
}
