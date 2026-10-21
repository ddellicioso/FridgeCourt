import 'package:flutter/material.dart';

/// "Snack Pastel" palette — validated against WCAG 2.1 AA contrast
/// (see /docs notes from the design phase for the before/after fixes).
class AppColors {
  AppColors._();

  static const surface = Color(0xFFFFF8F3);
  static const textPrimary = Color(0xFF5B4B43);
  static const textSecondary = Color(0xFF6B5C4F);

  // Guilty / high-alert accent (status pill background).
  static const guilty = Color(0xFFC23B3F);

  // "The fridge says..." quote accent.
  static const quoteAccent = Color(0xFFA14A38);

  // Not-guilty action button.
  static const notGuiltyBg = Color(0xFFA8D8B9);
  static const notGuiltyText = Color(0xFF2F4A38);

  // Guilty action button.
  static const guiltyBg = Color(0xFFFFB4A2);
  static const guiltyText = Color(0xFF7A2E1F);

  // Neutral card / surface tones used across screens.
  static const card = Color(0xFFFFFFFF);
  static const cardBorder = Color(0xFFF0E4DA);
  static const pending = Color(0xFFE9C46A);
  static const pendingText = Color(0xFF5B4B43);
}
