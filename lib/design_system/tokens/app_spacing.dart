/// Spacing, sizing, and border radius tokens for DQ Staff.
///
/// All values are const doubles — never use magic numbers in widgets.
abstract class AppSpacing {
  // ── Spacing scale ─────────────────────────────────────────
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double huge = 40;

  // ── Page insets ───────────────────────────────────────────
  static const double pageHorizontal = 16;
  static const double pageVertical = 16;

  // ── Section gap ───────────────────────────────────────────
  static const double sectionGap = 24;
  static const double itemGap = 12;
}

/// Border radius tokens.
abstract class AppRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 14;
  static const double xl = 16;
  static const double xxl = 20;
  static const double xxxl = 24;
  static const double full = 999;
}

/// Component sizing tokens.
abstract class AppSizes {
  // ── Icon sizes ────────────────────────────────────────────
  static const double iconSm = 18;
  static const double iconMd = 24;
  static const double iconLg = 32;
  static const double iconXl = 44;

  // ── Avatar / thumbnail ────────────────────────────────────
  static const double avatarSm = 32;
  static const double avatarMd = 44;
  static const double avatarLg = 56;

  // ── Touch targets ─────────────────────────────────────────
  static const double touchTarget = 48;

  // ── Button heights ────────────────────────────────────────
  static const double buttonSm = 40;
  static const double buttonMd = 48;
  static const double buttonLg = 52;

  // ── App bar ───────────────────────────────────────────────
  static const double appBarHeight = 56;

  // ── Bottom nav ────────────────────────────────────────────
  static const double bottomNavHeight = 58;

  // ── Scanner overlay ───────────────────────────────────────
  static const double scanBoxSize = 270;

  // ── Blur intensities ──────────────────────────────────────
  static const double blurLight = 6;
  static const double blurMd = 10;
  static const double blurHeavy = 20;
  static const double blurXHeavy = 40;
}
