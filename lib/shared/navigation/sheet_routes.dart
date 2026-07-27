import 'package:flutter/material.dart';

/// NZ-Mobile-style modal bottom sheet (92% height, top radius 20, 300ms
/// slide-up, drag-down to dismiss) implemented as a PageRoute so **Hero
/// animations fly into it** — showModalBottomSheet can't do that.
Future<T?> showHeroBottomSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  double heightFactor = 0.92,
}) {
  return Navigator.of(context, rootNavigator: true).push<T>(
    _SheetPageRoute<T>(builder: builder, heightFactor: heightFactor),
  );
}

final class _SheetPageRoute<T> extends PageRoute<T> {
  _SheetPageRoute({required this.builder, required this.heightFactor});

  final WidgetBuilder builder;
  final double heightFactor;

  @override
  bool get opaque => false;

  @override
  Color? get barrierColor => Colors.black.withValues(alpha: 0.55);

  @override
  String? get barrierLabel => 'sheet';

  @override
  bool get barrierDismissible => true;

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 300);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 220);

  @override
  Widget buildPage(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation) {
    final sheet = Align(
      alignment: Alignment.bottomCenter,
      child: FractionallySizedBox(
        heightFactor: heightFactor,
        widthFactor: 1,
        child: _DraggableDismiss(
          onDismiss: () => Navigator.of(context).maybePop(),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: Material(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: SafeArea(top: false, child: builder(context)),
            ),
          ),
        ),
      ),
    );
    return sheet;
  }

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) {
    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
          .animate(CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      )),
      child: child,
    );
  }
}

/// Swipe-down-to-dismiss wrapper for the sheet (fast downward fling closes).
final class _DraggableDismiss extends StatelessWidget {
  const _DraggableDismiss({required this.child, required this.onDismiss});

  final Widget child;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onVerticalDragEnd: (d) {
        if ((d.primaryVelocity ?? 0) > 700) onDismiss();
      },
      child: child,
    );
  }
}

/// Standard grab-handle for the sheets.
final class SheetHandle extends StatelessWidget {
  const SheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 10, bottom: 6),
        width: 42,
        height: 4.5,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    );
  }
}

/// Right-edge (start-aware) filter drawer as a route: slides in from the
/// trailing edge over a scrim — used for the online-store filters.
Future<T?> showEndDrawerSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  double widthFactor = 0.84,
}) {
  final isRtl = Directionality.of(context) == TextDirection.rtl;
  return Navigator.of(context, rootNavigator: true).push<T>(
    PageRouteBuilder<T>(
      opaque: false,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      barrierDismissible: true,
      barrierLabel: 'filters',
      transitionDuration: const Duration(milliseconds: 280),
      reverseTransitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, _, _) => Align(
        alignment: isRtl ? Alignment.centerLeft : Alignment.centerRight,
        child: FractionallySizedBox(
          widthFactor: widthFactor,
          heightFactor: 1,
          child: Material(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: SafeArea(child: builder(context)),
          ),
        ),
      ),
      transitionsBuilder: (context, animation, _, child) => SlideTransition(
        position: Tween<Offset>(
          begin: Offset(isRtl ? -1 : 1, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
        child: child,
      ),
    ),
  );
}
