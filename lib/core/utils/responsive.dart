import 'package:flutter/widgets.dart';

/// Width-based responsive scaling. Design reference width = 390 (iPhone 13).
/// Small phones (Oppo F11 class, ~360dp) scale down; tablets are capped so
/// content never balloons — wide layouts should also constrain with
/// [maxContentWidth].
extension Responsive on BuildContext {
  double get screenWidth => MediaQuery.sizeOf(this).width;

  bool get isTablet => screenWidth >= 600;

  /// Scale factor clamped to keep proportions sane on both extremes.
  double get uiScale => (screenWidth / 390).clamp(0.82, 1.08);

  /// Responsive size (spacing, radii, icon sizes).
  double rs(double v) => v * uiScale;

  /// Responsive font size — slightly gentler curve than rs.
  double rf(double v) => v * ((screenWidth / 390).clamp(0.86, 1.05));

  /// Content column cap: phones fill the width, tablets center a column.
  double get maxContentWidth => isTablet ? 480 : double.infinity;

  /// Horizontal page padding that breathes on bigger screens.
  EdgeInsets get pagePadding =>
      EdgeInsets.symmetric(horizontal: rs(24), vertical: rs(16));
}
