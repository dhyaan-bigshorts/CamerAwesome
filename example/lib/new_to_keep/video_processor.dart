import 'dart:io';
import 'package:ffmpeg_kit_flutter_audio/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_audio/return_code.dart';
import 'package:flutter/material.dart';
import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:path_provider/path_provider.dart';

/// Simple class to apply filter to videos
class VideoFilter {
  /// Apply filter to a video
  /// Returns the path to the processed video
  static Future<String> applyFilter({
    required String inputPath,
    required AwesomeFilter filter,
  }) async {
    if (filter == AwesomeFilter.None) return inputPath;

    try {
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final outputPath = '${tempDir.path}/filtered_$timestamp.mp4';

      if (filter.matrix != null) {
        final matrix = filter.matrix!;

        // Create colorchannelmixer filter
        String matrixFilter = 'colorchannelmixer=';
        matrixFilter += '${matrix[0]}:${matrix[1]}:${matrix[2]}:${matrix[3]}:';
        matrixFilter += '${matrix[5]}:${matrix[6]}:${matrix[7]}:${matrix[8]}:';
        matrixFilter +=
            '${matrix[10]}:${matrix[11]}:${matrix[12]}:${matrix[13]}';

        // Try MPEG-4 with high quality
        String command =
            '-i "$inputPath" -filter:v "$matrixFilter" -c:v mpeg4 -q:v 1 -c:a copy "$outputPath"';

        debugPrint('FFmpeg command: $command');
        var session = await FFmpegKit.execute(command);
        var returnCode = await session.getReturnCode();

        if (ReturnCode.isSuccess(returnCode)) {
          return outputPath;
        }

        return inputPath;
      }
      return inputPath;
    } catch (e) {
      return inputPath;
    }
  }

  /// Apply filter to multiple videos
  static Future<List<String>> applyFilterToVideos({
    required List<String> videoPaths,
    required List<AwesomeFilter> filters,
  }) async {
    final filteredVideos = <String>[];
    final count =
        videoPaths.length < filters.length ? videoPaths.length : filters.length;

    for (var i = 0; i < count; i++) {
      final path = videoPaths[i];
      final filter = filters[i];
      final filteredPath = await applyFilter(
        inputPath: path,
        filter: filter,
      );
      filteredVideos.add(filteredPath);
    }

    // If you want to handle extra videos (or extra filters), you can:
    // • Copy the remaining originals:
    // filteredVideos.addAll(videoPaths.sublist(count));
    // • Or re-use the last filter:
    // for (var i = count; i < videoPaths.length; i++) { … }

    return filteredVideos;
  }
}
