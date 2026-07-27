import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/di/injector.dart';
import '../../core/utils/responsive.dart';
import '../../features/content/contact_screen.dart' show showBranchesSheet;
import '../../features/notifications/notifications.dart';
import '../../features/settings/bloc/theme_cubit.dart';
import '../navigation/side_menu.dart';

/// The app bar from the reference: surface panel with big rounded bottom
/// corners, the website's mobile dual logo (brand logo | HJ logo separated
/// by a vertical line) on the start side, and bell / location / hamburger
/// (brand-colored bars) on the end side.
final class AppHeader extends StatelessWidget {
  const AppHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final brandKey = context.watch<ThemeCubit>().state.brandKey;
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    // The website mobile navbar's exact assets: the brand roundel icon +
    // the full HJ logo (per language + theme).
    final brandIcon = brandKey == 'lexus'
        ? 'assets/logos/lexus-ico.png'
        : 'assets/logos/toyota-ico.png';
    final hjLogo =
        'assets/logos/logo-${isRtl ? 'right' : 'left'}-${isDark ? 'white' : 'black'}.png';

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.07),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
              context.rs(16), context.rs(4), context.rs(6), context.rs(8)),
          child: Row(
            children: [
              // Website mobile logo: brand roundel | full HJ logo.
              Image.asset(
                brandIcon,
                height: context.rs(26),
                fit: BoxFit.contain,
              ),
              Container(
                margin: EdgeInsets.symmetric(horizontal: context.rs(9)),
                width: 1.1,
                height: context.rs(22),
                color: scheme.outline.withValues(alpha: 0.8),
              ),
              Image.asset(
                hjLogo,
                height: context.rs(28),
                fit: BoxFit.contain,
              ),
              const Spacer(),
              // Notifications inbox (FCM) with unread badge.
              BlocBuilder<NotificationsCubit, (List<AppNotification>, int)>(
                bloc: sl<NotificationsCubit>(),
                builder: (context, state) => IconButton(
                  onPressed: () => showNotificationsSheet(context),
                  visualDensity: VisualDensity.compact,
                  icon: Badge(
                    isLabelVisible: state.$2 > 0,
                    label: Text('${state.$2}'),
                    child: const Icon(Icons.notifications_none_rounded,
                        size: 22),
                  ),
                ),
              ),
              // Branches (فرع الخبر / فرع الدمام) → open in Maps.
              IconButton(
                onPressed: () => showBranchesSheet(context),
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.location_on_outlined, size: 22),
              ),
              // Brand-colored hamburger → opens the 3D drawer.
              InkWell(
                onTap: () => context.read<MenuCubit>().open(),
                customBorder: const CircleBorder(),
                child: SizedBox(
                  width: context.rs(42),
                  height: context.rs(40),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        for (final w in [20.0, 20.0, 20.0])
                          Container(
                            margin: const EdgeInsets.symmetric(vertical: 2.2),
                            width: context.rs(w),
                            height: 2.6,
                            decoration: BoxDecoration(
                              color: scheme.primary,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
