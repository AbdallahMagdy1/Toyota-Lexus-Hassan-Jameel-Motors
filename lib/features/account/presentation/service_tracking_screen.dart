import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/api_paths.dart';
import '../../../core/di/injector.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/responsive.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/app_header.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../home/presentation/widgets/home_bits.dart';
import '../../settings/bloc/locale_cubit.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../data/account_repository.dart';
import '../domain/account_models.dart';
import 'finance_requests_screen.dart' show FinanceRequest;
import 'registered_home_view.dart' show WorkOrderCard;

/// Live service tracking — the old app's cycle rebuilt: initial snapshot
/// from /account/work-orders, then a live SSE stream (SQL trigger →
/// broadcaster → this screen). Falls back to a 30s refresh if the stream
/// drops; the backend stays the single source of state.
final class ServiceTrackingScreen extends StatelessWidget {
  const ServiceTrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => _TrackingCubit(),
      child: const _View(),
    );
  }
}

final class _TrackingState extends Equatable {
  const _TrackingState({
    this.loading = true,
    this.orders = const [],
    this.live = false,
  });

  final bool loading;
  final List<WorkOrder> orders;
  final bool live; // SSE stream connected

  @override
  List<Object?> get props => [loading, orders, live];
}

/// Bumped on every live SSE event so the orders-tracking hub refetches.
final ValueNotifier<int> _hubRefresh = ValueNotifier(0);

final class _TrackingCubit extends Cubit<_TrackingState> {
  _TrackingCubit() : super(const _TrackingState()) {
    _custId = sl<AuthBloc>().state.user?.custId ?? '';
    _userId = sl<AuthBloc>().state.user?.userId ?? 0;
    _load();
    _listen();
    // Safety net: refresh the snapshot periodically if the stream is down.
    _poll = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!state.live && !isClosed) _load();
    });
  }

  late final String _custId;
  late final int _userId;
  Timer? _poll;
  CancelToken? _sse;

  Future<void> _load() async {
    if (_custId.isEmpty) {
      emit(const _TrackingState(loading: false));
      return;
    }
    try {
      final res = await sl<ApiClient>().get<List<dynamic>>(
        '/api/app/account/work-orders',
        query: {'custId': _custId},
      );
      if (isClosed) return;
      emit(_TrackingState(
        loading: false,
        orders: (res.data ?? [])
            .whereType<Map<String, dynamic>>()
            .map(WorkOrder.fromJson)
            .toList(),
        live: state.live,
      ));
    } on DioException {
      if (!isClosed) emit(_TrackingState(loading: false, live: state.live));
    }
  }

  /// SSE: parse `data: {...}` lines; each update refreshes the snapshot so
  /// the card always renders authoritative backend state.
  Future<void> _listen() async {
    if (_custId.isEmpty) return;
    while (!isClosed) {
      _sse = CancelToken();
      try {
        final res = await sl<ApiClient>().dio.get<ResponseBody>(
              ApiPaths.trackingStream,
              queryParameters: {
                'custId': _custId,
                if (_userId > 0) 'userId': _userId,
              },
              cancelToken: _sse,
              options: Options(
                responseType: ResponseType.stream,
                receiveTimeout: Duration.zero,
              ),
            );
        if (isClosed) return;
        emit(_TrackingState(
            loading: false, orders: state.orders, live: true));
        final stream = utf8.decoder
            .bind(res.data!.stream)
            .transform(const LineSplitter());
        await for (final line in stream) {
          if (isClosed) return;
          if (!line.startsWith('data:')) continue;
          try {
            final j =
                jsonDecode(line.substring(5).trim()) as Map<String, dynamic>;
            final kind = (j['kind'] ?? 'workorder').toString();
            // Any cycle event refreshes the tracking hub live.
            _hubRefresh.value++;
            if (kind == 'workorder') {
              // Re-pull the snapshot (authoritative), then ack the update.
              await _load();
              final orderId = j['maintenanceOrderId']?.toString();
              if (orderId != null) {
                await sl<ApiClient>().dio.post<Map<String, dynamic>>(
                  '/api/app/tracking/ack',
                  queryParameters: {'custId': _custId, 'orderId': orderId},
                );
              }
            }
          } catch (_) {}
        }
      } catch (_) {
        // stream dropped — retry with backoff
      }
      if (isClosed) return;
      emit(_TrackingState(loading: false, orders: state.orders, live: false));
      await Future<void>.delayed(const Duration(seconds: 8));
    }
  }

  @override
  Future<void> close() {
    _poll?.cancel();
    _sse?.cancel();
    return super.close();
  }
}

final class _View extends StatelessWidget {
  const _View();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final state = context.watch<_TrackingCubit>().state;
    final lang = context.watch<LocaleCubit>().state.languageCode;
    final scheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        const AppHeader(),
        Expanded(
          child: state.loading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: EdgeInsets.fromLTRB(context.rs(16), context.rs(18),
                      context.rs(16), context.rs(110)),
                  children: [
                    Row(children: [
                      Expanded(
                        child: Text(t.trackTitle,
                            style: TextStyle(
                                fontSize: context.rf(24),
                                fontWeight: FontWeight.w800)),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: context.rs(9),
                            vertical: context.rs(4)),
                        decoration: BoxDecoration(
                          color: (state.live
                                  ? const Color(0xFF1E9E5A)
                                  : scheme.onSurface)
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: state.live
                                  ? const Color(0xFF1E9E5A)
                                  : scheme.onSurface
                                      .withValues(alpha: 0.4),
                            ),
                          ),
                          SizedBox(width: context.rs(5)),
                          Text(
                            state.live ? t.trackLive : t.trackReconnecting,
                            style: TextStyle(
                                fontSize: context.rf(9.5),
                                fontWeight: FontWeight.w800,
                                color: state.live
                                    ? const Color(0xFF1E9E5A)
                                    : scheme.onSurface
                                        .withValues(alpha: 0.55)),
                          ),
                        ]),
                      ),
                    ]),
                    SizedBox(height: context.rs(14)),
                    if (state.orders.isEmpty)
                      Padding(
                        padding: EdgeInsets.all(context.rs(40)),
                        child: Column(children: [
                          Icon(Icons.car_repair_rounded,
                              size: 44,
                              color: scheme.onSurface.withValues(alpha: 0.25)),
                          SizedBox(height: context.rs(10)),
                          Text(t.trackEmpty,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: context.rf(13),
                                  color: scheme.onSurface
                                      .withValues(alpha: 0.55))),
                        ]),
                      ),
                    for (final o in state.orders)
                      Padding(
                        padding: EdgeInsets.only(bottom: context.rs(14)),
                        child: WorkOrderCard(order: o, lang: lang),
                      ),

                    // ── متابعة الطلبات: الصيانة / الحماية / طلباتي ──
                    SizedBox(height: context.rs(10)),
                    const _OrdersTrackingSection(),
                  ],
                ),
        ),
      ],
    );
  }
}


/// متابعة الطلبات — the unified tracker over the three cycles
/// (App_Orders_TrackingSnapshot): kind filter chips, stage progress per
/// order, status chip and payment shortcuts (Sadad / pay URL).
final class _OrdersTrackingSection extends StatefulWidget {
  const _OrdersTrackingSection();

  @override
  State<_OrdersTrackingSection> createState() => _OrdersTrackingSectionState();
}

final class _OrdersTrackingSectionState extends State<_OrdersTrackingSection> {
  Future<List<TrackedOrder>>? _future;
  Future<List<FinanceRequest>>? _finFuture;
  int _tab = 0; // 0 all, 1 maintenance, 2 protection, 3 order, 4 finance

  @override
  void initState() {
    super.initState();
    _refetch();
    // Live SSE events bump this — the hub refetches instantly.
    _hubRefresh.addListener(_refetch);
  }

  @override
  void dispose() {
    _hubRefresh.removeListener(_refetch);
    super.dispose();
  }

  static Future<List<FinanceRequest>> _fetchFinance() async {
    final user = sl<AuthBloc>().state.user;
    if (user == null) return const [];
    try {
      final res = await sl<ApiClient>().get<List<dynamic>>(
        ApiPaths.financeRequests,
        query: {
          'userId': user.userId,
          if ((user.phone ?? '').isNotEmpty) 'phone': user.phone,
        },
      );
      return (res.data ?? [])
          .whereType<Map<String, dynamic>>()
          .map(FinanceRequest.fromJson)
          .toList();
    } on DioException {
      return const [];
    }
  }

  void _refetch() {
    final user = sl<AuthBloc>().state.user;
    if (user == null) return;
    setState(() {
      _future = AccountRepository(sl<ApiClient>())
          .ordersTracking(userId: user.userId, custId: user.custId);
      _finFuture = _fetchFinance();
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final lang = context.watch<LocaleCubit>().state.languageCode;
    final scheme = Theme.of(context).colorScheme;
    if (_future == null) return const SizedBox.shrink();

    return FutureBuilder<List<TrackedOrder>>(
      future: _future,
      builder: (context, snap) {
        final all = snap.data ?? const <TrackedOrder>[];
        final filtered = switch (_tab) {
          1 => all.where((o) => o.kind == 'maintenance').toList(),
          2 => all.where((o) => o.kind == 'protection').toList(),
          3 => all.where((o) => o.kind == 'order').toList(),
          _ => all,
        };

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(bottom: context.rs(10)),
              child: Text(t.trkHubTitle,
                  style: TextStyle(
                      fontSize: context.rf(17), fontWeight: FontWeight.w800)),
            ),
            Wrap(spacing: 8, children: [
              for (final (i, label) in [
                t.trkAll,
                t.trkKindMaintenance,
                t.trkKindProtection,
                t.trkKindOrders,
                t.trkKindFinance,
              ].indexed)
                ChoiceChip(
                  label: Text(label,
                      style: TextStyle(fontSize: context.rf(11))),
                  selected: i == _tab,
                  onSelected: (_) => setState(() => _tab = i),
                ),
            ]),
            SizedBox(height: context.rs(12)),
            if (_tab == 4)
              _FinanceMiniList(future: _finFuture)
            else if (snap.connectionState != ConnectionState.done)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (filtered.isEmpty)
              Padding(
                padding: EdgeInsets.all(context.rs(24)),
                child: Center(
                  child: Text(t.trkHubEmpty,
                      style: TextStyle(
                          fontSize: context.rf(12),
                          color: scheme.onSurface.withValues(alpha: 0.55))),
                ),
              )
            else
              for (final o in filtered.take(20))
                Padding(
                  padding: EdgeInsets.only(bottom: context.rs(10)),
                  child: _TrackedOrderCard(order: o, lang: lang),
                ),
          ],
        );
      },
    );
  }
}

/// Compact finance-request cards inside the tracking hub (التمويل chip).
/// Tapping opens the full finance tracker screen.
final class _FinanceMiniList extends StatelessWidget {
  const _FinanceMiniList({required this.future});

  final Future<List<FinanceRequest>>? future;

  static String _label(BuildContext context, String? status) {
    final t = AppLocalizations.of(context);
    return switch (status) {
      'Received' => t.finStageReceived,
      'Contacting' => t.finStageContacting,
      'SentToBank' => t.finStageSentToBank,
      'Approved' => t.finStageApproved,
      'Rejected' => t.finStageRejected,
      _ => status ?? '',
    };
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final lang = context.watch<LocaleCubit>().state.languageCode;
    final scheme = Theme.of(context).colorScheme;

    return FutureBuilder<List<FinanceRequest>>(
      future: future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final items = snap.data ?? const <FinanceRequest>[];
        if (items.isEmpty) {
          return Padding(
            padding: EdgeInsets.all(context.rs(24)),
            child: Center(
              child: Text(t.trkHubEmpty,
                  style: TextStyle(
                      fontSize: context.rf(12),
                      color: scheme.onSurface.withValues(alpha: 0.55))),
            ),
          );
        }
        return Column(
          children: [
            for (final r in items.take(10))
              Padding(
                padding: EdgeInsets.only(bottom: context.rs(10)),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => context.go(Routes.financeRequests),
                  child: Container(
                    padding: EdgeInsets.all(context.rs(14)),
                    decoration: softCardDecoration(context, radius: 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: context.rs(36),
                              height: context.rs(36),
                              decoration: BoxDecoration(
                                color:
                                    scheme.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(Icons.account_balance_rounded,
                                  size: 18, color: scheme.primary),
                            ),
                            SizedBox(width: context.rs(10)),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    r.vehicleName(lang),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        fontSize: context.rf(12.5),
                                        fontWeight: FontWeight.w800),
                                  ),
                                  Text(
                                    r.bankName(lang),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: context.rf(10.5),
                                      color: scheme.onSurface
                                          .withValues(alpha: 0.55),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: context.rs(9),
                                  vertical: context.rs(4)),
                              decoration: BoxDecoration(
                                color: (r.rejected
                                        ? scheme.error
                                        : r.status == 'Approved'
                                            ? const Color(0xFF1E9E5A)
                                            : scheme.primary)
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                _label(context, r.status),
                                style: TextStyle(
                                  fontSize: context.rf(9.5),
                                  fontWeight: FontWeight.w800,
                                  color: r.rejected
                                      ? scheme.error
                                      : r.status == 'Approved'
                                          ? const Color(0xFF1E9E5A)
                                          : scheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: context.rs(10)),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: LinearProgressIndicator(
                            value: (r.stageIndex + 1) /
                                FinanceRequest.stages.length,
                            minHeight: 5,
                            backgroundColor:
                                scheme.onSurface.withValues(alpha: 0.08),
                            color: r.rejected
                                ? scheme.error
                                : scheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

final class _TrackedOrderCard extends StatelessWidget {
  const _TrackedOrderCard({required this.order, required this.lang});

  final TrackedOrder order;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final o = order;
    final icon = switch (o.kind) {
      'maintenance' => Icons.event_available_rounded,
      'protection' => Icons.shield_outlined,
      _ => Icons.local_shipping_outlined,
    };
    final date = o.orderDate?.toIso8601String().substring(0, 10) ?? '';
    final progress =
        o.stageCount <= 1 ? 1.0 : (o.stageIndex + 1) / o.stageCount;

    return Container(
      padding: EdgeInsets.all(context.rs(14)),
      decoration: softCardDecoration(context,
          radius: 18, tint: o.needsPayment ? scheme.primary : null),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: context.rs(34),
              height: context.rs(34),
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.09),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 16, color: scheme.primary),
            ),
            SizedBox(width: context.rs(10)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(o.title(lang),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: context.rf(12.5),
                          fontWeight: FontWeight.w800)),
                  Text(
                    [if ((o.refNo ?? '').isNotEmpty) o.refNo!, date]
                        .where((s) => s.isNotEmpty)
                        .join(' • '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textDirection: TextDirection.ltr,
                    style: TextStyle(
                        fontSize: context.rf(9.5),
                        color: scheme.onSurface.withValues(alpha: 0.5)),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(
                  horizontal: context.rs(9), vertical: context.rs(4)),
              decoration: BoxDecoration(
                color: o.isTerminal
                    ? scheme.onSurface.withValues(alpha: 0.06)
                    : scheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                o.status(lang),
                style: TextStyle(
                    fontSize: context.rf(9),
                    fontWeight: FontWeight.w800,
                    color: o.isTerminal
                        ? scheme.onSurface.withValues(alpha: 0.55)
                        : scheme.primary),
              ),
            ),
          ]),
          if (!o.isTerminal) ...[
            SizedBox(height: context.rs(12)),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: scheme.onSurface.withValues(alpha: 0.08),
              ),
            ),
          ],
          if ((o.total ?? 0) > 0 || (o.sadadNumber ?? '').isNotEmpty) ...[
            SizedBox(height: context.rs(10)),
            Row(children: [
              if ((o.sadadNumber ?? '').isNotEmpty)
                Expanded(
                  child: Text('${t.acSadad}: ${o.sadadNumber}',
                      textDirection: TextDirection.ltr,
                      style: TextStyle(
                          fontSize: context.rf(10.5),
                          color: scheme.onSurface.withValues(alpha: 0.6))),
                )
              else
                const Spacer(),
              if ((o.total ?? 0) > 0)
                PriceText(
                    price: o.total,
                    currency: '',
                    contactForPrice: '',
                    fontSize: context.rf(13)),
            ]),
          ],
          if (o.needsPayment && (o.paymentUrl ?? '').isNotEmpty) ...[
            SizedBox(height: context.rs(10)),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(42),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                textStyle: TextStyle(
                    fontSize: context.rf(12), fontWeight: FontWeight.w800),
              ),
              onPressed: () => launchUrl(Uri.parse(o.paymentUrl!),
                  mode: LaunchMode.externalApplication),
              icon: const Icon(Icons.payments_outlined, size: 16),
              label: Text(t.jdPayNow),
            ),
          ],
        ],
      ),
    );
  }
}
