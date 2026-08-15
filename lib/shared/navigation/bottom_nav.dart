import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/routes.dart';
import '../../core/utils/responsive.dart';
import '../../features/cart/bloc/cart_cubit.dart';

/// Instagram-style floating pill nav: a wide stadium bar hugging the bottom,
/// active tab in a soft circular highlight, live cart badge — and dynamic
/// with scrolling: [collapsed] shrinks the whole bar toward the bottom edge
/// while the user scrolls down, springing back on scroll-up (the shell
/// drives this from the page's scroll notifications).
final class AppBottomNav extends StatelessWidget {
  const AppBottomNav({super.key, required this.location, this.collapsed = false});

  final String location;

  /// True while the user is scrolling down — the bar scales down compactly.
  final bool collapsed;

  static const tabs = [
    (Routes.home, Icons.home_rounded),
    (Routes.store, Icons.storefront_rounded),
    (Routes.cart, Icons.shopping_cart_outlined),
    (Routes.profile, Icons.person_outline_rounded),
  ];

  /// Routes where the bar is visible.
  static bool showsOn(String location) => tabs.any((t) => location == t.$1);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cartCount = context.select((CartCubit c) => c.state.length);

    return AnimatedScale(
      // Instagram-like breathing: shrink toward the bottom center while
      // scrolling down, grow back on scroll-up. Transform-only — cheap.
      scale: collapsed ? 0.84 : 1,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      alignment: Alignment.bottomCenter,
      child: AnimatedOpacity(
        opacity: collapsed ? 0.9 : 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            context.rs(20),
            0,
            context.rs(20),
            context.rs(10),
          ),
          child: Material(
            // Light mode = white pill, dark mode = near-black pill (ref).
            // Flat — a hairline outline separates it instead of a shadow.
            color: isDark ? const Color(0xFF1A1C21) : Colors.white,
            borderRadius: BorderRadius.circular(999),
            child: Container(
              height: context.rs(62),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                    color: scheme.outline.withValues(alpha: 0.4)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (final (route, icon) in tabs)
                    _NavItem(
                      icon: icon,
                      active: location == route,
                      badge: route == Routes.cart && cartCount > 0
                          ? cartCount
                          : null,
                      activeColor: scheme.primary,
                      inactiveColor: isDark
                          ? Colors.white.withValues(alpha: 0.65)
                          : const Color(0xFF141519).withValues(alpha: 0.5),
                      onTap: () {
                        if (location != route) {
                          // Subtle selection tick — premium tab feel.
                          HapticFeedback.selectionClick();
                          context.go(route);
                        }
                      },
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

final class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.active,
    required this.onTap,
    required this.activeColor,
    required this.inactiveColor,
    this.badge,
  });

  final IconData icon;
  final bool active;
  final VoidCallback onTap;
  final Color activeColor;
  final Color inactiveColor;
  final int? badge;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOut,
        width: context.rs(48),
        height: context.rs(48),
        decoration: BoxDecoration(
          // Instagram-style active state: a soft circular highlight behind
          // the icon (brand-tinted so each brand keeps its identity).
          shape: BoxShape.circle,
          color: active
              ? activeColor.withValues(alpha: 0.14)
              : Colors.transparent,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedScale(
              scale: active ? 1.1 : 1,
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutBack,
              child: Icon(
                icon,
                size: context.rs(24),
                color: active ? activeColor : inactiveColor,
              ),
            ),
            if (badge != null)
              PositionedDirectional(
                top: 6,
                end: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4.5,
                    vertical: 1.5,
                  ),
                  decoration: BoxDecoration(
                    color: activeColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$badge',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
