import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:go_router/go_router.dart';

import '../../app/router/routes.dart';
import '../../core/utils/responsive.dart';
import 'bottom_nav.dart';

/// Floating back button — a small surface-colored FAB at the bottom end
/// edge (opposite the contact FAB) that appears only when the shell's
/// manual history has a previous screen to return to. It pops in with a
/// springy scale, shrinks under the finger and bounces back on release
/// before navigating; everything is transform/opacity-only, so it costs
/// nothing per frame.
final class FloatingBackFab extends StatefulWidget {
  const FloatingBackFab({super.key, required this.location});

  final String location;

  /// Roots where back would exit the app — the FAB hides there.
  static const _roots = {Routes.home, Routes.welcome, Routes.onboarding};

  @override
  State<FloatingBackFab> createState() => _FloatingBackFabState();
}

final class _FloatingBackFabState extends State<FloatingBackFab> {
  /// True while the finger is down — drives the press-pop scale.
  bool _pressed = false;

  void _go() {
    HapticFeedback.selectionClick();
    // Pushed pages (context.push — parts, tracking, offers…) pop off the
    // router stack; go()-based navigation walks the manual history instead.
    final router = GoRouter.of(context);
    if (router.canPop()) {
      router.pop();
      return;
    }
    final prev = NavHistory.back(widget.location);
    context.go(prev ?? Routes.home);
  }

  /// The route ACTUALLY on top. For `context.push` the shell keeps building
  /// with the base tab location (that's why the nav bar stays up), so the
  /// pushed page's path is only visible on the router's current uri.
  String _topLocation() {
    try {
      return GoRouter.of(context)
          .routerDelegate
          .currentConfiguration
          .uri
          .path;
    } catch (_) {
      return widget.location;
    }
  }

  @override
  Widget build(BuildContext context) {
    final top = _topLocation();
    bool canPop = false;
    try {
      canPop = GoRouter.of(context).canPop();
    } catch (_) {}
    final visible = NavHistory.participates(top) &&
        !FloatingBackFab._roots.contains(top) &&
        (canPop || NavHistory.hasBack(widget.location));
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Sit above the floating nav pill whenever it is on screen — the bar
    // follows the BASE location, which stays a tab route under pushed pages.
    final bottom = AppBottomNav.showsOn(widget.location)
        ? context.rs(96)
        : context.rs(24);

    return AnimatedPositionedDirectional(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      end: context.rs(14),
      bottom: bottom,
      child: IgnorePointer(
        ignoring: !visible,
        child: AnimatedScale(
          // Entrance/exit pop + press feedback in ONE transform: hidden = 0,
          // pressed = shrunk, idle = full — released with a springy bounce.
          scale: !visible
              ? 0
              : _pressed
                  ? 0.82
                  : 1,
          duration: Duration(milliseconds: _pressed ? 90 : 320),
          curve: _pressed
              ? Curves.easeOut
              : visible
                  ? Curves.easeOutBack
                  : Curves.easeIn,
          child: AnimatedOpacity(
            opacity: visible ? 1 : 0,
            duration: const Duration(milliseconds: 200),
            child: GestureDetector(
              onTapDown: (_) => setState(() => _pressed = true),
              onTapCancel: () => setState(() => _pressed = false),
              onTapUp: (_) {
                setState(() => _pressed = false);
                _go();
              },
              child: Material(
                color: isDark ? const Color(0xFF1A1C21) : Colors.white,
                shape: CircleBorder(
                    side: BorderSide(
                        color: scheme.outline.withValues(alpha: 0.4))),
                clipBehavior: Clip.antiAlias,
                child: SizedBox(
                  width: context.rs(44),
                  height: context.rs(44),
                  child: Icon(
                    Directionality.of(context) == TextDirection.rtl
                        ? Icons.arrow_forward_rounded
                        : Icons.arrow_back_rounded,
                    size: 20,
                    color: scheme.primary,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
