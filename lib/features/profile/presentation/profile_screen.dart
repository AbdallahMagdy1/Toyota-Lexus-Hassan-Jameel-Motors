import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../core/di/injector.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/responsive.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/app_header.dart';
import '../../account/data/account_repository.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../home/presentation/widgets/home_bits.dart';
import '../../notifications/notifications.dart';
import '../../settings/bloc/locale_cubit.dart';
import '../../settings/bloc/theme_cubit.dart';

/// Profile — the website's /profile hub, reference-card style: avatar
/// header + stats strip + grouped account rows (my vehicles, orders,
/// bookings, finance requests, favorites, notifications, contact),
/// personal data and the app preferences.
final class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final user = context.select((AuthBloc b) => b.state.user);
    final lang = context.watch<LocaleCubit>().state.languageCode;
    final themeState = context.watch<ThemeCubit>().state;
    final scheme = Theme.of(context).colorScheme;
    final cached = user == null
        ? null
        : AccountRepository(sl<ApiClient>()).cachedHome(user.userId);
    final name = (user?.displayName(lang) ?? '').trim();
    final initial = name.isEmpty ? '؟' : name.characters.first;

    Widget row(IconData icon, String label, String sub, VoidCallback onTap,
            {Widget? trailing}) =>
        Padding(
          padding: EdgeInsets.only(bottom: context.rs(8)),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: onTap,
              child: Container(
                padding: EdgeInsets.all(context.rs(13)),
                decoration: softCardDecoration(context, radius: 16),
                child: Row(children: [
                  Container(
                    width: context.rs(36),
                    height: context.rs(36),
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(icon, size: 17, color: scheme.primary),
                  ),
                  SizedBox(width: context.rs(11)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(label,
                            style: TextStyle(
                                fontSize: context.rf(13),
                                fontWeight: FontWeight.w800)),
                        Text(sub,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: context.rf(10.5),
                                color: scheme.onSurface
                                    .withValues(alpha: 0.55))),
                      ],
                    ),
                  ),
                  trailing ??
                      Icon(Icons.chevron_right_rounded,
                          color: scheme.onSurface.withValues(alpha: 0.35)),
                ]),
              ),
            ),
          ),
        );

    Widget groupTitle(String s) => Padding(
          padding: EdgeInsets.fromLTRB(
              context.rs(4), context.rs(16), context.rs(4), context.rs(8)),
          child: Text(s,
              style: TextStyle(
                  fontSize: context.rf(15), fontWeight: FontWeight.w800)),
        );

    return Column(children: [
      const AppHeader(),
      Expanded(
        child: ListView(
          padding: EdgeInsets.fromLTRB(
              context.rs(16), context.rs(16), context.rs(16), context.rs(140)),
          children: [
            // Avatar header (reference style).
            Row(children: [
              Container(
                width: context.rs(64),
                height: context.rs(64),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [
                    scheme.primary,
                    scheme.primary.withValues(alpha: 0.65),
                  ]),
                ),
                child: Text(initial,
                    style: TextStyle(
                        color: scheme.onPrimary,
                        fontSize: context.rf(24),
                        fontWeight: FontWeight.w800)),
              ),
              SizedBox(width: context.rs(14)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: TextStyle(
                            fontSize: context.rf(18),
                            fontWeight: FontWeight.w800)),
                    Text(user?.phone ?? user?.email ?? '',
                        textDirection: TextDirection.ltr,
                        style: TextStyle(
                            fontSize: context.rf(11.5),
                            color:
                                scheme.onSurface.withValues(alpha: 0.55))),
                  ],
                ),
              ),
            ]),
            SizedBox(height: context.rs(16)),

            // Stats strip.
            Container(
              padding: EdgeInsets.symmetric(vertical: context.rs(12)),
              decoration: softCardDecoration(context,
                  radius: 18, tint: scheme.primary),
              child: Row(children: [
                for (final (v, label) in [
                  ('${cached?.garage.length ?? '—'}', t.acMyGarage),
                  ('${cached?.journeys.length ?? '—'}', t.acJourneys),
                ])
                  Expanded(
                    child: Column(children: [
                      Text(v,
                          style: TextStyle(
                              fontSize: context.rf(18),
                              fontWeight: FontWeight.w800,
                              color: scheme.primary)),
                      Text(label,
                          style: TextStyle(
                              fontSize: context.rf(10.5),
                              color: scheme.onSurface
                                  .withValues(alpha: 0.55))),
                    ]),
                  ),
              ]),
            ),

            // ── Account (mirrors the website profile tabs) ──
            groupTitle(t.profileAccount),
            row(Icons.directions_car_outlined, t.acMyGarage,
                t.profileVehiclesSub, () => context.go(Routes.home)),
            row(Icons.receipt_long_outlined, t.acMyOrders, t.profileOrdersSub,
                () => context.push(Routes.tracking)),
            row(Icons.request_quote_outlined, t.finReqTitle,
                t.profileFinanceSub,
                () => context.push(Routes.financeRequests)),
            row(Icons.favorite_border_rounded, t.favTitle,
                t.profileFavoritesSub, () => context.push(Routes.favorites)),
            row(Icons.notifications_none_rounded, t.notifTitle,
                t.profileNotifSub, () => showNotificationsSheet(context)),
            row(Icons.support_agent_outlined, t.contactTitle,
                t.profileContactSub, () => context.push(Routes.contact)),

            // ── Preferences ──
            groupTitle(t.profilePrefs),
            row(
              Icons.dark_mode_outlined,
              t.profileDarkMode,
              themeState.mode == ThemeMode.dark ? t.profileOn : t.profileOff,
              () => context.read<ThemeCubit>().setMode(
                  themeState.mode == ThemeMode.dark
                      ? ThemeMode.light
                      : ThemeMode.dark),
              trailing: Switch(
                value: themeState.mode == ThemeMode.dark,
                onChanged: (v) => context
                    .read<ThemeCubit>()
                    .setMode(v ? ThemeMode.dark : ThemeMode.light),
              ),
            ),
            row(
              Icons.translate_rounded,
              t.profileLanguage,
              lang == 'ar' ? 'العربية' : 'English',
              () => context.read<LocaleCubit>().toggle(),
            ),

            // ── Personal data (read-only) ──
            groupTitle(t.profilePersonal),
            Container(
              padding: EdgeInsets.all(context.rs(14)),
              decoration: softCardDecoration(context, radius: 16),
              child: Column(children: [
                for (final (label, value) in [
                  (t.formFirstName,
                      '${user?.firstNameAr ?? ''} / ${user?.firstNameEn ?? ''}'),
                  (t.formLastName,
                      '${user?.lastNameAr ?? ''} / ${user?.lastNameEn ?? ''}'),
                  (t.formPhone, user?.phone ?? '—'),
                  (t.formEmailOptional, user?.email ?? '—'),
                ])
                  Padding(
                    padding: EdgeInsets.only(bottom: context.rs(8)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(label,
                            style: TextStyle(
                                fontSize: context.rf(11.5),
                                color: scheme.onSurface
                                    .withValues(alpha: 0.55))),
                        Flexible(
                          child: Text(value,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: context.rf(12.5),
                                  fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  ),
              ]),
            ),
            SizedBox(height: context.rs(18)),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                shape: const StadiumBorder(),
                side: BorderSide(color: scheme.error),
                foregroundColor: scheme.error,
              ),
              onPressed: () =>
                  context.read<AuthBloc>().add(const AuthSignOutRequested()),
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: Text(t.homeSignOut),
            ),
          ],
        ),
      ),
    ]);
  }
}
