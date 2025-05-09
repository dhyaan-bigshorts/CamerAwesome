import 'dart:ui';
import 'dart:typed_data';

import 'package:camerawesome/src/orchestrator/models/models.dart';
import 'package:colorfilter_generator/addons.dart';
import 'package:colorfilter_generator/colorfilter_generator.dart';
import 'package:camerawesome/src/photofilters/filters/color_filters.dart';
import 'package:camerawesome/src/photofilters/filters/subfilters.dart';
import 'package:camerawesome/src/photofilters/filters/filters.dart';

// First, create the filter classes for the photo filter engine

// Sunrise: Strong red to blue transition with green mid-tones
class SunriseFilter extends ColorFilter {
  SunriseFilter() : super(name: "Sunrise") {
    subFilters.add(RGBScaleSubFilter(1.5, 1.2, 0.8));
  }

  @override
  void apply(Uint8List pixels, int width, int height) {
    // Apply the subfilters
    super.apply(pixels, width, height);
  }
}

// Daylight: Balanced red-green to blue transition
class DaylightFilter extends ColorFilter {
  DaylightFilter() : super(name: "Daylight") {
    subFilters.add(RGBScaleSubFilter(1.3, 1.0, 1.2));
  }

  @override
  void apply(Uint8List pixels, int width, int height) {
    // Apply the subfilters
    super.apply(pixels, width, height);
  }
}

// Jungle: Green-emphasized transition
class JungleFilter extends ColorFilter {
  JungleFilter() : super(name: "Jungle") {
    subFilters.add(RGBScaleSubFilter(1.2, 1.3, 1.5));
  }

  @override
  void apply(Uint8List pixels, int width, int height) {
    // Apply the subfilters
    super.apply(pixels, width, height);
  }
}

// Ocean: Strong green-blue bias
class OceanFilter extends ColorFilter {
  OceanFilter() : super(name: "Ocean") {
    subFilters.add(RGBScaleSubFilter(1.0, 1.5, 1.8));
  }

  @override
  void apply(Uint8List pixels, int width, int height) {
    // Apply the subfilters
    super.apply(pixels, width, height);
  }
}

// Emerald: Deep green with strong blue
class EmeraldFilter extends ColorFilter {
  EmeraldFilter() : super(name: "Emerald") {
    subFilters.add(RGBScaleSubFilter(0.9, 1.6, 2.0));
  }

  @override
  void apply(Uint8List pixels, int width, int height) {
    // Apply the subfilters
    super.apply(pixels, width, height);
  }
}

// Aurora: Muted red, strong green-blue
class AuroraFilter extends ColorFilter {
  AuroraFilter() : super(name: "Aurora") {
    subFilters.add(RGBScaleSubFilter(0.8, 1.8, 2.2));
  }

  @override
  void apply(Uint8List pixels, int width, int height) {
    // Apply the subfilters
    super.apply(pixels, width, height);
  }
}

// DeepSpace: Deep gradient with emphasized blue
class DeepSpaceFilter extends ColorFilter {
  DeepSpaceFilter() : super(name: "DeepSpace") {
    subFilters.add(RGBScaleSubFilter(0.7, 2.0, 2.4));
  }

  @override
  void apply(Uint8List pixels, int width, int height) {
    // Apply the subfilters
    super.apply(pixels, width, height);
  }
}

// Now, extend the AwesomeFilter class to include our new gradient filters

extension GradientFilters on AwesomeFilter {
  // Helper method to create color matrix for RGB scaling
  static List<double> _createRGBScaleMatrix(double r, double g, double b) {
    return [r, 0, 0, 0, 0, 0, g, 0, 0, 0, 0, 0, b, 0, 0, 0, 0, 0, 1, 0];
  }

  static AwesomeFilter get Sunrise => AwesomeFilter(
        name: 'RGB Gradient 1',
        outputFilter: SunriseFilter(),
        matrix: _createRGBScaleMatrix(1.5, 1.2, 0.8),
      );

  static AwesomeFilter get Daylight => AwesomeFilter(
        name: 'RGB Gradient 2',
        outputFilter: DaylightFilter(),
        matrix: _createRGBScaleMatrix(1.3, 1.0, 1.2),
      );

  static AwesomeFilter get Jungle => AwesomeFilter(
        name: 'RGB Gradient 3',
        outputFilter: JungleFilter(),
        matrix: _createRGBScaleMatrix(1.2, 1.3, 1.5),
      );

  static AwesomeFilter get Ocean => AwesomeFilter(
        name: 'RGB Gradient 4',
        outputFilter: OceanFilter(),
        matrix: _createRGBScaleMatrix(1.0, 1.5, 1.8),
      );

  static AwesomeFilter get Emerald => AwesomeFilter(
        name: 'RGB Gradient 5',
        outputFilter: EmeraldFilter(),
        matrix: _createRGBScaleMatrix(0.9, 1.6, 2.0),
      );

  static AwesomeFilter get Aurora => AwesomeFilter(
        name: 'RGB Gradient 6',
        outputFilter: AuroraFilter(),
        matrix: _createRGBScaleMatrix(0.8, 1.8, 2.2),
      );

  static AwesomeFilter get DeepSpace => AwesomeFilter(
        name: 'RGB Gradient 7',
        outputFilter: DeepSpaceFilter(),
        matrix: _createRGBScaleMatrix(0.7, 2.0, 2.4),
      );
}

// Add the new filters to your existing filters list
final List<AwesomeFilter> gradientFilters = [
  AwesomeFilter.Sunrise,
  AwesomeFilter.Daylight,
  AwesomeFilter.Jungle,
  AwesomeFilter.Ocean,
  AwesomeFilter.Emerald,
  AwesomeFilter.Aurora,
  AwesomeFilter.DeepSpace,
];

// BlackWhiteGradientFilter: Grayscale gradient with increasing brightness
class BlackWhiteGradientFilter extends ColorFilter {
  BlackWhiteGradientFilter() : super(name: "BlackWhiteGradient") {
    subFilters.add(GrayScaleSubFilter());
    subFilters.add(ContrastSubFilter(0.5));
  }

  @override
  void apply(Uint8List pixels, int width, int height) {
    // Apply the subfilters
    super.apply(pixels, width, height);
  }
}

// Additional RGB gradient variations

// CoolToneGradientFilter: Creates a cooler tone with less red and more blue
class CoolToneGradientFilter extends ColorFilter {
  CoolToneGradientFilter() : super(name: "CoolToneGradient") {
    subFilters.add(RGBScaleSubFilter(0.7, 0.9, 1.5));
  }

  @override
  void apply(Uint8List pixels, int width, int height) {
    // Apply the subfilters
    super.apply(pixels, width, height);
  }
}

// WarmToneGradientFilter: Creates a warmer tone with more red and less blue
class WarmToneGradientFilter extends ColorFilter {
  WarmToneGradientFilter() : super(name: "WarmToneGradient") {
    subFilters.add(RGBScaleSubFilter(1.5, 0.9, 0.7));
  }

  @override
  void apply(Uint8List pixels, int width, int height) {
    // Apply the subfilters
    super.apply(pixels, width, height);
  }
}

// HighContrastGradientFilter: Higher saturation and contrast for vibrant gradient
class HighContrastGradientFilter extends ColorFilter {
  HighContrastGradientFilter() : super(name: "HighContrastGradient") {
    subFilters.add(RGBScaleSubFilter(1.2, 1.2, 1.2));
    subFilters.add(ContrastSubFilter(0.3));
    subFilters.add(SaturationSubFilter(0.2));
  }

  @override
  void apply(Uint8List pixels, int width, int height) {
    // Apply the subfilters
    super.apply(pixels, width, height);
  }
}

// PastelGradientFilter: Softer, more faded gradient
class PastelGradientFilter extends ColorFilter {
  PastelGradientFilter() : super(name: "PastelGradient") {
    subFilters.add(BrightnessSubFilter(0.1));
    subFilters.add(SaturationSubFilter(-0.2));
    subFilters.add(RGBScaleSubFilter(1.1, 1.1, 1.3));
  }

  @override
  void apply(Uint8List pixels, int width, int height) {
    // Apply the subfilters
    super.apply(pixels, width, height);
  }
}

// DualToneGradientFilter: Strong emphasis on red and blue, less green
class DualToneGradientFilter extends ColorFilter {
  DualToneGradientFilter() : super(name: "DualToneGradient") {
    subFilters.add(RGBScaleSubFilter(1.4, 0.7, 1.4));
  }

  @override
  void apply(Uint8List pixels, int width, int height) {
    // Apply the subfilters
    super.apply(pixels, width, height);
  }
}

// RainbowVibranceFilter: Highly saturated RGB gradient
class RainbowVibranceFilter extends ColorFilter {
  RainbowVibranceFilter() : super(name: "RainbowVibrance") {
    subFilters.add(SaturationSubFilter(0.4));
    subFilters.add(ContrastSubFilter(0.2));
    subFilters.add(BrightnessSubFilter(0.1));
  }

  @override
  void apply(Uint8List pixels, int width, int height) {
    // Apply the subfilters
    super.apply(pixels, width, height);
  }
}

// NebulaGradientFilter: Space-like purple and blue dominant
class NebulaGradientFilter extends ColorFilter {
  NebulaGradientFilter() : super(name: "NebulaGradient") {
    subFilters.add(RGBScaleSubFilter(0.8, 0.9, 1.7));
    subFilters.add(RGBOverlaySubFilter(70, 0, 120, 0.1)); // Purple overlay
  }

  @override
  void apply(Uint8List pixels, int width, int height) {
    // Apply the subfilters
    super.apply(pixels, width, height);
  }
}

// SunsetGradientFilter: Warm oranges and purples
class SunsetGradientFilter extends ColorFilter {
  SunsetGradientFilter() : super(name: "SunsetGradient") {
    subFilters.add(RGBScaleSubFilter(1.4, 0.8, 1.2));
    subFilters.add(RGBOverlaySubFilter(255, 100, 0, 0.1)); // Orange overlay
  }

  @override
  void apply(Uint8List pixels, int width, int height) {
    // Apply the subfilters
    super.apply(pixels, width, height);
  }
}

// NeonGradientFilter: Bright, vibrant colors
class NeonGradientFilter extends ColorFilter {
  NeonGradientFilter() : super(name: "NeonGradient") {
    subFilters.add(BrightnessSubFilter(0.15));
    subFilters.add(SaturationSubFilter(0.5));
    subFilters.add(ContrastSubFilter(0.3));
  }

  @override
  void apply(Uint8List pixels, int width, int height) {
    // Apply the subfilters
    super.apply(pixels, width, height);
  }
}

// DeepSeaGradientFilter: Blue-green dominant
class DeepSeaGradientFilter extends ColorFilter {
  DeepSeaGradientFilter() : super(name: "DeepSeaGradient") {
    subFilters.add(RGBScaleSubFilter(0.6, 1.3, 1.5));
  }

  @override
  void apply(Uint8List pixels, int width, int height) {
    // Apply the subfilters
    super.apply(pixels, width, height);
  }
}

// TechGradientFilter: Cyan-dominant modern tech look
class TechGradientFilter extends ColorFilter {
  TechGradientFilter() : super(name: "TechGradient") {
    subFilters.add(RGBScaleSubFilter(0.7, 1.5, 1.3));
    subFilters.add(ContrastSubFilter(0.2));
  }

  @override
  void apply(Uint8List pixels, int width, int height) {
    // Apply the subfilters
    super.apply(pixels, width, height);
  }
}

// CyberGradientFilter: Pink and cyan dominant
class CyberGradientFilter extends ColorFilter {
  CyberGradientFilter() : super(name: "CyberGradient") {
    subFilters.add(RGBScaleSubFilter(1.3, 0.9, 1.3));
    subFilters
        .add(RGBOverlaySubFilter(150, 0, 255, 0.1)); // Pink-purple overlay
  }

  @override
  void apply(Uint8List pixels, int width, int height) {
    // Apply the subfilters
    super.apply(pixels, width, height);
  }
}

// MintChocolateGradientFilter: Brown and green dominant
class MintChocolateGradientFilter extends ColorFilter {
  MintChocolateGradientFilter() : super(name: "MintChocolateGradient") {
    subFilters.add(RGBScaleSubFilter(1.2, 1.4, 0.8));
    subFilters.add(SepiaSubFilter(0.2));
  }

  @override
  void apply(Uint8List pixels, int width, int height) {
    // Apply the subfilters
    super.apply(pixels, width, height);
  }
}
