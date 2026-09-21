import 'package:flutter/material.dart';

/// Monochrome Color Palette for Drop.
/// Implements pure black & white design system with subtle contrast greys.
class AppColors {
  AppColors._();

  // Pure Base Tones
  static const Color black = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);

  // Dark Theme Palette
  static const Color darkBackground = Color(0xFF000000);
  static const Color darkSurface = Color(0xFF121212);
  static const Color darkCard = Color(0xFF1A1A1A);
  static const Color darkBorder = Color(0xFF262626);
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFFA0A0A0);
  static const Color darkTextMuted = Color(0xFF666666);

  // Light Theme Palette
  static const Color lightBackground = Color(0xFFFFFFFF);
  static const Color lightSurface = Color(0xFFF7F7F7);
  static const Color lightCard = Color(0xFFEFEFEF);
  static const Color lightBorder = Color(0xFFE0E0E0);
  static const Color lightTextPrimary = Color(0xFF000000);
  static const Color lightTextSecondary = Color(0xFF555555);
  static const Color lightTextMuted = Color(0xFF999999);

  // Accent Tones (Monochrome focus with subtle overlay feedback)
  static const Color overlayDark = Color(0x99000000);
  static const Color overlayLight = Color(0x33FFFFFF);
  static const Color heartRed = Color(0xFFFF3040); // Minimal accent for like heart
  static const Color errorRed = Color(0xFFE53935);
  static const Color successGreen = Color(0xFF4CAF50);
}
