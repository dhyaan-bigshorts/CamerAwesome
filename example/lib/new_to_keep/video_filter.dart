import 'package:flutter/material.dart';

abstract class VideoFilter {
  String get name;
  Widget apply(Widget cameraPreview);
}

class NormalFilter extends VideoFilter {
  @override
  String get name => 'Normal';

  @override
  Widget apply(Widget cameraPreview) {
    return cameraPreview; // No filter
  }
}

class GrayscaleFilter extends VideoFilter {
  @override
  String get name => 'Grayscale';

  @override
  Widget apply(Widget cameraPreview) {
    return ColorFiltered(
      colorFilter: const ColorFilter.matrix([
        0.2126,
        0.7152,
        0.0722,
        0,
        0,
        0.2126,
        0.7152,
        0.0722,
        0,
        0,
        0.2126,
        0.7152,
        0.0722,
        0,
        0,
        0,
        0,
        0,
        1,
        0,
      ]),
      child: cameraPreview,
    );
  }
}

class SepiaFilter extends VideoFilter {
  @override
  String get name => 'Sepia';

  @override
  Widget apply(Widget cameraPreview) {
    return ColorFiltered(
      colorFilter: const ColorFilter.matrix([
        0.393,
        0.769,
        0.189,
        0,
        0,
        0.349,
        0.686,
        0.168,
        0,
        0,
        0.272,
        0.534,
        0.131,
        0,
        0,
        0,
        0,
        0,
        1,
        0,
      ]),
      child: cameraPreview,
    );
  }
}

class VintageFilter extends VideoFilter {
  @override
  String get name => 'Vintage';

  @override
  Widget apply(Widget cameraPreview) {
    return ColorFiltered(
      colorFilter: const ColorFilter.matrix([
        0.9,
        0.5,
        0.1,
        0,
        0,
        0.3,
        0.8,
        0.1,
        0,
        0,
        0.2,
        0.3,
        0.5,
        0,
        0,
        0,
        0,
        0,
        1,
        0,
      ]),
      child: cameraPreview,
    );
  }
}
