import 'dart:convert' show base64Encode;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

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

    final userId = authUser?.userId ?? 0;

    return Column(children: [
      const AppHeader(),
      Expanded(
        child: ListView(
          padding: EdgeInsets.fromLTRB(
              context.rs(16), context.rs(18), context.rs(16), context.rs(110)),
          children: [
            _HeaderCard(lang: lang, userId: userId)
                .animate()
                .fadeIn(duration: 260.ms)
                .slideY(begin: 0.05, curve: Curves.easeOut),

            if (signedIn) ...[
              // ── Account data (sheet editors) ──
              groupTitle(t.profileAccount),
              row(Icons.badge_outlined, t.pfMyData,
                  () => showMyDataSheet(context, cubit)),
              row(Icons.alternate_email_rounded, t.pfContactData,
                  sub: full?.phone ?? authUser.phone,
                  () => showContactDataSheet(context, cubit)),
              row(Icons.lock_outline_rounded, t.pfPassword,
                  () => showPasswordSheet(context, cubit)),
              row(Icons.request_quote_outlined, t.pfFinanceRequests,
                  () => context.push(Routes.financeRequests)),
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
                  minimumSize: const Size.fromHeight(44),
                  shape: const StadiumBorder(),
                ),
                onPressed: () =>
                    context.read<AuthBloc>().add(const AuthSignOutRequested()),
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: Text(t.homeSignOut),
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
  const _HeaderCard({required this.lang, required this.userId});

  final String lang;
  final int userId;

  /// Gallery → base64 (resized ≤720px, no data-url prefix) → the website's
  /// UpdateWeb_users(Logo) cycle.
  Future<void> _pickPhoto(BuildContext context) async {
    final t = AppLocalizations.of(context);
    final cubit = context.read<ProfileCubit>();
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 720,
      maxHeight: 720,
      imageQuality: 82,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    if (bytes.lengthInBytes > 4 * 1024 * 1024) return;
    final ok = await cubit.changeImage(base64Encode(bytes));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
          SnackBar(content: Text(ok ? t.pfPhotoUpdated : t.pfPhotoFailed)));
  }

  /// Full-screen photo viewer (tap anywhere / close to dismiss).
  void _viewPhoto(BuildContext context) {
    final avatar = context.read<ProfileCubit>().state.avatar;
    if (avatar == null) return;
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.85),
      builder: (_) => GestureDetector(
        onTap: () => Navigator.of(context, rootNavigator: true).pop(),
        child: InteractiveViewer(
          child: Center(
            child: Image.memory(avatar, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }

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
                minimumSize: const Size.fromHeight(44),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              // Straight to the sign-in screen — the welcome route bounces
              // guest sessions back home via the router redirect.
              onPressed: () => context.go(Routes.signIn),
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
    final avatar = context.select((ProfileCubit c) => c.state.avatar);
    final avatarBusy = context.select((ProfileCubit c) => c.state.avatarBusy);
    final cubit = context.read<ProfileCubit>();

    // The reference-mock profile hero: centered photo avatar (tap to view,
    // camera badge to change), name + phone, action pill row, then a
    // 3-column quick-links strip separated by hairlines.
    return Container(
      padding: EdgeInsets.fromLTRB(
          context.rs(16), context.rs(20), context.rs(16), context.rs(6)),
      decoration: softCardDecoration(context, radius: 24),
      child: Column(children: [
        // ── Avatar + change badge ──
        Semantics(
          label: t.pfViewPhoto,
          button: true,
          child: SizedBox(
            width: context.rs(96),
            height: context.rs(96),
            child: Stack(children: [
              GestureDetector(
                onTap: () => _viewPhoto(context),
                child: Container(
                  width: context.rs(96),
                  height: context.rs(96),
                  alignment: Alignment.center,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: avatar == null
                        ? LinearGradient(colors: [
                            scheme.primary,
                            scheme.primary.withValues(alpha: 0.65),
                          ])
                        : null,
                    border: Border.all(
                        color: scheme.primary.withValues(alpha: 0.25),
                        width: 2),
                    image: avatar == null
                        ? null
                        : DecorationImage(
                            image: MemoryImage(avatar), fit: BoxFit.cover),
                  ),
                  child: avatar == null
                      ? Text(initial,
                          style: TextStyle(
                              color: scheme.onPrimary,
                              fontSize: context.rf(34),
                              fontWeight: FontWeight.w800))
                      : null,
                ),
              ),
              if (avatarBusy)
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withValues(alpha: 0.35),
                    ),
                    child: const Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.4, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              // Camera badge — change the photo (44pt hit area via padding).
              PositionedDirectional(
                bottom: 0,
                end: 0,
                child: Semantics(
                  label: t.pfChangePhoto,
                  button: true,
                  child: Material(
                    color: scheme.primary,
                    shape: const CircleBorder(),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap:
                          avatarBusy ? null : () => _pickPhoto(context),
                      child: Tooltip(
                        message: t.pfChangePhoto,
                        child: SizedBox(
                          width: context.rs(30),
                          height: context.rs(30),
                          child: Icon(Icons.photo_camera_rounded,
                              size: 15, color: scheme.onPrimary),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ]),
          ),
        ),
        SizedBox(height: context.rs(10)),
        Text(name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: context.rf(16.5), fontWeight: FontWeight.w800)),
        if (phone.isNotEmpty) ...[
          SizedBox(height: context.rs(2)),
          Text(phone,
              textDirection: TextDirection.ltr,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: context.rf(11.5),
                  color: scheme.onSurface.withValues(alpha: 0.55))),
        ],
        SizedBox(height: context.rs(14)),
        // ── Action row: update-profile pill + two icon squares (mock) ──
        Row(children: [
          SizedBox(width: context.rs(8)),
          _HeroSquare(
            icon: Icons.lock_outline_rounded,
            label: t.pfPassword,
            onTap: () => showPasswordSheet(context, cubit),
          ),
          SizedBox(width: context.rs(8)),
          Expanded(
            child: FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size(64, 44),
                shape: const StadiumBorder(),
              ),
              onPressed: () => showMyDataSheet(context, cubit),
              child: Text(t.pfMyData),
            ),
          ),
          SizedBox(width: context.rs(8)),
          _HeroSquare(
            icon: Icons.alternate_email_rounded,
            label: t.pfContactData,
            onTap: () => showContactDataSheet(context, cubit),
          ),
          SizedBox(width: context.rs(8)),
        ]),
        SizedBox(height: context.rs(14)),
        Divider(
            height: 1, color: scheme.outline.withValues(alpha: 0.5)),
        // ── 3-column quick-links strip (Account/Signature/Documents) ──
        IntrinsicHeight(
          child: Row(children: [
            _HeroStripItem(
              icon: Icons.directions_car_outlined,
              label: t.pfMyCars,
              onTap: () => showMyCarsSheet(context, userId: userId),
            ),
            VerticalDivider(
                width: 1,
                color: scheme.outline.withValues(alpha: 0.5)),
            _HeroStripItem(
              icon: Icons.receipt_long_outlined,
              label: t.pfMyOrders,
              onTap: () => context.push(Routes.tracking),
            ),
            VerticalDivider(
                width: 1,
                color: scheme.outline.withValues(alpha: 0.5)),
            _HeroStripItem(
              icon: Icons.event_available_outlined,
              label: t.pfMyBookings,
              onTap: () => context.push(Routes.tracking),
            ),
          ]),
        ),
      ]),
    );
  }
}

/// Small soft icon square flanking the hero's primary pill (the mock's two
/// side buttons).
final class _HeroSquare extends StatelessWidget {
  const _HeroSquare({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      label: label,
      button: true,
      child: Material(
        color: scheme.primary.withValues(alpha: isDark ? 0.2 : 0.09),
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Tooltip(
            message: label,
            child: SizedBox(
              width: context.rs(44),
              height: context.rs(44),
              child: Icon(icon, size: 19, color: scheme.primary),
            ),
          ),
        ),
      ),
    );
  }
}

/// One column of the hero's bottom strip: icon over a bold label.
final class _HeroStripItem extends StatelessWidget {
  const _HeroStripItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: context.rs(12)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 19, color: scheme.primary),
              SizedBox(height: context.rs(5)),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: context.rf(10.5),
                    fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
