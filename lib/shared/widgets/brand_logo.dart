import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/settings/bloc/theme_cubit.dart';

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
