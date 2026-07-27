import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/routes.dart';
import '../../core/utils/responsive.dart';
import '../../features/cart/bloc/cart_cubit.dart';

/// The reference's floating dark pill nav: Home / Favorites / Cart / Profile,
/// active tab highlighted, live cart badge.
final class AppBottomNav extends StatelessWidget {
  const AppBottomNav({super.key, required this.location});

  final String location;

  static const tabs = [
    (Routes.home, Icons.home_rounded),
    (Routes.favorites, Icons.favorite_border_rounded),
    (Routes.cart, Icons.shopping_cart_outlined),
    (Routes.profile, Icons.person_outline_rounded),
  ];

  /// Routes where the bar is visible.
  static bool showsOn(String location) =>
      tabs.any((t) => location == t.$1);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cartCount = context.select((CartCubit c) => c.state.length);

    return Padding(
      padding: EdgeInsets.fromLTRB(context.rs(38), 0, context.rs(38), context.rs(12)),
      child: Material(
        // Light mode = white pill, dark mode = dark pill.
        color: isDark ? const Color(0xFF1A1C21) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        elevation: 8,
        shadowColor: Colors.black.withValues(alpha: isDark ? 0.35 : 0.18),
        child: SizedBox(
          height: context.rs(52),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (final (route, icon) in tabs)
                _NavItem(
                  icon: icon,
                  active: location == route,
                  badge: route == Routes.cart && cartCount > 0 ? cartCount : null,
                  activeColor: scheme.primary,
                  inactiveColor: isDark
                      ? Colors.white.withValues(alpha: 0.6)
                      : const Color(0xFF141519).withValues(alpha: 0.45),
                  onTap: () {
                    if (location != route) context.go(route);
                  },
                ),
            ],
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
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        width: context.rs(46),
        height: context.rs(38),
        decoration: BoxDecoration(
          // Reference-kit active pill: brand gradient + colored glow.
          gradient: active
              ? LinearGradient(colors: [
                  activeColor,
                  activeColor.withValues(alpha: 0.78),
                ])
              : null,
          borderRadius: BorderRadius.circular(16),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: activeColor.withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : const [],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedScale(
              scale: active ? 1.08 : 1,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutBack,
              child: Icon(
                icon,
                size: 20,
                color: active ? Colors.white : inactiveColor,
              ),
            ),
            if (badge != null)
              PositionedDirectional(
                top: 6,
                end: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4.5, vertical: 1.5),
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
