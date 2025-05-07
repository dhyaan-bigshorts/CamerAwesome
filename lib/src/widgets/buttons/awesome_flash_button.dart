import 'package:camerawesome/src/widgets/utils/awesome_circle_icon.dart';
import 'package:camerawesome/src/widgets/utils/awesome_theme.dart';
import 'package:flutter/material.dart';

import 'package:camerawesome/src/orchestrator/models/camera_flashes.dart';
import 'package:camerawesome/src/orchestrator/models/sensor_config.dart';
import 'package:camerawesome/src/orchestrator/states/camera_state.dart';
import 'package:camerawesome/src/widgets/utils/awesome_oriented_widget.dart';

class AwesomeFlashButton extends StatelessWidget {
  final CameraState state;
  final AwesomeTheme? theme;
  final Widget Function(FlashMode) iconBuilder;
  final void Function(SensorConfig, FlashMode) onFlashTap;
  final bool enableFlashOnForVideo;

  AwesomeFlashButton({
    super.key,
    required this.state,
    this.theme,
    Widget Function(FlashMode)? iconBuilder,
    void Function(SensorConfig, FlashMode)? onFlashTap,
    this.enableFlashOnForVideo = false,
  })  : iconBuilder = iconBuilder ??
            ((flashMode) {
              final IconData icon;
              switch (flashMode) {
                case FlashMode.none:
                  icon = Icons.flash_off;
                  break;
                case FlashMode.on:
                  icon = Icons.flash_on;
                  break;
                case FlashMode.auto:
                  icon = Icons.flash_auto;
                  break;
                case FlashMode.always:
                  icon = Icons.flashlight_on;
                  break;
              }
              return AwesomeCircleWidget.icon(
                icon: icon,
                theme: theme,
              );
            }),
        onFlashTap = onFlashTap ??
            ((sensorConfig, flashMode) => sensorConfig.switchCameraFlash());

  @override
  Widget build(BuildContext context) {
    final theme = this.theme ?? AwesomeThemeProvider.of(context).theme;
    return StreamBuilder<SensorConfig>(
      stream: state.sensorConfig$,
      builder: (_, sensorConfigSnapshot) {
        if (!sensorConfigSnapshot.hasData) {
          return const SizedBox.shrink();
        }
        final sensorConfig = sensorConfigSnapshot.requireData;
        return StreamBuilder<FlashMode>(
          stream: sensorConfig.flashMode$,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const SizedBox.shrink();
            }

            // Skip the button if we're in video mode and flash on is disabled for video
            ;
            if (!enableFlashOnForVideo &&
                snapshot.requireData == FlashMode.on) {
              return const SizedBox.shrink();
            }

            return AwesomeOrientedWidget(
              rotateWithDevice: theme.buttonTheme.rotateWithCamera,
              child: theme.buttonTheme.buttonBuilder(
                iconBuilder(snapshot.requireData),
                () {
                  // If video mode and flash is disabled for video, skip FlashMode.on
                  if (!enableFlashOnForVideo) {
                    final nextFlash =
                        _getNextFlashWithoutOn(snapshot.requireData);
                    sensorConfig.setFlashMode(nextFlash);
                  } else {
                    onFlashTap(sensorConfig, snapshot.requireData);
                  }
                },
              ),
            );
          },
        );
      },
    );
  }

  // Helper method to get the next flash mode, skipping FlashMode.on when in video mode
  FlashMode _getNextFlashWithoutOn(FlashMode current) {
    switch (current) {
      case FlashMode.none:
        return FlashMode.auto;
      case FlashMode.auto:
        return FlashMode.always;
      case FlashMode.always:
        return FlashMode.none;
      case FlashMode.on:
        return FlashMode.auto; // Skip to auto if somehow on FlashMode.on
    }
  }
}
