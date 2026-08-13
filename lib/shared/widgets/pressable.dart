import 'package:flutter/material.dart';

/// Press-scale feedback for tappable cards: shrinks to [pressedScale] while
/// the finger is down and springs back on release — the HIG "scale feedback"
/// pattern. Purely visual: the actual tap keeps living on the child's own
/// InkWell/GestureDetector, so hit-testing, ripples and semantics are
/// untouched.
final class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    this.pressedScale = 0.97,
    this.enabled = true,
  });

  final Widget child;
  final double pressedScale;
  final bool enabled;

  @override
  State<Pressable> createState() => _PressableState();
}

final class _PressableState extends State<Pressable> {
  bool _down = false;

  void _set(bool v) {
    if (_down != v && mounted) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;
    return Listener(
      behavior: HitTestBehavior.deferToChild,
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: _down ? widget.pressedScale : 1,
        duration: Duration(milliseconds: _down ? 90 : 180),
        curve: _down ? Curves.easeOut : Curves.easeOutBack,
        child: widget.child,
      ),
    );
  }
}
