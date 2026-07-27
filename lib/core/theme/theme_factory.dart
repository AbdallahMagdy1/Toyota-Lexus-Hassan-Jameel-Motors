import 'package:flutter/material.dart';

import 'app_brand.dart';

/// Builds the app-wide ThemeData from an [AppBrand] + brightness — the
/// mobile equivalent of globals.css mapping --color-brand-* per mode.
abstract final class ThemeFactory {
  static ThemeData build(AppBrand brand, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final brandColor = brand.colorFor(brightness);
    final onBrand = brand.foregroundFor(brightness);
    final scale = brand.scaleFor(brightness);

    // Reference-kit tokens: airy cool wash behind pure-white surfaces in
    // light mode (elevation via soft shadows, not hairline borders); dark
    // mode keeps subtle borders since shadows read poorly on near-black.
    final background = isDark ? const Color(0xFF0A0B0D) : const Color(0xFFF2F5FA);
    final surface = isDark ? const Color(0xFF14161B) : Colors.white;
    final onSurface = isDark ? const Color(0xFFF2F3F5) : const Color(0xFF13161B);
    final muted = isDark ? const Color(0xFF8B8F98) : const Color(0xFF6C7280);
    final border = isDark ? const Color(0xFF23252B) : const Color(0xFFE8ECF2);

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: brandColor,
      onPrimary: onBrand,
      secondary: scale[isDark ? 400 : 600] ?? brandColor,
      onSecondary: onBrand,
      error: const Color(0xFFE5484D),
      onError: Colors.white,
      surface: surface,
      onSurface: onSurface,
      surfaceContainerHighest: isDark ? const Color(0xFF1A1C21) : const Color(0xFFF0F1F3),
      outline: border,
      outlineVariant: border,
    );

    final radius = BorderRadius.circular(14);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.standard,
      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      }),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: onSurface,
        elevation: 0,
        centerTitle: true,
      ),
      textTheme: Typography.material2021(platform: TargetPlatform.iOS)
          .englishLike
          .apply(bodyColor: onSurface, displayColor: onSurface),
      // NOTE: minimumSize must have a BOUNDED width here. Size.fromHeight
      // sets minWidth = ∞, which explodes ("BoxConstraints forces an
      // infinite width") for any themed button placed in a Row/unbounded
      // context. Full-width buttons opt in per-call via Size.fromHeight or
      // a stretched Column — never via the global theme.
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: brandColor,
          foregroundColor: onBrand,
          minimumSize: const Size(64, 50),
          shape: RoundedRectangleBorder(borderRadius: radius),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: onSurface,
          minimumSize: const Size(64, 50),
          side: BorderSide(color: border),
          shape: RoundedRectangleBorder(borderRadius: radius),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: scale[isDark ? 300 : 600] ?? brandColor),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF16181D) : const Color(0xFFF2F3F5),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(borderRadius: radius, borderSide: BorderSide(color: border)),
        enabledBorder: OutlineInputBorder(borderRadius: radius, borderSide: BorderSide(color: border)),
        focusedBorder: OutlineInputBorder(borderRadius: radius, borderSide: BorderSide(color: brandColor, width: 1.6)),
        errorBorder: OutlineInputBorder(borderRadius: radius, borderSide: const BorderSide(color: Color(0xFFE5484D))),
        focusedErrorBorder: OutlineInputBorder(borderRadius: radius, borderSide: const BorderSide(color: Color(0xFFE5484D), width: 1.6)),
        hintStyle: TextStyle(color: muted, fontSize: 15),
        labelStyle: TextStyle(color: muted),
      ),
      dividerTheme: DividerThemeData(color: border, thickness: 1),
      // Reference-kit chips: stadium pills, no outline — selected fills with
      // the brand color, unselected sits on the surface. Applies app-wide
      // (ChoiceChip/FilterChip) without touching call sites.
      chipTheme: ChipThemeData(
        shape: const StadiumBorder(),
        side: BorderSide.none,
        backgroundColor: isDark ? const Color(0xFF1C1F26) : Colors.white,
        selectedColor: brandColor,
        labelStyle: TextStyle(
          color: onSurface,
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
        ),
        secondaryLabelStyle: TextStyle(
          color: onBrand,
          fontSize: 12.5,
          fontWeight: FontWeight.w800,
        ),
        checkmarkColor: onBrand,
        elevation: isDark ? 0 : 1.5,
        pressElevation: 0,
        shadowColor: Colors.black.withValues(alpha: 0.10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? const Color(0xFF1F2127) : const Color(0xFF1C1D21),
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
