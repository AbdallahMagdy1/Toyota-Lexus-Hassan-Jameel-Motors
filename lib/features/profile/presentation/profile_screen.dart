import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../core/di/injector.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/local_store.dart';
import '../../../core/utils/responsive.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/app_header.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../home/presentation/widgets/home_bits.dart';
import '../../settings/bloc/locale_cubit.dart';
import '../../settings/bloc/theme_cubit.dart';
import '../bloc/profile_cubit.dart';
import '../data/profile_repository.dart';
import 'sheets/contact_data_sheet.dart';
import 'sheets/delete_account_sheet.dart';
import 'sheets/my_cars_sheet.dart';
import 'sheets/my_data_sheet.dart';
import 'sheets/notifications_sheet.dart';
import 'sheets/password_sheet.dart';

/// PROFILE HUB — the website's /profile cycle rebuilt mobile-first:
/// hero card → quick-link grid (cars / orders / bookings / finance) →
/// account rows opening bottom-sheet editors (my data / contact /
/// password / notifications) → preferences → sign out → delete account.
final class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.select((AuthBloc b) => b.state.user);
    return BlocProvider(
      key: ValueKey('profile-${user?.id}'),
      create: (_) => ProfileCubit(
        ProfileRepository(sl<ApiClient>(), sl<LocalStore>()),
        sl<AuthBloc>(),
      )..load(),
      child: const _ProfileView(),
    );
  }
}

final class _ProfileView extends StatelessWidget {
  const _ProfileView();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final lang = context.watch<LocaleCubit>().state.languageCode;
    final themeState = context.watch<ThemeCubit>().state;
    final authUser = context.select((AuthBloc b) => b.state.user);
    final cubit = context.watch<ProfileCubit>();
    final full = cubit.state.user;
    final signedIn = authUser != null;

    Widget groupTitle(String s) => Padding(
          padding: EdgeInsets.fromLTRB(
              context.rs(4), context.rs(18), context.rs(4), context.rs(10)),
          child: Row(children: [
            Container(
              width: 4,
              height: context.rs(16),
              margin: EdgeInsetsDirectional.only(end: context.rs(8)),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    scheme.primary,
                    scheme.primary.withValues(alpha: 0.4),
                  ],
                ),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            Text(s,
                style: TextStyle(
                    fontSize: context.rf(15), fontWeight: FontWeight.w800)),
          ]),
        );

    Widget row(
      IconData icon,
      String label,
      VoidCallback onTap, {
      String? sub,
      Widget? trailing,
    }) =>
        Padding(
          padding: EdgeInsets.only(bottom: context.rs(8)),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: onTap,
              child: Container(
                constraints: const BoxConstraints(minHeight: 56),
                padding: EdgeInsets.symmetric(
                    horizontal: context.rs(13), vertical: context.rs(11)),
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
                        if (sub != null)
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

    Widget tile(IconData icon, String label, VoidCallback onTap) => Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onTap,
            child: Container(
              constraints: BoxConstraints(minHeight: context.rs(96)),
              padding: EdgeInsets.all(context.rs(14)),
              decoration: softCardDecoration(context, radius: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: context.rs(38),
                    height: context.rs(38),
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, size: 18, color: scheme.primary),
                  ),
                  SizedBox(height: context.rs(10)),
                  Text(label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: context.rf(12.5),
                          fontWeight: FontWeight.w800)),
                ],
              ),
            ),
          ),
        );

    Widget tileRow(List<Widget> tiles) => Padding(
          padding: EdgeInsets.only(bottom: context.rs(10)),
          child: Row(children: [
            for (var i = 0; i < tiles.length; i++) ...[
              if (i > 0) SizedBox(width: context.rs(10)),
              Expanded(child: tiles[i]),
            ],
          ]),
        );

    final userId = authUser?.userId ?? 0;

    return Column(children: [
      const AppHeader(),
      Expanded(
        child: ListView(
          padding: EdgeInsets.fromLTRB(
              context.rs(16), context.rs(18), context.rs(16), context.rs(110)),
          children: [
            _HeaderCard(lang: lang)
                .animate()
                .fadeIn(duration: 260.ms)
                .slideY(begin: 0.05, curve: Curves.easeOut),

            if (signedIn) ...[
              SizedBox(height: context.rs(16)),
              // Quick links — the website profile's tabs as a 2-col grid.
              tileRow([
                tile(Icons.directions_car_outlined, t.pfMyCars,
                    () => showMyCarsSheet(context, userId: userId)),
                tile(Icons.receipt_long_outlined, t.pfMyOrders,
                    () => context.push(Routes.tracking)),
              ]).animate(delay: 40.ms).fadeIn(duration: 240.ms),
              tileRow([
                tile(Icons.event_available_outlined, t.pfMyBookings,
                    () => context.push(Routes.tracking)),
                tile(Icons.request_quote_outlined, t.pfFinanceRequests,
                    () => context.push(Routes.financeRequests)),
              ]).animate(delay: 80.ms).fadeIn(duration: 240.ms),

              // ── Account data (sheet editors) ──
              groupTitle(t.profileAccount),
              row(Icons.badge_outlined, t.pfMyData,
                  () => showMyDataSheet(context, cubit)),
              row(Icons.alternate_email_rounded, t.pfContactData,
                  sub: full?.phone ?? authUser.phone,
                  () => showContactDataSheet(context, cubit)),
              row(Icons.lock_outline_rounded, t.pfPassword,
                  () => showPasswordSheet(context, cubit)),
              row(Icons.favorite_border_rounded, t.pfFavorites,
                  () => context.push(Routes.favorites)),
              row(Icons.notifications_none_rounded, t.pfNotifications,
                  () => showProfileNotificationsSheet(context, cubit)),
            ],

            // ── Preferences (available to guests too) ──
            groupTitle(t.profilePrefs),
            row(
              Icons.dark_mode_outlined,
              t.profileDarkMode,
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
              sub: lang == 'ar' ? 'العربية' : 'English',
              () => context.read<LocaleCubit>().toggle(),
            ),

            if (signedIn) ...[
              SizedBox(height: context.rs(18)),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  shape: const StadiumBorder(),
                ),
                onPressed: () =>
                    context.read<AuthBloc>().add(const AuthSignOutRequested()),
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: Text(t.homeSignOut),
              ),
              SizedBox(height: context.rs(22)),
              // Destructive zone — separated at the very bottom.
              Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => showDeleteAccountSheet(context, cubit),
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 52),
                    padding: EdgeInsets.symmetric(
                        horizontal: context.rs(13), vertical: context.rs(11)),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: scheme.error.withValues(alpha: 0.45)),
                      color: scheme.error.withValues(alpha: 0.05),
                    ),
                    child: Row(children: [
                      Icon(Icons.delete_outline_rounded,
                          size: 19, color: scheme.error),
                      SizedBox(width: context.rs(11)),
                      Expanded(
                        child: Text(t.pfDeleteAccount,
                            style: TextStyle(
                                fontSize: context.rf(13),
                                fontWeight: FontWeight.w800,
                                color: scheme.error)),
                      ),
                      Icon(Icons.chevron_right_rounded,
                          color: scheme.error.withValues(alpha: 0.55)),
                    ]),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    ]);
  }
}

/* ─────────────────────────── Header card ─────────────────────────── */

final class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.lang});

  final String lang;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final authUser = context.select((AuthBloc b) => b.state.user);
    final full = context.select((ProfileCubit c) => c.state.user);

    if (authUser == null) {
      // Guest hero — invite to sign in.
      return Container(
        padding: EdgeInsets.all(context.rs(18)),
        decoration:
            softCardDecoration(context, radius: 20, tint: scheme.primary),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                width: context.rs(52),
                height: context.rs(52),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: scheme.primary.withValues(alpha: 0.12),
                ),
                child: Icon(Icons.person_outline_rounded,
                    size: 24, color: scheme.primary),
              ),
              SizedBox(width: context.rs(12)),
              Expanded(
                child: Text(t.pfGuest,
                    style: TextStyle(
                        fontSize: context.rf(17),
                        fontWeight: FontWeight.w800)),
              ),
            ]),
            SizedBox(height: context.rs(14)),
            FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () => context.go(Routes.welcome),
              child: Text(t.pfSignIn,
                  style: TextStyle(
                      fontSize: context.rf(13.5),
                      fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      );
    }

    final name = (full?.displayName(lang) ?? authUser.displayName(lang)).trim();
    final phone = full?.phone ?? authUser.phone ?? full?.email ?? '';
    final initial = name.isEmpty ? '؟' : name.characters.first.toUpperCase();

    return Container(
      padding: EdgeInsets.all(context.rs(16)),
      decoration:
          softCardDecoration(context, radius: 20, tint: scheme.primary),
      child: Row(children: [
        Container(
          width: context.rs(60),
          height: context.rs(60),
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
                  fontSize: context.rf(23),
                  fontWeight: FontWeight.w800)),
        ),
        SizedBox(width: context.rs(14)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t.pfSignedInAs,
                  style: TextStyle(
                      fontSize: context.rf(10),
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                      color: scheme.onSurface.withValues(alpha: 0.5))),
              SizedBox(height: context.rs(2)),
              Text(name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: context.rf(17),
                      fontWeight: FontWeight.w800)),
              if (phone.isNotEmpty)
                Text(phone,
                    textDirection: TextDirection.ltr,
                    style: TextStyle(
                        fontSize: context.rf(11.5),
                        color: scheme.onSurface.withValues(alpha: 0.55))),
            ],
          ),
        ),
      ]),
    );
  }
}
