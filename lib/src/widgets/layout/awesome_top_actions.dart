import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:camerawesome/src/orchestrator/states/states.dart';
import 'package:camerawesome/src/widgets/buttons/awesome_aspect_ratio_button.dart';
import 'package:camerawesome/src/widgets/buttons/awesome_flash_button.dart';
import 'package:camerawesome/src/widgets/buttons/awesome_location_button.dart';
import 'package:flutter/material.dart';

class AwesomeTopActions extends StatelessWidget {
  final CameraState state;

  /// Show only children that are relevant to the current [state]
  final List<Widget> children;
  final List<Widget>? ultraWide;
  final EdgeInsets padding;

  AwesomeTopActions({
    super.key,
    required this.state,
    this.ultraWide,
    List<Widget>? children,
    this.padding = const EdgeInsets.only(left: 30, right: 30, top: 20),
  }) : children = children ??
            (state is VideoRecordingCameraState
                ? [const SizedBox.shrink()]
                : [
                    AwesomeFlashButton(state: state),
                    const SizedBox(width: 16),
                    if (state is PhotoCameraState) ...[
                      AwesomeAspectRatioButton(state: state),
                      const SizedBox(width: 16),
                    ],
                    if (state is PhotoCameraState) ...[
                      AwesomeLocationButton(state: state),
                    ],
                  ]);

  @override
  Widget build(BuildContext context) {
    // Skip rendering if no widgets to show
    if ((children.isEmpty || children.first is SizedBox) &&
        (ultraWide == null || ultraWide!.isEmpty)) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Main top row of buttons
          if (children.isNotEmpty && children.first is! SizedBox)
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: children,
            ),

          // UltraWide column
          if (ultraWide != null && ultraWide!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12, right: 4),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(4),
                ),
                padding: const EdgeInsets.only(top: 16, bottom: 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    if ((state is VideoCameraState ||
                            state is PhotoCameraState) &&
                        state.sensorConfig.sensors.first.position ==
                            SensorPosition.back) ...[
                      AwesomeFlashButton(state: state),
                      const SizedBox(height: 12),
                    ],
                    ...ultraWide!.map(
                      (widget) => widget,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
