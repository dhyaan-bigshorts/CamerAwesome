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
    this.padding = const EdgeInsets.only(left: 30, right: 30, top: 5),
  }) : children = children ??
            (state is VideoRecordingCameraState
                ? [const SizedBox.shrink()]
                : [
                    AwesomeFlashButton(state: state),
                    if (state is PhotoCameraState)
                      AwesomeAspectRatioButton(state: state),
                    if (state is PhotoCameraState)
                      AwesomeLocationButton(state: state),
                  ]);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: children,
          ),
          Padding(
              padding: padding,
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (state is VideoCameraState &&
                        state.sensorConfig.sensors.first.position ==
                            SensorPosition.back)
                      AwesomeFlashButton(state: state),
                    const AwesomeCircleWidget(
                        child: Icon(
                      Icons.repeat,
                    )),
                    ...?ultraWide,
                  ]))
        ],
      ),
    );
  }
}
