import 'package:flutter/material.dart';

import '../../../../core/utils/media_url.dart';
import '../../../../core/utils/responsive.dart';

/// Shared building blocks for the home sections.

/// Fading network image with a neutral placeholder — every card uses this.
/// URLs are sanitized (ERP file names carry raw Arabic/control chars) and
/// decoded at display size ([logicalWidth] × devicePixelRatio) so 4MB CDN
/// artwork doesn't blow up memory or jank the rails.
final class HomeImage extends StatelessWidget {
  const HomeImage({
    super.key,
    this.url,
    this.fit = BoxFit.cover,
    this.aspectRatio,
    this.logicalWidth,
    this.alignment = Alignment.center,
  });

  final String? url;
  final BoxFit fit;
  final double? aspectRatio;
  final Alignment alignment;

  /// Approximate on-screen width used to pick the decode resolution.
  final double? logicalWidth;

  @override
  Widget build(BuildContext context) {
    final placeholder = ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Icon(
        Icons.directions_car_outlined,
        size: 34,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.15),
      ),
    );
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final targetWidth =
        logicalWidth == null ? null : (logicalWidth! * dpr).round();
    // Server-side optimize (fixes broken CDN files + resizes); the proxy
    // already delivers the right size, so no client-side cacheWidth needed.
    final optimized = optimizedImageUrl(url, width: targetWidth);
    final image = optimized == null
        ? placeholder
        : Image.network(
            optimized,
            fit: fit,
            alignment: alignment,
            gaplessPlayback: true,
            filterQuality: FilterQuality.medium,
            errorBuilder: (_, _, _) => placeholder,
            frameBuilder: (context, child, frame, sync) => sync
                ? child
                : AnimatedOpacity(
                    opacity: frame == null ? 0 : 1,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                    child: child,
                  ),
          );
    return aspectRatio == null ? image : AspectRatio(aspectRatio: aspectRatio!, child: image);
  }
}

/// "Section title + subtitle + View all" row, like the website headers.
final class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(context.rs(20), context.rs(26), context.rs(20), context.rs(12)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: context.rf(20),
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: context.rf(12.5),
                      color: scheme.onSurface.withValues(alpha: 0.55),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (actionLabel != null)
            // Reference style: "See All ›" in brand color with a chevron.
            GestureDetector(
              onTap: onAction,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: context.rs(4)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(
                    actionLabel!,
                    style: TextStyle(
                      fontSize: context.rf(12),
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                      color: scheme.primary,
                    ),
                  ),
                  SizedBox(width: context.rs(2)),
                  Icon(
                    Directionality.of(context) == TextDirection.rtl
                        ? Icons.chevron_left_rounded
                        : Icons.chevron_right_rounded,
                    size: 16,
                    color: scheme.primary,
                  ),
                ]),
              ),
            ),
        ],
      ),
    );
  }
}

/// Horizontal filter chips (vehicle categories, parts categories).
final class FilterChipsRow extends StatelessWidget {
  const FilterChipsRow({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onSelected,
  });

  /// Index 0 is the "All" chip.
  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: context.rs(38),
      child: ListView.separated(
        padding: EdgeInsets.symmetric(horizontal: context.rs(20)),
        scrollDirection: Axis.horizontal,
        itemCount: labels.length,
        separatorBuilder: (_, _) => SizedBox(width: context.rs(8)),
        itemBuilder: (context, i) {
          final selected = i == selectedIndex;
          final isDark = Theme.of(context).brightness == Brightness.dark;
          // Reference-kit pills: selected = brand gradient with a colored
          // glow; unselected = floating surface pill (soft shadow, no
          // border in light mode).
          return GestureDetector(
            onTap: () => onSelected(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              padding: EdgeInsets.symmetric(horizontal: context.rs(18)),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: selected
                    ? LinearGradient(colors: [
                        scheme.primary,
                        scheme.primary.withValues(alpha: 0.78),
                      ])
                    : null,
                color: selected
                    ? null
                    : (isDark ? const Color(0xFF1C1F26) : scheme.surface),
                borderRadius: BorderRadius.circular(999),
                border: !selected
                    ? Border.all(
                        color: scheme.outline
                            .withValues(alpha: isDark ? 0.6 : 0.5))
                    : null,
              ),
              child: Text(
                labels[i],
                style: TextStyle(
                  fontSize: context.rf(12.5),
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  color: selected
                      ? scheme.onPrimary
                      : scheme.onSurface.withValues(alpha: 0.75),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Horizontal card rail — fixed-extent, lazily built, cheap to scroll.
final class CardRail extends StatelessWidget {
  const CardRail({
    super.key,
    required this.height,
    required this.itemCount,
    required this.itemBuilder,
    this.itemWidth,
  });

  final double height;
  final int itemCount;
  final double? itemWidth;
  final IndexedWidgetBuilder itemBuilder;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ListView.separated(
        padding: EdgeInsets.symmetric(horizontal: context.rs(20)),
        scrollDirection: Axis.horizontal,
        itemCount: itemCount,
        cacheExtent: 600,
        separatorBuilder: (_, _) => SizedBox(width: context.rs(12)),
        itemBuilder: (context, i) => RepaintBoundary(
          child: itemWidth == null
              ? itemBuilder(context, i)
              : SizedBox(width: itemWidth, child: itemBuilder(context, i)),
        ),
      ),
    );
  }
}

/// Flat design (user request): no drop shadows anywhere — separation comes
/// from surface color + hairline borders instead. Kept as the single switch
/// so every card updates together.
List<BoxShadow> kSoftShadows(BuildContext context, {double opacity = 1}) {
  return const [];
}

/// The reference kit's soft surface decoration: white floating card in
/// light mode (no border), elevated bordered surface in dark. Optional
/// [tint] lays a subtle brand gradient wash over the surface.
BoxDecoration softCardDecoration(
  BuildContext context, {
  double radius = 20,
  Color? tint,
}) {
  final scheme = Theme.of(context).colorScheme;
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return BoxDecoration(
    color: isDark ? const Color(0xFF181B21) : scheme.surface,
    gradient: tint == null
        ? null
        : LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [tint.withValues(alpha: 0.16), const Color(0xFF15171C)]
                : [tint.withValues(alpha: 0.10), Colors.white],
          ),
    borderRadius: BorderRadius.circular(radius),
    // Hairline border in BOTH modes now that shadows are gone — it is the
    // only separation light surfaces have left.
    border: Border.all(
      color: scheme.outline.withValues(alpha: isDark ? 0.5 : 0.45),
    ),
  );
}

/// The shared card chrome — flat style: surface + hairline border in both
/// modes (no drop shadows anywhere, per design direction).
final class HomeCard extends StatelessWidget {
  const HomeCard({super.key, required this.child, this.onTap, this.padding});

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark ? const Color(0xFF181B21) : scheme.surface,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: scheme.outline.withValues(alpha: isDark ? 0.5 : 0.45),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// The Saudi Riyal symbol from the website's icomoon font (U+E900) — the
/// exact glyph the website CurrencyCode component renders before prices.
const String kRiyalGlyph = '\uE900';

TextSpan riyalSpan({required double fontSize, Color? color}) => TextSpan(
      text: '$kRiyalGlyph ',
      style: TextStyle(
        fontFamily: 'icomoon',
        fontStyle: FontStyle.normal,
        fontSize: fontSize * 0.82,
        color: color,
        height: 1,
      ),
    );

String formatPrice(double v) => v
    .toStringAsFixed(v % 1 == 0 ? 0 : 2)
    .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',');

/// "⃀ 128,280" price text (riyal glyph + number) with graceful fallback.
final class PriceText extends StatelessWidget {
  const PriceText({
    super.key,
    required this.price,
    required this.currency,
    required this.contactForPrice,
    this.fontSize,
    this.color,
  });

  final double? price;
  final String currency; // kept for call-site compatibility; glyph is used
  final String contactForPrice;
  final double? fontSize;

  /// Overrides both glyph and number color (else primary + onSurface).
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (price == null || price! <= 0) {
      return Text(
        contactForPrice,
        style: TextStyle(
          fontSize: (fontSize ?? 14) - 1,
          fontWeight: FontWeight.w700,
          color: color ?? scheme.onSurface.withValues(alpha: 0.6),
        ),
      );
    }
    final size = fontSize ?? 14;
    return Text.rich(
      TextSpan(children: [
        riyalSpan(fontSize: size, color: color ?? scheme.primary),
        TextSpan(
          text: formatPrice(price!),
          style: TextStyle(
            fontSize: size,
            fontWeight: FontWeight.w800,
            fontStyle: FontStyle.italic,
            color: color,
          ),
        ),
      ]),
      textDirection: TextDirection.ltr,
    );
  }
}
