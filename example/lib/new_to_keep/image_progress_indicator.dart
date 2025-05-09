import 'package:camera_app/new_to_keep/app_config.dart';
import 'package:flutter/material.dart';

class ImageProgressBar extends StatelessWidget {
  /// Total number of images you plan to capture.
  final int maxCount;

  /// How many images have been captured so far.
  final int currentCount;

  /// Bar colors & dimensions.
  final Color backgroundColor;
  final Color tickColor;
  final double height;
  final EdgeInsets padding;

  /// Instead of a single color, you can pass a gradient here.
  /// If null, defaults to a simple two-tone fade.
  final Gradient? progressGradient;

  const ImageProgressBar({
    Key? key,
    required this.maxCount,
    required this.currentCount,
    this.backgroundColor = Colors.black45,
    this.tickColor = Colors.white,
    this.height = 4.0,
    this.padding = const EdgeInsets.symmetric(vertical: 8.0),
    this.progressGradient,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final count = currentCount.clamp(0, maxCount);
    final fraction = maxCount > 0 ? count / maxCount : 0.0;

    // compute total width via your AppConfig helper
    final totalWidth = AppConfig(context).deviceWidth(96);

    return SizedBox(
      width: totalWidth,
      child: Padding(
        padding: padding,
        child: LayoutBuilder(builder: (ctx, constraints) {
          final barWidth = constraints.maxWidth;
          return Stack(
            children: [
              // 1) background
              Container(
                width: barWidth,
                height: height,
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(height / 2),
                ),
              ),

              // 2) filled gradient
              FractionallySizedBox(
                widthFactor: fraction,
                child: Container(
                  height: height,
                  decoration: BoxDecoration(
                    // use your passed‐in gradient or default to a rainbow‐style
                    gradient: progressGradient ??
                        const LinearGradient(
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
                    borderRadius: BorderRadius.circular(height / 2),
                  ),
                ),
              ),

              // 3) tick marks
              for (int i = 1; i < maxCount; i++)
                Positioned(
                  left: (i / maxCount) * barWidth - 0.5,
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
