import 'dart:convert';
import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/api_paths.dart';
import '../../core/di/injector.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/responsive.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/navigation/sheet_routes.dart';
import '../../shared/widgets/app_states.dart';
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
        route: PushService.resolveRoute(m.data),
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

  /// Notification permission as last reported by the OS (for diagnostics).
  static String _perm = 'unknown';

  /// Push-registration diagnostics → GET /api/user/token/diag?stage=…
  /// Every step of registration reports here so a phone that "doesn't get
  /// notifications" shows WHY in the server request log (IIS logs the query
  /// even before the backend endpoint is deployed). Fire-and-forget; never
  /// throws, never blocks.
  static void _diag(String stage, [Object? detail]) {
    try {
      final user = sl<AuthBloc>().state.user;
      final d = (detail ?? '').toString().replaceAll(RegExp(r'\s+'), ' ');
      sl<ApiClient>().get<dynamic>(
        ApiPaths.fcmTokenDiag,
        query: {
          'stage': stage,
          'platform': Platform.isIOS ? 'ios' : 'android',
          'brand': appBrand,
          'perm': _perm,
          'userId': user?.userId ?? 0,
          if (d.isNotEmpty) 'detail': d.length > 160 ? d.substring(0, 160) : d,
        },
      ).ignore(); // drop the result and any error
    } catch (_) {}
  }

  static Future<void> init() async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    try {
      await Firebase.initializeApp();
    } catch (e) {
      debugPrint('FCM init skipped: $e');
      _diag('firebase_init_failed', e);
      return;
    }
    _diag('init_ok');

    // ── Token registration FIRST, independent of everything below. ──
    // It used to run only after the permission dialogs, topic subscriptions
    // and getInitialMessage had all completed: a permission prompt the user
    // hadn't answered yet, or any earlier failure, meant the device signed in
    // but NEVER sent its token — so the backend could not reach that phone.
    _ready = true;
    sl<AuthBloc>().stream.listen((state) {
      // Signed out → detach THIS device from the account so it stops
      // receiving that user's personal pushes (other devices keep theirs).
      if (state.user == null && _registeredUserId != null) {
        _unregister();
      } else {
        syncToken();
      }
    });
    FirebaseMessaging.instance.onTokenRefresh.listen((_) => syncToken());
    // Self-heal: re-register every time the app comes back to the
    // foreground, so a token rotated while the app was closed (reinstall,
    // Play-services refresh) or a failed earlier sync never leaves this
    // device unreachable for the signed-in user.
    // (The binding keeps the listener registered for the app's lifetime.)
    AppLifecycleListener(onResume: syncToken);
    syncToken(); // not awaited — never blocks the steps below

    // ── Tap handling NEXT, also ahead of any prompt or network call. ──
    // getInitialMessage used to wait behind the permission dialog and the
    // topic subscriptions (network), so a cold start from a tapped push could
    // stall before deep-linking. Each step below has its own try so one
    // failure never skips the rest.
    FirebaseMessaging.onBackgroundMessage(_backgroundHandler);
    // Background/terminated arrivals: the SYSTEM tray showed them; when the
    // user TAPS one, store it into the in-app inbox AND deep-link to the
    // screen the dashboard chose (data['route']).
    FirebaseMessaging.onMessageOpenedApp.listen(_handleOpen);
    try {
      await _local.initialize(
        const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          // No prompt here — requestPermission() below asks once for both
          // FCM and local notifications, so initialize() never waits on a
          // dialog.
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
        // Foreground notification tapped → deep-link (payload = data['route']).
        onDidReceiveNotificationResponse: (resp) => _navigateTo(resp.payload),
      );
      await _local
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_channel);
      // A foreground-shown notification tapped after the app was killed
      // launches it without onDidReceiveNotificationResponse firing.
      final launch = await _local.getNotificationAppLaunchDetails();
      if (launch?.didNotificationLaunchApp ?? false) {
        _navigateTo(launch!.notificationResponse?.payload);
      }
    } catch (e) {
      debugPrint('Local notifications setup failed: $e');
      _diag('setup_failed', 'local: $e');
    }
    FirebaseMessaging.onMessage.listen(_onMessage);
    try {
      final initial = await FirebaseMessaging.instance.getInitialMessage();
      if (initial != null) await _handleOpen(initial);
    } catch (e) {
      debugPrint('FCM initial message failed: $e');
      _diag('setup_failed', 'initial: $e');
    }

    try {
      final settings = await FirebaseMessaging.instance.requestPermission();
      _perm = settings.authorizationStatus.name; // authorized | denied | …
      _diag('permission', _perm);
      // Android 13+ POST_NOTIFICATIONS also for the local (foreground)
      // notifications path — without it .show() drops silently.
      await _local
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    } catch (e) {
      debugPrint('FCM permission request failed: $e');
      _diag('setup_failed', 'permission: $e');
    }
    // Permission is settled now — on iOS the APNs token (needed for an FCM
    // token) may only exist after it, so sync once more.
    syncToken();

    // "TargetAll" broadcasts publish to the 'all' topic (WebSiteMobileBackEnd
    // FCMServices.SendToTopicAsync) — the OLD app never subscribed, so
    // broadcasts reached nobody. Subscribing fixes send-to-all.
    try {
      await FirebaseMessaging.instance.subscribeToTopic('all');
      // Per-brand topic so broadcasts can target one store app only —
      // and DROP the other brand's topic: dev/debug installs that once
      // ran with the other brand's entry point subscribed to it, and FCM
      // topic subscriptions persist forever unless unsubscribed. Without
      // this cleanup a 'toyota' broadcast still lands in such a Lexus
      // install (and vice versa).
      await FirebaseMessaging.instance.subscribeToTopic(appBrand);
      await FirebaseMessaging.instance
          .unsubscribeFromTopic(appBrand == 'lexus' ? 'toyota' : 'lexus');
    } catch (e) {
      debugPrint('FCM topic subscription failed: $e');
    }
  }

  /// Inbox-only: the tray already displayed this one (background arrival).
  static Future<void> _storeOnly(RemoteMessage m) =>
      sl<NotificationsCubit>().add(AppNotification.fromMessage(m));

  /// User TAPPED a tray notification (background/terminated) → store it in the
  /// inbox, then deep-link to the screen the dashboard chose. data['route']
  /// carries a go_router PATH (e.g. '/offers', '/maintenance', '/tracking').
  static Future<void> _handleOpen(RemoteMessage m) async {
    await _storeOnly(m);
    _navigateTo(resolveRoute(m.data));
  }

  /// The go_router path a push opens. Current backends send it ready-made in
  /// data['route'] ('/models?slug=…', '/offers?slug=…', '/tracking?kind=…&ref=…').
  /// Older payloads carried a NAME instead of a path — mapped here so those
  /// taps still land on the right screen:
  ///   new_car                              → /models?slug=<slug>
  ///   orders_tracking / maintenance_tracking → /tracking?kind=<kind>&ref=<refNo|orderId>
  static String? resolveRoute(Map<String, dynamic> data) {
    final route = data['route']?.toString().trim() ?? '';
    if (route.startsWith('/')) return route;
    String q(String k) => Uri.encodeQueryComponent(data[k]?.toString().trim() ?? '');
    switch (route) {
      case 'new_car':
        final slug = q('slug');
        return slug.isEmpty ? '/models' : '/models?slug=$slug';
      case 'orders_tracking':
        final kind = q('kind'), ref = q('refNo');
        return '/tracking?kind=$kind&ref=$ref';
      case 'maintenance_tracking':
        return '/tracking?kind=maintenance&ref=${q('orderId')}';
      case 'offer':
        return '/offers';
      default:
        return null;
    }
  }

  /// Opens an inbox item's target screen (same handling as a push tap).
  static void openRoute(String? route) => _navigateTo(route);

  /// Navigate to a notification's target screen. Only app PATHS (leading '/')
  /// are followed; any other value (or none) just leaves the app on its normal
  /// start screen. Deferred to after the first frame so the router + shell are
  /// mounted even on a cold start (getInitialMessage).
  static void _navigateTo(String? route) {
    if (route == null || !route.startsWith('/')) return;
    final path = route; // non-null, captured for the deferred closure
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        final router = sl<GoRouter>();
        // Already ON this exact location (the same push tapped again):
        // go() would be a no-op and the item's sheet would not reopen. A
        // throwaway query param changes the screen's query key so its
        // ?slug= / ?guid= handling runs again.
        final current = router.routerDelegate.currentConfiguration.uri;
        final target = current.toString() == path
            ? '$path${path.contains('?') ? '&' : '?'}'
                '_t=${DateTime.now().millisecondsSinceEpoch}'
            : path;
        router.go(target);
      } catch (_) {/* unknown/guarded route — ignore, app stays where it is */}
    });
    // A post-frame callback alone doesn't schedule a frame — on an idle
    // screen (nothing animating) it would never run.
    WidgetsBinding.instance.ensureVisualUpdate();
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
      payload: n.route, // so tapping the foreground notification deep-links too
    );
  }

  /// The account this device's token is currently registered to (null = none).
  static int? _registeredUserId;

  /// Last successful POST /api/user/token on THIS install, as
  /// 'userId|brand|token' — survives restarts, so "does this device
  /// have a registered token?" is answered without a server round-trip.
  static const _registeredKey = 'push_registered_token';

  /// True when this device's CURRENT FCM token is registered for the
  /// signed-in user (a rotated token or another account counts as not).
  static Future<bool> hasRegisteredToken() async {
    if (!_ready) return false;
    final user = sl<AuthBloc>().state.user;
    if (user == null || user.userId <= 0) return false;
    try {
      final saved =
          (await SharedPreferences.getInstance()).getString(_registeredKey);
      if (saved == null) return false;
      final token = await FirebaseMessaging.instance
          .getToken()
          .timeout(const Duration(seconds: 10));
      return token != null && saved == '${user.userId}|$appBrand|$token';
    } catch (_) {
      return false;
    }
  }

  /// Safety net for the welcome swipe CTA: registers this device only if it
  /// has no registered token yet. Fire-and-forget — never delays navigation.
  static Future<void> ensureRegistered() async {
    if (_syncing != null) return; // a registration is already running
    if (await hasRegisteredToken()) return;
    await syncToken();
  }

  /// Registers THIS device's token for the signed-in user. The backend keeps
  /// one row per device (App_UserDevices, unique per token), so every device
  /// the user signs in on receives their pushes — not only the last one.
  static Future<void> syncToken() {
    // One sync at a time — sign-in, resume and token-refresh can fire
    // together. A request arriving mid-sync (e.g. sign-in while the startup
    // sync is retrying) queues exactly one more pass, so it's never lost.
    if (_syncing != null) {
      _syncAgain = true;
      return _syncing!;
    }
    return _syncing = _syncLoop();
  }

  static Future<void>? _syncing;
  static bool _syncAgain = false;

  static Future<void> _syncLoop() async {
    try {
      do {
        _syncAgain = false;
        await _syncOnce();
      } while (_syncAgain);
    } finally {
      _syncing = null;
    }
  }

  /// Fetches the FCM token with retries: right after install/sign-in it can be
  /// null or throw briefly (Play services warming up; on iOS the APNs token
  /// arrives a moment after the permission prompt). A single silent failure
  /// used to leave the phone unregistered until the next sign-in.
  static Future<String?> _fetchToken() async {
    Object? lastError;
    for (var attempt = 0; attempt < 5; attempt++) {
      try {
        if (Platform.isIOS &&
            await FirebaseMessaging.instance.getAPNSToken() == null) {
          throw StateError('APNs token not available yet');
        }
        // Bounded: a phone with broken Google services can hang here forever.
        final token = await FirebaseMessaging.instance
            .getToken()
            .timeout(const Duration(seconds: 20));
        if (token != null && token.isNotEmpty) return token;
      } catch (e) {
        lastError = e;
        debugPrint('FCM getToken attempt ${attempt + 1} failed: $e');
      }
      await Future<void>.delayed(Duration(seconds: 2 * (attempt + 1)));
    }
    _diag('token_unavailable', lastError ?? 'getToken returned null');
    return null;
  }

  static Future<void> _syncOnce() async {
    if (!_ready) return;
    final user = sl<AuthBloc>().state.user;
    if (user == null || user.userId <= 0) return;
    try {
      final token = await _fetchToken();
      if (token == null) return;
      // Still the same signed-in user after the retries?
      if (sl<AuthBloc>().state.user?.userId != user.userId) return;
      // <dynamic>: a non-JSON-object reply must not fail a stored registration.
      final res = await sl<ApiClient>().post<dynamic>(
        ApiPaths.fcmToken,
        // brand routes brand-specific pushes (a Toyota car's updates must
        // reach the Toyota app, not Lexus) — App_UserDevices.Brand.
        body: {
          'userId': user.userId,
          'token': token,
          'brand': appBrand,
          'platform': Platform.isIOS ? 'ios' : 'android',
        },
      );
      // ApiClient returns every <500 status as data — a rejected
      // registration (400/404…) must not be recorded as "registered".
      final code = res.statusCode ?? 0;
      if (code < 200 || code >= 300) {
        throw StateError('HTTP $code ${res.data ?? ''}');
      }
      _registeredUserId = user.userId;
      await (await SharedPreferences.getInstance())
          .setString(_registeredKey, '${user.userId}|$appBrand|$token');
      _diag('registered');
      // Signed out while the request was in flight → detach it again, or
      // this device keeps receiving the signed-out user's pushes.
      if (sl<AuthBloc>().state.user?.userId != user.userId) await _unregister();
    } catch (e) {
      debugPrint('FCM token sync failed: $e');
      _diag('register_failed', e);
    }
  }

  /// Sign-out: remove this device's token from the account it was registered
  /// to. Brand topics ('all' / 'toyota' / 'lexus') stay subscribed, so the
  /// device still gets general broadcasts as a guest.
  static Future<void> _unregister() async {
    final userId = _registeredUserId;
    _registeredUserId = null;
    if (!_ready || userId == null) return;
    try {
      await (await SharedPreferences.getInstance()).remove(_registeredKey);
      final token = await FirebaseMessaging.instance
          .getToken()
          .timeout(const Duration(seconds: 20));
      if (token == null) return;
      final res = await sl<ApiClient>().post<dynamic>(
        ApiPaths.fcmTokenUnregister,
        body: {'userId': userId, 'token': token},
      );
      final code = res.statusCode ?? 0;
      if (code < 200 || code >= 300) {
        debugPrint('FCM token unregister rejected: HTTP $code');
      }
    } catch (e) {
      debugPrint('FCM token unregister failed: $e');
    }
  }
}

@pragma('vm:entry-point')
Future<void> _backgroundHandler(RemoteMessage message) async {
  // Data-only messages in background are shown by the system tray via the
  // notification block the backend includes; nothing to do here.
}

/* ───────────────────────── Inbox sheet ───────────────────────── */

/// One row of the SERVER inbox (dbo.siteUserNotifications): broadcast rows
/// (ToAll=1) + rows addressed to this Web_UserID, served paged by
/// /api/app/account/notifications-feed.
final class ServerNotification {
  const ServerNotification({
    required this.id,
    this.titleAr,
    this.titleEn,
    this.contentAr,
    this.contentEn,
    this.type,
    this.date,
    this.targetRoute,
  });

  final int id;
  final String? titleAr;
  final String? titleEn;
  final String? contentAr;
  final String? contentEn;
  final String? type;
  final DateTime? date;

  /// App path this item opens on tap ('/models?slug=…', '/offers?slug=…',
  /// '/tracking?kind=…&ref=…'); null/blank = informational only.
  final String? targetRoute;
  bool get tappable => (targetRoute ?? '').trim().startsWith('/');

  String title(String lang) =>
      (lang == 'ar' ? titleAr : titleEn) ?? titleEn ?? titleAr ?? '';
  String body(String lang) =>
      (lang == 'ar' ? contentAr : contentEn) ?? contentEn ?? contentAr ?? '';

  factory ServerNotification.fromJson(Map<String, dynamic> j) =>
      ServerNotification(
        id: int.tryParse('${j['notifyId'] ?? 0}') ?? 0,
        titleAr: j['titleAr']?.toString(),
        titleEn: j['titleEn']?.toString(),
        contentAr: j['contentAr']?.toString(),
        contentEn: j['contentEn']?.toString(),
        type: j['alertType']?.toString(),
        date: DateTime.tryParse('${j['createdDate'] ?? ''}'),
        targetRoute: j['targetRoute']?.toString(),
      );

  /// Icon by the ops NotificationType (service update / appointment /
  /// agreement / offer …) — keyword-matched so new types degrade gracefully.
  IconData get icon {
    final t = '${type ?? ''} $titleEn'.toLowerCase();
    if (t.contains('offer')) return Icons.local_offer_outlined;
    if (t.contains('agreement') || t.contains('repair')) {
      return Icons.description_outlined;
    }
    if (t.contains('today') || t.contains('appointment')) {
      return Icons.event_available_rounded;
    }
    if (t.contains('service')) return Icons.car_repair_rounded;
    return Icons.notifications_active_outlined;
  }
}

void showNotificationsSheet(BuildContext context) {
  sl<NotificationsCubit>().markAllRead();
  showHeroBottomSheet<void>(
    context,
    heightFactor: 0.85,
    builder: (_) => const _NotificationsView(),
  );
}

final class _NotificationsView extends StatefulWidget {
  const _NotificationsView();

  @override
  State<_NotificationsView> createState() => _NotificationsViewState();
}

final class _NotificationsViewState extends State<_NotificationsView> {
  static const _pageSize = 20;

  final _scroll = ScrollController();
  final List<ServerNotification> _items = [];
  int _page = 0;
  bool _loading = false;
  bool _exhausted = false;
  bool _firstLoadDone = false;

  @override
  void initState() {
    super.initState();
    _loadMore();
    // Infinite scroll: fetch the next page as the user nears the bottom —
    // history can be long, so it is never loaded in one shot.
    _scroll.addListener(() {
      if (_scroll.position.extentAfter < 400) _loadMore();
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _loadMore() async {
    if (_loading || _exhausted) return;
    setState(() => _loading = true);
    final userId = sl<AuthBloc>().state.user?.userId ?? 0;
    try {
      final res = await sl<ApiClient>().get<List<dynamic>>(
        '/api/app/account/notifications-feed',
        query: {'userId': userId, 'page': _page, 'pageSize': _pageSize},
      );
      final rows = (res.data ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(ServerNotification.fromJson)
          .where((n) => n.title('ar').isNotEmpty || n.body('ar').isNotEmpty)
          .toList();
      if (!mounted) return;
      setState(() {
        _items.addAll(rows);
        _page += 1;
        _exhausted = rows.length < _pageSize;
        _loading = false;
        _firstLoadDone = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _exhausted = true;
        _firstLoadDone = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final lang = context.watch<LocaleCubit>().state.languageCode;

    return Material(
      color: scheme.surface,
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                  context.rs(20), context.rs(10), context.rs(20), 0),
              child: Column(children: [
                const SheetHandle(),
                SizedBox(height: context.rs(12)),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(t.notifTitle,
                      style: TextStyle(
                          fontSize: context.rf(18),
                          fontWeight: FontWeight.w800)),
                ),
              ]),
            ),
            Expanded(
              child: !_firstLoadDone
                  ? const Center(
                      child: SizedBox(
                          width: 26,
                          height: 26,
                          child: CircularProgressIndicator(strokeWidth: 2.6)))
                  : _items.isEmpty
                      ? AppEmptyState(
                          icon: Icons.notifications_none_rounded,
                          title: t.notifEmpty,
                          compact: true,
                        )
                      : ListView.separated(
                          controller: _scroll,
                          padding: EdgeInsets.all(context.rs(16)),
                          itemCount: _items.length + (_exhausted ? 0 : 1),
                          separatorBuilder: (_, _) =>
                              SizedBox(height: context.rs(8)),
                          itemBuilder: (context, i) {
                            if (i >= _items.length) {
                              // Tail loader while the next page streams in.
                              return Padding(
                                padding: EdgeInsets.all(context.rs(14)),
                                child: const Center(
                                  child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2.2)),
                                ),
                              );
                            }
                            final n = _items[i];
                            return _NotificationTile(
                                n: n, lang: lang, scheme: scheme);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _NotificationTile extends StatelessWidget {
  const _NotificationTile(
      {required this.n, required this.lang, required this.scheme});

  final ServerNotification n;
  final String lang;
  final ColorScheme scheme;

  String _when(DateTime? d, String lang) {
    if (d == null) return '';
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 60) {
      return lang == 'ar' ? 'منذ ${diff.inMinutes} دقيقة' : '${diff.inMinutes}m ago';
    }
    if (diff.inHours < 24) {
      return lang == 'ar' ? 'منذ ${diff.inHours} ساعة' : '${diff.inHours}h ago';
    }
    if (diff.inDays < 7) {
      return lang == 'ar' ? 'منذ ${diff.inDays} يوم' : '${diff.inDays}d ago';
    }
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tile = Container(
      padding: EdgeInsets.all(context.rs(12)),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF181B21) : const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: context.rs(36),
            height: context.rs(36),
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: isDark ? 0.18 : 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(n.icon, size: 17, color: scheme.primary),
          ),
          SizedBox(width: context.rs(10)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(
                    child: Text(n.title(lang),
                        style: TextStyle(
                            fontSize: context.rf(12.5),
                            fontWeight: FontWeight.w800)),
                  ),
                  SizedBox(width: context.rs(8)),
                  Text(
                    _when(n.date, lang),
                    style: TextStyle(
                        fontSize: context.rf(9.5),
                        color: scheme.onSurface.withValues(alpha: 0.45)),
                  ),
                ]),
                if (n.body(lang).isNotEmpty) ...[
                  SizedBox(height: context.rs(3)),
                  Text(n.body(lang),
                      style: TextStyle(
                          fontSize: context.rf(11.5),
                          height: 1.45,
                          color:
                              scheme.onSurface.withValues(alpha: 0.65))),
                ],
              ],
            ),
          ),
          if (n.tappable) ...[
            SizedBox(width: context.rs(6)),
            Padding(
              padding: EdgeInsets.only(top: context.rs(9)),
              child: Icon(Icons.chevron_right_rounded,
                  size: 20, color: scheme.onSurface.withValues(alpha: 0.35)),
            ),
          ],
        ],
      ),
    );
    if (!n.tappable) return tile;
    // Tap → close the inbox and open the item (new car / offer / order).
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.of(context).maybePop();
          PushService.openRoute(n.targetRoute!.trim());
        },
        child: tile,
      ),
    );
  }
}
