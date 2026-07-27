import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/routes.dart';
import '../../core/utils/responsive.dart';
import '../../features/settings/bloc/theme_cubit.dart';

/// The website's floating contact (headphones) button — opens /contact.
final class ContactFab extends StatelessWidget {
  const ContactFab({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return PositionedDirectional(
      start: context.rs(14),
      bottom: context.rs(96),
      child: FloatingActionButton.small(
        heroTag: 'contact-fab',
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        shape: const CircleBorder(),
        onPressed: () => context.push(Routes.contact),
        child: const Icon(Icons.headset_mic_rounded, size: 20),
      ),
    );
  }
}

/// Inline Toyota ⇄ Lexus switch — the reference design's stacked header
/// control: a white vertical capsule with both brand roundels, the active
/// one lifted on a solid brand-colored circle. Not floating — callers
/// place it inline (home greeting, guest hero).
final class BrandSwitchCapsule extends StatelessWidget {
  const BrandSwitchCapsule({super.key});

  @override
  Widget build(BuildContext context) {
    final brandKey = context.watch<ThemeCubit>().state.brandKey;
    final cubit = context.read<ThemeCubit>();
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLexus = brandKey == 'lexus';

    Widget roundel(String asset, bool active, String toBrand) =>
        GestureDetector(
          onTap: () => cubit.setBrand(toBrand),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            width: context.rs(38),
            height: context.rs(38),
            padding: EdgeInsets.all(context.rs(8)),
            decoration: BoxDecoration(
              color: active ? scheme.primary : Colors.transparent,
              shape: BoxShape.circle,
              boxShadow: active
                  ? [
                      BoxShadow(
                        color: scheme.primary.withValues(alpha: 0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : const [],
            ),
            child: active
                // Active roundel: white emblem on the solid brand circle.
                ? Image.asset(asset,
                    fit: BoxFit.contain, color: scheme.onPrimary)
                : Opacity(
                    opacity: 0.45,
                    child: Image.asset(asset, fit: BoxFit.contain)),
          ),
        );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      padding: EdgeInsets.all(context.rs(4)),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF181B21) : Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: isDark
            ? Border.all(color: scheme.outline.withValues(alpha: 0.5))
            : null,
        boxShadow: isDark
            ? const []
            : [
                BoxShadow(
                  color: const Color(0xFF1B2A4A).withValues(alpha: 0.1),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: const Color(0xFF1B2A4A).withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          roundel('assets/logos/toyota-ico.png', !isLexus, 'toyota'),
          SizedBox(height: context.rs(4)),
          roundel('assets/logos/lexus-ico.png', isLexus, 'lexus'),
        ],
      ),
    );
  }
}
