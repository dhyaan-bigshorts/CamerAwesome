import 'dart:io';

import 'package:camerawesome/src/orchestrator/models/capture_modes.dart';
import 'package:camerawesome/src/orchestrator/models/filters/awesome_filter.dart';
import 'package:camerawesome/src/orchestrator/states/states.dart';
import 'package:camerawesome/src/widgets/awesome_camera_mode_selector.dart';
import 'package:camerawesome/src/widgets/camera_awesome_builder.dart';
import 'package:camerawesome/src/widgets/filters/awesome_filter_widget.dart';
import 'package:camerawesome/src/widgets/layout/layout.dart';
import 'package:camerawesome/src/widgets/utils/awesome_theme.dart';
import 'package:camerawesome/src/widgets/zoom/awesome_zoom_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// This widget doesn't handle [PreparingCameraState]
class AwesomeCameraLayout extends StatelessWidget {
  final CameraState state;
  final Widget? middleContent;
  final Widget? topActions;
  final Widget? bottomActions;

  // Add reset button functionality
  final VoidCallback? onResetPressed;
  final bool hasRecordedVideos;
  final AwesomeFilter? selectedFilter;

  AwesomeCameraLayout(
      {super.key,
      required this.state,
      OnMediaTap? onMediaTap,
      Widget? middleContent,
      Widget? topActions,
      Widget? bottomActions,
      this.onResetPressed, // New parameter
      this.hasRecordedVideos = false, // New parameter
      this.selectedFilter})
      : middleContent = middleContent ??
            (Column(
              children: [
                const Spacer(),
                // Add reset button when there are recorded videos
                if (hasRecordedVideos)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: IconButton(
                      icon: const Icon(
                        Icons.refresh,
                        color: Colors.white,
                      ),
                      tooltip: 'Delete last video',
                      onPressed: onResetPressed,
                    ),
                  ),
                if (state is PhotoCameraState && state.hasFilters)
                  AwesomeFilterWidget(state: state)
                else if (!kIsWeb && Platform.isAndroid)
                  AwesomeZoomSelector(state: state),
                AwesomeCameraModeSelector(state: state),
              ],
            )),
        topActions = topActions ?? AwesomeTopActions(state: state),
        bottomActions = bottomActions ??
            AwesomeBottomActions(state: state, onMediaTap: onMediaTap);

  @override
  Widget build(BuildContext context) {
    final theme = AwesomeThemeProvider.of(context).theme;
    return SafeArea(
      bottom: false,
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          topActions!,
          Expanded(child: middleContent!),
          Container(
            color: theme.bottomActionsBackgroundColor,
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  bottomActions!,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
