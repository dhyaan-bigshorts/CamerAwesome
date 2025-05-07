import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class AppConfig {
  final BuildContext _context;

  AppConfig(this._context);

  Size deviceSize() {
    return Size(100.w, 100.h);
  }

  double deviceHeight(double v) {
    return v.h;
  }

  double deviceWidth(double v) {
    return v.w;
  }

  double rHP(double v) {
    // Note: This doesn't consider SafeArea, just like the original implementation
    return v.h;
  }

  double rWP(double v) {
    // Note: This doesn't consider SafeArea, just like the original implementation
    return v.w;
  }

  double responsiveTextSize(double size) {
    return size.sp;
  }

  // You can add more methods here if needed, utilizing Sizer's functionality
}
