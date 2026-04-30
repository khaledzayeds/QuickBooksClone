// app_text_styles.dart
// app_text_styles.dart

import 'package:flutter/material.dart';

class AppTextStyles {
  AppTextStyles._();

  // Arabic font — add to pubspec: cairo
  static const _arabic = 'Cairo';

  static const displayLarge = TextStyle(
    fontFamily: _arabic,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.2,
  );

  static const headlineLarge = TextStyle(
    fontFamily: _arabic,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.3,
  );

  static const headlineMedium = TextStyle(
    fontFamily: _arabic,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  static const titleLarge = TextStyle(
    fontFamily: _arabic,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  static const titleMedium = TextStyle(
    fontFamily: _arabic,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  static const bodyLarge = TextStyle(
    fontFamily: _arabic,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.6,
  );

  static const bodyMedium = TextStyle(
    fontFamily: _arabic,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.6,
  );

  static const labelLarge = TextStyle(
    fontFamily: _arabic,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  static const labelSmall = TextStyle(
    fontFamily: _arabic,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: 0.5,
  );
}