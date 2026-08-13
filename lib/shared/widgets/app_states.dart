import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/utils/responsive.dart';

/// Shared Loading / Empty / Error building blocks — one visual language for
/// every screen state instead of ad-hoc spinners and icon+text columns.

/* ------------------------------ Shimmer ------------------------------ */

/// Sweeping-highlight shimmer over any skeleton subtree. One repeating
/// controller per instance; skeletons are plain boxes so the whole thing
/// stays cheap (transform+opacity only, no relayout per frame).
final class Shimmer extends StatefulWidget {
  const Shimmer({super.key, required this.child});

  final Widget child;

  @override
  State<Shimmer> createState() => _ShimmerState();
}

/// Marker so nested [Shimmer]s become passthrough — composite skeletons
/// (rail/list/grid) self-wrap, and screens may wrap several of them in one
/// outer sweep without doubling the effect.
final class _ShimmerScope extends InheritedWidget {
  const _ShimmerScope({required super.child});

  @override
  bool updateShouldNotify(_ShimmerScope oldWidget) => false;
}

final class _ShimmerState extends State<Shimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Already inside a sweeping Shimmer — render plain.
    if (context.dependOnInheritedWidgetOfExactType<_ShimmerScope>() != null) {
      return widget.child;
    }
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final highlight = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.white.withValues(alpha: 0.85);
    return AnimatedBuilder(
      animation: _controller,
      child: _ShimmerScope(child: widget.child),
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            // The highlight band sweeps from before the start edge to past
            // the end edge, following the reading direction.
            final rtl = Directionality.of(context) == TextDirection.rtl;
            final t = _controller.value;
            final dx = (rtl ? 1 - t : t) * 2 - 1;
            return LinearGradient(
              begin: Alignment(-1 + dx * 2, -0.3),
              end: Alignment(1 + dx * 2, 0.3),
              colors: [
                Colors.transparent,
                highlight,
                Colors.transparent,
              ],
              stops: const [0.35, 0.5, 0.65],
            ).createShader(bounds);
          },
          child: child,
        );
      },
    );
  }
}

/// Base skeleton tile — a rounded surface-tinted box.
final class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    this.width,
    this.height,
    this.radius = 12,
    this.circle = false,
  });

  final double? width;
  final double? height;
  final double radius;
  final bool circle;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1F26) : const Color(0xFFE4E8EF),
        shape: circle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: circle ? null : BorderRadius.circular(radius),
      ),
    );
  }
}

/// A text-line placeholder ([widthFactor] of the available width).
final class SkeletonLine extends StatelessWidget {
  const SkeletonLine({super.key, this.widthFactor = 1, this.height = 12});

  final double widthFactor;
  final double height;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      alignment: AlignmentDirectional.centerStart,
      child: SkeletonBox(height: height, radius: height / 2),
    );
  }
}

/// Horizontal rail of card skeletons — mirrors [CardRail] geometry so the
/// layout doesn't jump when real cards arrive.
final class SkeletonRail extends StatelessWidget {
  const SkeletonRail({
    super.key,
    required this.height,
    required this.itemWidth,
    this.itemCount = 3,
  });

  final double height;
  final double itemWidth;
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: SizedBox(
        height: height,
        child: ListView.separated(
          padding: EdgeInsets.symmetric(horizontal: context.rs(20)),
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: itemCount,
          separatorBuilder: (_, _) => SizedBox(width: context.rs(12)),
          itemBuilder: (_, _) => _CardSkeleton(width: itemWidth),
        ),
      ),
    );
  }
}

final class _CardSkeleton extends StatelessWidget {
  const _CardSkeleton({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: SkeletonBox(width: width, radius: 16)),
          SizedBox(height: context.rs(10)),
          const SkeletonLine(widthFactor: 0.7, height: 13),
          SizedBox(height: context.rs(8)),
          const SkeletonLine(widthFactor: 0.45, height: 11),
        ],
      ),
    );
  }
}

/// Vertical list of row skeletons (avatar-ish block + two lines) — for
/// list-style screens (news, requests, tracking, notifications).
final class SkeletonList extends StatelessWidget {
  const SkeletonList({
    super.key,
    this.itemCount = 5,
    this.itemHeight = 84,
    this.padding,
  });

  final int itemCount;
  final double itemHeight;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: ListView.separated(
        padding: padding ??
            EdgeInsets.symmetric(
                horizontal: context.rs(20), vertical: context.rs(16)),
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: itemCount,
        separatorBuilder: (_, _) => SizedBox(height: context.rs(12)),
        itemBuilder: (_, _) => SizedBox(
          height: itemHeight,
          child: Row(
            children: [
              SkeletonBox(
                  width: itemHeight, height: itemHeight, radius: 14),
              SizedBox(width: context.rs(14)),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SkeletonLine(widthFactor: 0.8, height: 13),
                    SizedBox(height: context.rs(10)),
                    const SkeletonLine(widthFactor: 0.5, height: 11),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Full-page grid skeleton (2-up product grids: store, parts, models).
final class SkeletonGrid extends StatelessWidget {
  const SkeletonGrid({
    super.key,
    this.itemCount = 6,
    this.aspectRatio = 0.78,
    this.crossAxisCount = 2,
  });

  final int itemCount;
  final double aspectRatio;
  final int crossAxisCount;

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: GridView.builder(
        padding: EdgeInsets.symmetric(
            horizontal: context.rs(20), vertical: context.rs(16)),
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: context.rs(14),
          crossAxisSpacing: context.rs(14),
          childAspectRatio: aspectRatio,
        ),
        itemCount: itemCount,
        itemBuilder: (_, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(child: SkeletonBox(width: double.infinity, radius: 16)),
            SizedBox(height: context.rs(10)),
            const SkeletonLine(widthFactor: 0.75, height: 12),
            SizedBox(height: context.rs(7)),
            const SkeletonLine(widthFactor: 0.4, height: 10),
          ],
        ),
      ),
    );
  }
}

/* ---------------------------- Empty state ---------------------------- */

/// Polished empty state: soft brand-tinted icon disc, title, optional
/// description and action — replaces bare "no data" text everywhere.
final class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.compact = false,
  });

  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// Compact = inline section variant (smaller paddings, no min height).
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: context.rs(compact ? 58 : 76),
          height: context.rs(compact ? 58 : 76),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: scheme.primary.withValues(alpha: 0.10),
          ),
          child: Icon(icon,
              size: context.rs(compact ? 26 : 34), color: scheme.primary),
        ),
        SizedBox(height: context.rs(compact ? 12 : 18)),
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: context.rf(compact ? 14.5 : 16.5),
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
        ),
        if (message != null) ...[
          SizedBox(height: context.rs(6)),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: context.rs(28)),
            child: Text(
              message!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: context.rf(12.5),
                height: 1.45,
                color: scheme.onSurface.withValues(alpha: 0.55),
              ),
            ),
          ),
        ],
        if (actionLabel != null && onAction != null) ...[
          SizedBox(height: context.rs(16)),
          FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: Size(context.rs(140), context.rs(44)),
              textStyle: TextStyle(
                  fontSize: context.rf(13), fontWeight: FontWeight.w700),
            ),
            onPressed: onAction,
            child: Text(actionLabel!),
          ),
        ],
      ],
    )
        .animate()
        .fadeIn(duration: 280.ms)
        .slideY(begin: 0.04, end: 0, curve: Curves.easeOutCubic);

    if (compact) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: context.rs(24)),
        child: Center(child: content),
      );
    }
    return Center(
      child: Padding(
        padding: EdgeInsets.all(context.rs(24)),
        child: content,
      ),
    );
  }
}

/* ---------------------------- Error state ---------------------------- */

/// Polished error state with a clear retry path — replaces the bare
/// icon+text tap targets.
final class AppErrorState extends StatelessWidget {
  const AppErrorState({
    super.key,
    required this.title,
    this.message,
    this.retryLabel,
    this.onRetry,
    this.compact = false,
  });

  final String title;
  final String? message;
  final String? retryLabel;
  final VoidCallback? onRetry;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: context.rs(compact ? 58 : 76),
          height: context.rs(compact ? 58 : 76),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: scheme.error.withValues(alpha: 0.10),
          ),
          child: Icon(Icons.wifi_off_rounded,
              size: context.rs(compact ? 26 : 34), color: scheme.error),
        ),
        SizedBox(height: context.rs(compact ? 12 : 18)),
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: context.rf(compact ? 14.5 : 16.5),
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
        ),
        if (message != null) ...[
          SizedBox(height: context.rs(6)),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: context.rs(28)),
            child: Text(
              message!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: context.rf(12.5),
                height: 1.45,
                color: scheme.onSurface.withValues(alpha: 0.55),
              ),
            ),
          ),
        ],
        if (onRetry != null) ...[
          SizedBox(height: context.rs(16)),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              minimumSize: Size(context.rs(140), context.rs(44)),
              textStyle: TextStyle(
                  fontSize: context.rf(13), fontWeight: FontWeight.w700),
            ),
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: Text(retryLabel ?? title),
          ),
        ],
      ],
    )
        .animate()
        .fadeIn(duration: 280.ms)
        .slideY(begin: 0.04, end: 0, curve: Curves.easeOutCubic);

    if (compact) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: context.rs(24)),
        child: Center(child: content),
      );
    }
    return Center(
      child: Padding(padding: EdgeInsets.all(context.rs(24)), child: content),
    );
  }
}
