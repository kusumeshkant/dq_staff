import 'package:flutter/material.dart';

// ── Breakpoints ────────────────────────────────────────────────────────────────
// 600 → tablet  |  900 → large tablet / desktop
// Matches the three-tier system used across the DQ platform.

extension DqStaffResponsive on BuildContext {
  double get screenWidth => MediaQuery.sizeOf(this).width;
  double get screenHeight => MediaQuery.sizeOf(this).height;

  bool get isMobile => screenWidth < 600;
  bool get isTablet => screenWidth >= 600 && screenWidth < 900;
  bool get isLargeScreen => screenWidth >= 900;
  bool get isTabletOrLarger => screenWidth >= 600;

  // ── Type-safe responsive value ─────────────────────────────────────────────
  T responsive<T>(T mobile, {T? tablet, T? large}) {
    if (screenWidth >= 900) return large ?? tablet ?? mobile;
    if (screenWidth >= 600) return tablet ?? mobile;
    return mobile;
  }

  // ── Layout helpers ─────────────────────────────────────────────────────────

  /// Horizontal padding for page-level content.
  double get pagePadding => responsive(16.0, tablet: 24.0, large: 32.0);

  /// Maximum content width — centers long-form content on wide screens.
  double get maxContentWidth =>
      responsive(double.infinity, tablet: 760.0, large: 960.0);

  /// Whether to show NavigationRail instead of BottomNavigationBar.
  bool get useNavigationRail => isTabletOrLarger;
}
