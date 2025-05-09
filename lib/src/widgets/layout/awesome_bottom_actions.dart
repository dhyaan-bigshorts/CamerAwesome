import 'package:camerawesome/src/orchestrator/models/media_capture.dart';
import 'package:camerawesome/src/orchestrator/states/states.dart';
import 'package:camerawesome/src/widgets/awesome_media_preview.dart';
import 'package:camerawesome/src/widgets/buttons/awesome_camera_switch_button.dart';
import 'package:camerawesome/src/widgets/buttons/awesome_capture_button.dart';
import 'package:camerawesome/src/widgets/buttons/awesome_pause_resume_button.dart';
import 'package:camerawesome/src/widgets/camera_awesome_builder.dart';
import 'package:camerawesome/src/widgets/utils/awesome_theme.dart';
import 'package:flutter/material.dart';

class AwesomeBottomActions extends StatelessWidget {
  final CameraState state;
  final Widget right;
  final Widget captureButton;
  final EdgeInsets padding;
  final List<Widget> floatingColumn; // Column of floating widgets
  final Widget? left; // Converted left to floating left

  AwesomeBottomActions({
    super.key,
    required this.state,
    Widget? left,
    Widget? right,
    Widget? captureButton,
    List<Widget>? floatingColumn,
    OnMediaTap? onMediaTap,
    this.padding = const EdgeInsets.symmetric(vertical: 0, horizontal: 8),
  })  : captureButton = captureButton ??
            ProductionCaptureButton(
              state: state,
            ),
        floatingColumn = floatingColumn ?? [],
        left = left ??
            (state is VideoRecordingCameraState
                ? null // No floating left in recording state
                : Builder(builder: (context) {
                    final theme = AwesomeThemeProvider.of(context).theme;
                    return AwesomeCameraSwitchButton(
                      state: state,
                      theme: theme.copyWith(
                        buttonTheme: theme.buttonTheme.copyWith(
                          backgroundColor: Colors.white12,
                        ),
                      ),
                    );
                  })),
        right = right ??
            (state is VideoRecordingCameraState
                ? const SizedBox(width: 48)
                : StreamBuilder<MediaCapture?>(
                    stream: state.captureState$,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const SizedBox(width: 60, height: 60);
                      }
                      return SizedBox(
                        width: 60,
                        child: AwesomeMediaPreview(
                          mediaCapture: snapshot.requireData,
                          onMediaTap: onMediaTap,
                        ),
                      );
                    },
                  ));

  @override
  Widget build(BuildContext context) {
    // ensure we have a placeholder for left when it's null
    final leftWidget = left != null
        ? GestureDetector(
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12, left: 12),
              child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: left!),
            ),
          )
        : const SizedBox(width: 48);

    return Stack(
      alignment: Alignment.bottomCenter,
      clipBehavior: Clip.none,
      children: [
        // the row with just left & right, spread to edges
        Padding(
          padding: padding,
          child: Stack(
            alignment: Alignment.center, // center children horizontally
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  leftWidget,
                  right,
                ],
              ),
              // this will sit exactly in the horizontal center
              captureButton,
            ],
          ),
        ),

        // any floatingColumn items, unchanged
        if (floatingColumn.isNotEmpty)
          Positioned(
            left: 30,
            bottom: 90,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: floatingColumn
                  .map((w) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: w,
                      ))
                  .toList(),
            ),
          ),
      ],
    );
  }
}
