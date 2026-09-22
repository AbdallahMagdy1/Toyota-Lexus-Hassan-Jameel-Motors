import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Horizontal fling-to-switch-tabs, RTL-aware.
///
/// "Next" always means the tab further along the reading direction — the
/// same order the chips row / bottom-nav items render in. So in Arabic
/// (RTL) flinging the finger to the RIGHT reveals the next tab (which sits
/// to the left), and in English the classic left-fling does.
///
/// The detector only claims HORIZONTAL drags, so vertical lists inside keep
/// scrolling normally, and any nested horizontal carousel still wins the
/// gesture arena within its own bounds (rails keep working).
final class TabSwipe extends StatelessWidget {
  const TabSwipe({
    super.key,
    required this.child,
    this.onNext,
    this.onPrev,
  });

  final Widget child;
  final VoidCallback? onNext;
  final VoidCallback? onPrev;

  static const double _minVelocity = 250;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragEnd: (d) {
        final v = d.primaryVelocity ?? 0;
        if (v.abs() < _minVelocity) return;
        final isRtl = Directionality.of(context) == TextDirection.rtl;
        final next = isRtl ? v > 0 : v < 0;
        final action = next ? onNext : onPrev;
        if (action != null) {
          HapticFeedback.selectionClick();
          action();
        }
      },
      child: child,
    );
  }
}
