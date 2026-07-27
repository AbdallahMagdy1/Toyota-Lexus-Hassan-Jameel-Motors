import 'dart:convert';
import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/api_paths.dart';
import '../../core/di/injector.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/responsive.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/navigation/sheet_routes.dart';
import '../auth/bloc/auth_bloc.dart';
import '../settings/bloc/locale_cubit.dart';

/// One stored notification — the old app's model: bilingual title/body +
/// route, persisted locally (get_storage there, SharedPreferences here).
final class AppNotification extends Equatable {
  const AppNotification({
    required this.id,
    this.titleAr,
    this.titleEn,
    this.bodyAr,
    this.bodyEn,
    this.route,
    required this.date,
  });

  final String id;
  final String? titleAr;
  final String? titleEn;
  final String? bodyAr;
  final String? bodyEn;
  final String? route;
  final DateTime date;

  String title(String lang) =>
      (lang == 'ar' ? titleAr : titleEn) ?? titleEn ?? titleAr ?? '';
  String body(String lang) =>
      (lang == 'ar' ? bodyAr : bodyEn) ?? bodyEn ?? bodyAr ?? '';

  Map<String, dynamic> toJson() => {
        'id': id,
        'titleAr': titleAr,
        'titleEn': titleEn,
        'bodyAr': bodyAr,
        'bodyEn': bodyEn,
        'route': route,
        'date': date.toIso8601String(),
      };

  factory AppNotification.fromJson(Map<String, dynamic> j) => AppNotification(
        id: j['id']?.toString() ?? '',
        titleAr: j['titleAr']?.toString(),
        titleEn: j['titleEn']?.toString(),
        bodyAr: j['bodyAr']?.toString(),
        bodyEn: j['bodyEn']?.toString(),
        route: j['route']?.toString(),
        date: DateTime.tryParse(j['date']?.toString() ?? '') ?? DateTime.now(),
      );

  factory AppNotification.fromMessage(RemoteMessage m) => AppNotification(
        id: m.messageId ?? DateTime.now().microsecondsSinceEpoch.toString(),
        titleAr: m.data['titleAr'] ?? m.notification?.title,
        titleEn: m.data['titleEn'] ?? m.notification?.title,
        bodyAr: m.data['bodyAr'] ?? m.notification?.body,
        bodyEn: m.data['bodyEn'] ?? m.notification?.body,
        route: m.data['route'],
        date: DateTime.now(),
      );

  @override
  List<Object?> get props => [id];
}

/// Local notification inbox + unread badge. App-lifetime singleton.
final class NotificationsCubit extends Cubit<(List<AppNotification>, int)> {
  NotificationsCubit(this._prefs) : super((const [], 0)) {
    _load();
  }

  final SharedPreferences _prefs;
  static const _key = 'app_notifications';
  static const _unreadKey = 'app_notifications_unread';

  void _load() {
    final raw = _prefs.getString(_key);
    final unread = _prefs.getInt(_unreadKey) ?? 0;
    if (raw == null) return;
    try {
      final list = (jsonDecode(raw) as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .map(AppNotification.fromJson)
          .toList();
      emit((list, unread));
    } catch (_) {}
  }

  Future<void> add(AppNotification n) async {
    final list = [n, ...state.$1].take(100).toList();
    final unread = state.$2 + 1;
    emit((list, unread));
    await _prefs.setString(_key, jsonEncode(list.map((e) => e.toJson()).toList()));
    await _prefs.setInt(_unreadKey, unread);
  }

  Future<void> markAllRead() async {
    emit((state.$1, 0));
    await _prefs.setInt(_unreadKey, 0);
  }

  Future<void> clear() async {
    emit((const [], 0));
    await _prefs.remove(_key);
    await _prefs.setInt(_unreadKey, 0);
  }
}

/// FCM bootstrap — the old app's cycle: init Firebase, high-importance
/// channel, foreground local-notification display, token registered to
/// Web_Users.Token whenever a user signs in.
final class PushService {
  PushService._();

  static final _local = FlutterLocalNotificationsPlugin();
  static const _channel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    importance: Importance.high,
  );
  static bool _ready = false;

  static Future<void> init() async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    try {
      await Firebase.initializeApp();
      await _local.initialize(const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ));
      await _local
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_channel);

      await FirebaseMessaging.instance.requestPermission();

      FirebaseMessaging.onMessage.listen(_onMessage);
      FirebaseMessaging.onBackgroundMessage(_backgroundHandler);
      _ready = true;

      // Register the token now (if signed in) and on every auth change.
      await syncToken();
      sl<AuthBloc>().stream.listen((_) => syncToken());
      FirebaseMessaging.instance.onTokenRefresh.listen((_) => syncToken());
    } catch (e) {
      debugPrint('FCM init skipped: $e');
    }
  }

  static Future<void> _onMessage(RemoteMessage m) async {
    final n = AppNotification.fromMessage(m);
    await sl<NotificationsCubit>().add(n);
    final lang = sl<LocaleCubit>().state.languageCode;
    await _local.show(
      n.id.hashCode,
      n.title(lang),
      n.body(lang),
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }

  /// Web_Users.Token — the same storage the notification procs read.
  static Future<void> syncToken() async {
    if (!_ready) return;
    final user = sl<AuthBloc>().state.user;
    if (user == null || user.userId <= 0) return;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) return;
      await sl<ApiClient>().post<Map<String, dynamic>>(
        ApiPaths.fcmToken,
        body: {'userId': user.userId, 'token': token},
      );
    } catch (e) {
      debugPrint('FCM token sync failed: $e');
    }
  }
}

@pragma('vm:entry-point')
Future<void> _backgroundHandler(RemoteMessage message) async {
  // Data-only messages in background are shown by the system tray via the
  // notification block the backend includes; nothing to do here.
}

/* ───────────────────────── Inbox sheet ───────────────────────── */

void showNotificationsSheet(BuildContext context) {
  sl<NotificationsCubit>().markAllRead();
  showHeroBottomSheet<void>(
    context,
    heightFactor: 0.8,
    builder: (_) => const _NotificationsView(),
  );
}

final class _NotificationsView extends StatelessWidget {
  const _NotificationsView();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final lang = context.watch<LocaleCubit>().state.languageCode;

    return Material(
      color: scheme.surface,
      child: SafeArea(
        top: false,
        child: BlocBuilder<NotificationsCubit, (List<AppNotification>, int)>(
          bloc: sl<NotificationsCubit>(),
          builder: (context, state) {
            final list = state.$1;
            return Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(
                      context.rs(20), context.rs(10), context.rs(20), 0),
                  child: Column(children: [
                    const SheetHandle(),
                    SizedBox(height: context.rs(12)),
                    Row(
                      children: [
                        Expanded(
                          child: Text(t.notifTitle,
                              style: TextStyle(
                                  fontSize: context.rf(18),
                                  fontWeight: FontWeight.w800)),
                        ),
                        if (list.isNotEmpty)
                          TextButton(
                            onPressed: sl<NotificationsCubit>().clear,
                            child: Text(t.notifClear,
                                style: TextStyle(fontSize: context.rf(11.5))),
                          ),
                      ],
                    ),
                  ]),
                ),
                Expanded(
                  child: list.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.notifications_none_rounded,
                                  size: 44,
                                  color: scheme.onSurface
                                      .withValues(alpha: 0.25)),
                              SizedBox(height: context.rs(10)),
                              Text(t.notifEmpty,
                                  style: TextStyle(
                                      fontSize: context.rf(13),
                                      color: scheme.onSurface
                                          .withValues(alpha: 0.55))),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: EdgeInsets.all(context.rs(16)),
                          itemCount: list.length,
                          separatorBuilder: (_, _) =>
                              SizedBox(height: context.rs(8)),
                          itemBuilder: (context, i) {
                            final n = list[i];
                            return Container(
                              padding: EdgeInsets.all(context.rs(12)),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                    color: scheme.outline
                                        .withValues(alpha: 0.5)),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: context.rs(34),
                                    height: context.rs(34),
                                    decoration: BoxDecoration(
                                      color: scheme.primary
                                          .withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                        Icons.notifications_active_outlined,
                                        size: 16,
                                        color: scheme.primary),
                                  ),
                                  SizedBox(width: context.rs(10)),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(n.title(lang),
                                            style: TextStyle(
                                                fontSize: context.rf(12.5),
                                                fontWeight: FontWeight.w800)),
                                        if (n.body(lang).isNotEmpty)
                                          Text(n.body(lang),
                                              style: TextStyle(
                                                  fontSize: context.rf(11.5),
                                                  height: 1.4,
                                                  color: scheme.onSurface
                                                      .withValues(
                                                          alpha: 0.65))),
                                        SizedBox(height: context.rs(3)),
                                        Text(
                                          n.date
                                              .toIso8601String()
                                              .substring(0, 16)
                                              .replaceAll('T', ' '),
                                          textDirection: TextDirection.ltr,
                                          style: TextStyle(
                                              fontSize: context.rf(9.5),
                                              color: scheme.onSurface
                                                  .withValues(alpha: 0.45)),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
