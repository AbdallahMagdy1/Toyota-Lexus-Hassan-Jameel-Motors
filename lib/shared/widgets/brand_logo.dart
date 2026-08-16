import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/settings/bloc/theme_cubit.dart';

/// The active brand's bare EMBLEM — the Toyota ovals / Lexus "L", no
/// wordmark. The assets are solid silhouettes on transparency, so [color]
/// recolors the whole mark; leave it null to keep the brand's own colour.
/// Used where an icon slot should carry the brand instead of a Material
/// glyph (bottom nav, the onboarding swipe thumb) and, at a low [opacity],
/// as a card watermark.
final class BrandMark extends StatelessWidget {
  const BrandMark({
    super.key,
    required this.size,
    this.color,
    this.opacity = 1,
  });

  final double size;
  final Color? color;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final asset = context.select((ThemeCubit c) => c.state.brand.mark);
    if (asset == null || asset.isEmpty) {
      // Never leave a hole in a nav bar if a custom dashboard brand has no
      // emblem bundled — fall back to a neutral glyph.
      return Icon(Icons.directions_car_rounded, size: size, color: color);
    }
    final image = Image.asset(
      asset,
      width: size,
      height: size,
      fit: BoxFit.contain,
      color: color,
      // Excluded from semantics: it is decoration next to a real label.
      excludeFromSemantics: true,
    );
    return opacity >= 1 ? image : Opacity(opacity: opacity, child: image);
  }
}

/// The active brand's logo (Toyota / Lexus), correct variant per brightness.
final class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.height = 36, this.forceDark = false});

  final double height;

  /// Auth/onboarding render on a dark backdrop regardless of theme mode.
  final bool forceDark;

  @override
  Widget build(BuildContext context) {
    final brand = context.select((ThemeCubit c) => c.state.brand);
    final brightness =
        forceDark ? Brightness.dark : Theme.of(context).brightness;
    final asset = brand.logoFor(brightness);
    if (asset.isEmpty) return SizedBox(height: height);
    return Image.asset(asset, height: height, fit: BoxFit.contain);
  }
}
