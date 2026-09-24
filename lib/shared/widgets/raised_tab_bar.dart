import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/utils/responsive.dart';

/// The reference "model year" tab strip: inactive tabs are plain muted
/// labels sitting on the baseline; the ACTIVE tab is a raised brand-colored
/// rounded card that floats slightly above the row (pure transform — the
/// app is flat, no shadows). An optional tiny caption renders inside the
/// active card above its label (like the reference's "MODEL / 2019").
final class RaisedTabBar extends StatelessWidget {
  const RaisedTabBar({
    super.key,
    required this.tabs,
    required this.index,
    required this.onChanged,
    this.caption,
    this.scrollable = false,
  });

  final List<String> tabs;
  final int index;
  final ValueChanged<int> onChanged;

  /// Tiny uppercase word inside the active card, above the label.
  final String? caption;

  /// Scrollable row for variable tab counts; false = equal-width fit.
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    Widget item(int i, {bool expanded = false}) {
      final selected = i == index;
      final label = AnimatedDefaultTextStyle(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        maxLines: 1,
        style: TextStyle(
          fontSize: context.rf(selected ? 12.5 : 11.5),
          fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
          letterSpacing: 0.2,
          color: selected
              ? scheme.onPrimary
              : scheme.onSurface.withValues(alpha: 0.45),
        ),
        child: Text(tabs[i], overflow: TextOverflow.ellipsis),
      );

      final card = AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: context.rs(expanded ? 6 : 16),
          vertical: context.rs(selected ? 8 : 6),
        ),
        decoration: BoxDecoration(
          color: selected ? scheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(13),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected && (caption ?? '').isNotEmpty) ...[
              Text(
                caption!.toUpperCase(),
                maxLines: 1,
                style: TextStyle(
                  fontSize: context.rf(7.5),
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.6,
                  color: scheme.onPrimary.withValues(alpha: 0.75),
                ),
              ),
              SizedBox(height: context.rs(1)),
            ],
            FittedBox(fit: BoxFit.scaleDown, child: label),
          ],
        ),
      );

      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (i == index) return;
          HapticFeedback.selectionClick();
          onChanged(i);
        },
        child: AnimatedSlide(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          offset: Offset(0, selected ? -0.10 : 0),
          child: Center(child: card),
        ),
      );
    }

    final height = context.rs((caption ?? '').isEmpty ? 46 : 54);
    if (scrollable) {
      return SizedBox(
        height: height,
        child: ListView.separated(
          padding: EdgeInsets.symmetric(horizontal: context.rs(20)),
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          itemCount: tabs.length,
          separatorBuilder: (_, _) => SizedBox(width: context.rs(6)),
          itemBuilder: (context, i) => item(i),
        ),
      );
    }
    return SizedBox(
      height: height,
      child: Row(
        children: [
          for (var i = 0; i < tabs.length; i++)
            Expanded(child: item(i, expanded: true)),
        ],
      ),
    );
  }
}
