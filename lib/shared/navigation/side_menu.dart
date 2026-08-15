import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/routes.dart';
import '../../core/utils/responsive.dart';
import '../../features/auth/bloc/auth_bloc.dart';
import '../../features/settings/bloc/locale_cubit.dart';
import '../../features/settings/bloc/theme_cubit.dart';
import '../../l10n/app_localizations.dart';

/// Open/close state of the side menu.
final class MenuCubit extends Cubit<bool> {
  MenuCubit() : super(false);

  void open() => emit(true);
  void dismiss() => emit(false);
  void toggle() => emit(!state);
}

/// The reference's overlay drawer: a theme-aware panel that slides over the
/// dimmed content with rounded trailing corners — avatar header with a
/// circular ✕, "MENU" group with the active item softly highlighted, an
/// account group, and the Dark Mode / Settings footer.
final class SideMenu extends StatelessWidget {
  const SideMenu({super.key, required this.location});

  final String location;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = context.watch<ThemeCubit>().state;
    final auth = context.watch<AuthBloc>().state;
    final lang = context.watch<LocaleCubit>().state.languageCode;
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Panel palette — near-black glass in dark mode, white panel in light.
    final panel = isDark
        ? const Color(0xFF191B21).withValues(alpha: 0.98)
        : Colors.white;
    final fg = isDark ? Colors.white : const Color(0xFF17181C);
    final muted = fg.withValues(alpha: 0.55);
    final highlight = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : const Color(0xFF17181C).withValues(alpha: 0.06);

    void go(String route) {
      context.read<MenuCubit>().dismiss();
      if (location != route) context.go(route);
    }

    final name = auth.user?.displayName(lang);
    final display = (name == null || name.isEmpty) ? t.homeGuest : name;
    final subtitle = auth.user?.email ??
        (theme.brandKey == 'lexus' ? t.brandLexus : t.brandToyota);

    Widget groupLabel(String text) => Padding(
          padding: EdgeInsets.fromLTRB(
              context.rs(14), context.rs(18), context.rs(14), context.rs(8)),
          child: Text(
            text.toUpperCase(),
            style: TextStyle(
              fontSize: context.rf(10),
              fontWeight: FontWeight.w800,
              letterSpacing: 1.4,
              color: muted.withValues(alpha: 0.45),
            ),
          ),
        );

    Widget item(IconData icon, String label, String route) {
      final selected = location == route;
      return Padding(
        padding: EdgeInsets.only(bottom: context.rs(2)),
        child: Material(
          color: selected ? highlight : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: () => go(route),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: context.rs(14), vertical: context.rs(11)),
              child: Row(
                children: [
                  Icon(icon,
                      size: 18, color: fg.withValues(alpha: selected ? 1 : 0.75)),
                  SizedBox(width: context.rs(12)),
                  Text(
                    label,
                    style: TextStyle(
                      color: fg.withValues(alpha: selected ? 1 : 0.85),
                      fontSize: context.rf(13.5),
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Material(
      color: panel,
      borderRadius:
          const BorderRadiusDirectional.horizontal(end: Radius.circular(28)),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
              horizontal: context.rs(14), vertical: context.rs(10)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: avatar + name/subtitle + circular close.
              Padding(
                padding: EdgeInsets.symmetric(horizontal: context.rs(4)),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: context.rs(17),
                      backgroundColor: scheme.primary.withValues(alpha: 0.16),
                      child: Text(
                        display.characters.first.toUpperCase(),
                        style: TextStyle(
                            color: scheme.primary,
                            fontWeight: FontWeight.w800,
                            fontSize: context.rf(14)),
                      ),
                    ),
                    SizedBox(width: context.rs(10)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            display,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: fg,
                                fontSize: context.rf(13.5),
                                fontWeight: FontWeight.w800),
                          ),
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style:
                                TextStyle(color: muted, fontSize: context.rf(10.5)),
                          ),
                        ],
                      ),
                    ),
                    // Circular ✕ like the reference.
                    Material(
                      color: fg.withValues(alpha: isDark ? 0.14 : 0.08),
                      shape: const CircleBorder(),
                      child: InkWell(
                        onTap: () => context.read<MenuCubit>().dismiss(),
                        customBorder: const CircleBorder(),
                        child: SizedBox(
                          width: context.rs(32),
                          height: context.rs(32),
                          child: Icon(Icons.close_rounded, size: 17, color: fg),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Items scroll on short screens; the footer stays pinned.
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      groupLabel(lang == 'ar' ? 'القائمة' : 'Menu'),
                      item(Icons.home_rounded,
                          lang == 'ar' ? 'الرئيسية' : 'Home', Routes.home),
                      item(Icons.storefront_outlined, t.homeOnlineStore,
                          Routes.onlineStore),
                      item(Icons.directions_car_outlined, t.homeMeetTheModels,
                          Routes.models),
                      item(Icons.car_rental_outlined, t.ucTitle,
                          Routes.usedCars),
                      item(Icons.local_offer_outlined, t.offersTitle,
                          Routes.offers),
                      item(Icons.account_balance_outlined, t.finTitle,
                          Routes.finance),
                      item(Icons.settings_suggest_outlined, t.partsTitle,
                          Routes.parts),
                      item(Icons.shield_outlined, t.protTitle,
                          Routes.protection),
                      item(Icons.build_circle_outlined, t.mhTitle,
                          Routes.maintenance),
                      item(Icons.newspaper_outlined, t.newsTitle, Routes.news),
                      item(Icons.support_agent_outlined, t.contactTitle,
                          Routes.contact),
                      item(Icons.shopping_cart_outlined, t.cartTitle,
                          Routes.cart),
                      Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: context.rs(14),
                            vertical: context.rs(10)),
                        child:
                            Divider(height: 1, color: fg.withValues(alpha: 0.1)),
                      ),
                      groupLabel(lang == 'ar' ? 'حسابي' : 'Account'),
                      item(Icons.favorite_border_rounded, t.favTitle,
                          Routes.favorites),
                      item(Icons.person_outline_rounded, t.pfTitle,
                          Routes.profile),
                    ],
                  ),
                ),
              ),
              // Dark Mode toggle row — the reference footer.
              Padding(
                padding: EdgeInsets.symmetric(horizontal: context.rs(14)),
                child: Row(
                  children: [
                    Icon(Icons.dark_mode_outlined,
                        size: 18, color: fg.withValues(alpha: 0.75)),
                    SizedBox(width: context.rs(12)),
                    Expanded(
                      child: Text(
                        t.homeThemeMode,
                        style: TextStyle(
                            color: fg.withValues(alpha: 0.85),
                            fontSize: context.rf(13.5),
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                    Switch(
                      value: theme.mode == ThemeMode.dark,
                      activeThumbColor: scheme.primary,
                      onChanged: (v) => context
                          .read<ThemeCubit>()
                          .setMode(v ? ThemeMode.dark : ThemeMode.light),
                    ),
                  ],
                ),
              ),
              item(Icons.settings_outlined, t.drawerSettings, Routes.profile),
              SizedBox(height: context.rs(4)),
            ],
          ),
        ),
      ),
    );
  }
}
