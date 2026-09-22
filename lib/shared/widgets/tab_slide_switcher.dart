import 'package:flutter/material.dart';

/// Animates tab-content changes with a directional push: the incoming page
/// slides in from the side you're heading toward while the outgoing page
/// slides out the other way, both under a fade — the Material "shared axis"
/// feel. RTL-aware: "forward" (a higher tab index) always enters from the
/// side the next chip sits on.
final class TabSlideSwitcher extends StatefulWidget {
  const TabSlideSwitcher({
    super.key,
    required this.index,
    required this.child,
  });

  /// The selected tab index — a change animates toward the new page.
  final int index;
  final Widget child;

  @override
  State<TabSlideSwitcher> createState() => _TabSlideSwitcherState();
}

final class _TabSlideSwitcherState extends State<TabSlideSwitcher> {
  bool _forward = true;

  @override
  void didUpdateWidget(TabSlideSwitcher old) {
    super.didUpdateWidget(old);
    if (old.index != widget.index) _forward = widget.index > old.index;
  }

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    // Reading-direction sign: forward enters from the end side (right in
    // LTR, left in RTL), backward from the start side.
    final dir = (_forward ? 1.0 : -1.0) * (isRtl ? -1.0 : 1.0);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        // The incoming child carries the CURRENT index key; the outgoing one
        // (its animation running in reverse) gets the mirrored offset so the
        // two pages travel the same way — a push, not a cross.
        final incoming = child.key == ValueKey<int>(widget.index);
        final begin = Offset((incoming ? 0.10 : -0.10) * dir, 0);
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(begin: begin, end: Offset.zero)
                .animate(animation),
            child: child,
          ),
        );
      },
      child: KeyedSubtree(
        key: ValueKey<int>(widget.index),
        child: widget.child,
      ),
    );
  }
}
