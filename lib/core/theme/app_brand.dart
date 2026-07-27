import 'dart:ui';

import 'package:equatable/equatable.dart';

Color _hex(String hex) {
  var h = hex.replaceFirst('#', '');
  if (h.length == 6) h = 'ff$h';
  return Color(int.parse(h, radix: 16));
}

Color? _hexOrNull(String? hex) {
  if (hex == null || hex.isEmpty) return null;
  if (hex.startsWith('rgba')) {
    // "rgba(235,10,30,0.12)" — the API's BrandSoft format.
    final m = RegExp(r'rgba?\(([\d.]+),\s*([\d.]+),\s*([\d.]+)(?:,\s*([\d.]+))?\)')
        .firstMatch(hex);
    if (m == null) return null;
    return Color.from(
      alpha: double.tryParse(m.group(4) ?? '1') ?? 1,
      red: (double.parse(m.group(1)!)) / 255,
      green: (double.parse(m.group(2)!)) / 255,
      blue: (double.parse(m.group(3)!)) / 255,
    );
  }
  try {
    return _hex(hex);
  } catch (_) {
    return null;
  }
}

/// One brand palette — the mobile mirror of the website's `BrandTheme`
/// (src/lib/brands.ts) + the dashboard's SiteThemes row.
final class AppBrand extends Equatable {
  const AppBrand({
    required this.key,
    required this.nameEn,
    required this.nameAr,
    required this.brandColor,
    required this.brandForeground,
    required this.scale,
    this.brandSoft,
    this.brandColorDark,
    this.brandForegroundDark,
    this.scaleDark,
    this.logoLight,
    this.logoDark,
  });

  final String key; // toyota | lexus | hj | custom keys from the dashboard
  final String nameEn;
  final String nameAr;
  final Color brandColor;
  final Color brandForeground;
  final Color? brandSoft;
  final Map<int, Color> scale; // 50..950
  final Color? brandColorDark;
  final Color? brandForegroundDark;
  final Map<int, Color>? scaleDark;
  final String? logoLight; // asset path for light backgrounds
  final String? logoDark; // asset path for dark backgrounds

  Color colorFor(Brightness b) =>
      b == Brightness.dark ? (brandColorDark ?? brandColor) : brandColor;

  Color foregroundFor(Brightness b) => b == Brightness.dark
      ? (brandForegroundDark ?? brandForeground)
      : brandForeground;

  Map<int, Color> scaleFor(Brightness b) =>
      b == Brightness.dark ? (scaleDark ?? scale) : scale;

  String logoFor(Brightness b) =>
      b == Brightness.dark ? (logoDark ?? logoLight ?? '') : (logoLight ?? '');

  /// Parse a theme row from GET /api/app/themes. System keys keep their
  /// bundled logos but take every color from the dashboard — exactly like
  /// the website's BrandProvider.buildBrandMap.
  factory AppBrand.fromApi(Map<String, dynamic> json) {
    final key = (json['key'] as String? ?? '').toLowerCase();
    final fallback = kFallbackBrands[key];
    return AppBrand(
      key: key,
      nameEn: json['nameEn'] as String? ?? fallback?.nameEn ?? key,
      nameAr: json['nameAr'] as String? ?? fallback?.nameAr ?? key,
      brandColor:
          _hexOrNull(json['brandColor'] as String?) ?? fallback?.brandColor ?? const Color(0xFF23CC4F),
      brandForeground: _hexOrNull(json['brandForeground'] as String?) ??
          fallback?.brandForeground ??
          const Color(0xFFFFFFFF),
      brandSoft: _hexOrNull(json['brandSoft'] as String?) ?? fallback?.brandSoft,
      scale: _parseScale(json['scale']) ?? fallback?.scale ?? const {},
      brandColorDark: _hexOrNull(json['brandColorDark'] as String?) ?? fallback?.brandColorDark,
      brandForegroundDark:
          _hexOrNull(json['brandForegroundDark'] as String?) ?? fallback?.brandForegroundDark,
      scaleDark: _parseScale(json['scaleDark']) ?? fallback?.scaleDark,
      logoLight: fallback?.logoLight,
      logoDark: fallback?.logoDark,
    );
  }

  static Map<int, Color>? _parseScale(dynamic node) {
    if (node is! Map) return null;
    final out = <int, Color>{};
    node.forEach((k, v) {
      final step = int.tryParse(k.toString());
      final color = v is String ? _hexOrNull(v) : null;
      if (step != null && color != null) out[step] = color;
    });
    return out.isEmpty ? null : out;
  }

  @override
  List<Object?> get props =>
      [key, brandColor, brandForeground, brandColorDark, scale, scaleDark];
}

/// Hardcoded fallbacks — byte-identical palettes to the website's
/// src/lib/brands.ts, used until /api/app/themes answers (and when offline).
final Map<String, AppBrand> kFallbackBrands = {
  'toyota': AppBrand(
    key: 'toyota',
    nameEn: 'Toyota',
    nameAr: 'تويوتا',
    brandColor: _hex('#EB0A1E'),
    brandForeground: _hex('#ffffff'),
    scale: {
      50: _hex('#fff1f2'),
      100: _hex('#ffe1e3'),
      200: _hex('#fecaca'),
      300: _hex('#fb9498'),
      400: _hex('#f75f66'),
      500: _hex('#EB0A1E'),
      600: _hex('#d40918'),
      700: _hex('#b00714'),
      800: _hex('#8c0610'),
      900: _hex('#73050d'),
      950: _hex('#450105'),
    },
    logoLight: 'assets/logos/toyota-logo-wide.png',
    logoDark: 'assets/logos/toyota-logo-wide.png',
  ),
  'lexus': AppBrand(
    key: 'lexus',
    nameEn: 'Lexus',
    nameAr: 'لكزس',
    brandColor: _hex('#111212'),
    brandForeground: _hex('#ffffff'),
    scale: {
      50: _hex('#f6f7f7'),
      100: _hex('#e2e4e4'),
      200: _hex('#c5c9c9'),
      300: _hex('#a1a7a7'),
      400: _hex('#7d8484'),
      500: _hex('#636a6a'),
      600: _hex('#4e5454'),
      700: _hex('#404545'),
      800: _hex('#363a3a'),
      900: _hex('#111212'),
      950: _hex('#0a0b0b'),
    },
    brandColorDark: _hex('#5e6562'),
    brandForegroundDark: _hex('#ffffff'),
    scaleDark: {
      50: _hex('#0a0b0b'),
      100: _hex('#111212'),
      200: _hex('#1c1e1e'),
      300: _hex('#2b2e2e'),
      400: _hex('#3d4241'),
      500: _hex('#5e6562'),
      600: _hex('#788079'),
      700: _hex('#9aa19b'),
      800: _hex('#bcc2bd'),
      900: _hex('#dde0de'),
      950: _hex('#f2f3f2'),
    },
    logoLight: 'assets/logos/lexus-Logo-wide.png',
    logoDark: 'assets/logos/lexus-Logo-wide-white.png',
  ),
  'hj': AppBrand(
    key: 'hj',
    nameEn: 'Hassan Jameel',
    nameAr: 'حسن جميل',
    brandColor: _hex('#23cc4f'),
    brandForeground: _hex('#ffffff'),
    scale: {
      50: _hex('#ecfdf2'),
      100: _hex('#d1fae0'),
      200: _hex('#a7f3c2'),
      300: _hex('#6ee7a0'),
      400: _hex('#34d976'),
      500: _hex('#23cc4f'),
      600: _hex('#1ba83f'),
      700: _hex('#178432'),
      800: _hex('#14682a'),
      900: _hex('#115524'),
      950: _hex('#052e10'),
    },
    logoLight: 'assets/logos/hj-logo.png',
    logoDark: 'assets/logos/hj-logo.png',
  ),
};
