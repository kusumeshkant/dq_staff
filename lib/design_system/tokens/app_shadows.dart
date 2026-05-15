import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Shadow and elevation tokens for DQ Staff.
///
/// All values are const — never define BoxShadow inline in widgets.
abstract class AppShadows {
  // ── Card shadow ───────────────────────────────────────────
  static const List<BoxShadow> card = [
    BoxShadow(
      color: AppColors.glassBlack30,
      blurRadius: 20,
      offset: Offset(0, 8),
    ),
  ];

  static const List<BoxShadow> cardSubtle = [
    BoxShadow(
      color: AppColors.glassBlack10,
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ];

  // ── Modal / bottom sheet shadow ───────────────────────────
  static const List<BoxShadow> modal = [
    BoxShadow(
      color: AppColors.glassBlack30,
      blurRadius: 40,
      offset: Offset(0, -8),
    ),
  ];

  // ── Button shadow ─────────────────────────────────────────
  static const List<BoxShadow> button = [
    BoxShadow(
      color: Color(0x4D1565C0), // primary at 30%
      blurRadius: 18,
      offset: Offset(0, 6),
    ),
  ];

  // ── Bottom nav shadow ─────────────────────────────────────
  static const List<BoxShadow> bottomNav = [
    BoxShadow(
      color: AppColors.glassBlack30,
      blurRadius: 12,
      offset: Offset(0, -3),
    ),
  ];
}

/// Blur (backdrop filter) sigma values.
abstract class AppBlur {
  static const double light = 6;
  static const double medium = 10;
  static const double heavy = 20;
  static const double xHeavy = 40;
}
