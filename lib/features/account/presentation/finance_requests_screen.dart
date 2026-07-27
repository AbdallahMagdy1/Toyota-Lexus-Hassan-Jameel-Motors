import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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

/// One finance request + its tracker (website Site_FinanceRequests_ForCustomer).
final class FinanceRequest extends Equatable {
  const FinanceRequest({
    this.guid,
    this.orderId,
    this.createdDate,
    this.vehicleNameAr,
    this.vehicleNameEn,
    this.modelYear,
    this.bankNameAr,
    this.bankNameEn,
    this.bankLogo,
    this.monthlyAmount,
    this.firstPayment,
    this.period,
    this.status,
    this.rejectReason,
    this.approveNote,
    this.events = const [],
  });

  final String? guid;
  final int? orderId;
  final DateTime? createdDate;
  final String? vehicleNameAr;
  final String? vehicleNameEn;
  final String? modelYear;
  final String? bankNameAr;
  final String? bankNameEn;
  final String? bankLogo;
  final double? monthlyAmount;
  final double? firstPayment;
  final int? period;
  final String? status; // Received|Contacting|SentToBank|Approved|Rejected
  final String? rejectReason;
  final String? approveNote;
  final List<({String? status, String? note, DateTime? createdAt})> events;

  /// The website's fixed track: Received → Contacting → SentToBank →
  /// Approved (Rejected = terminal off-ramp at the last node).
  static const stages = ['Received', 'Contacting', 'SentToBank', 'Approved'];

  int get stageIndex => switch (status) {
        'Contacting' => 1,
        'SentToBank' => 2,
        'Approved' || 'Rejected' => 3,
        _ => 0,
      };

  bool get rejected => status == 'Rejected';

  String vehicleName(String lang) =>
      (lang == 'ar' ? vehicleNameAr : vehicleNameEn) ??
      vehicleNameEn ??
      vehicleNameAr ??
      '';
  String bankName(String lang) =>
      (lang == 'ar' ? bankNameAr : bankNameEn) ?? bankNameEn ?? bankNameAr ?? '';

  factory FinanceRequest.fromJson(Map<String, dynamic> j) => FinanceRequest(
        guid: j['guid']?.toString(),
        orderId: (j['orderId'] as num?)?.toInt(),
        createdDate: DateTime.tryParse('${j['createdDate']}'),
        vehicleNameAr: j['vehicleNameAr']?.toString(),
        vehicleNameEn: j['vehicleNameEn']?.toString(),
        modelYear: j['modelYear']?.toString(),
        bankNameAr: j['bankNameAr']?.toString(),
        bankNameEn: j['bankNameEn']?.toString(),
        bankLogo: j['bankLogo']?.toString(),
        monthlyAmount: (j['monthlyAmount'] as num?)?.toDouble(),
        firstPayment: (j['firstPayment'] as num?)?.toDouble(),
        period: (j['period'] as num?)?.toInt(),
        status: j['status']?.toString(),
        rejectReason: j['rejectReason']?.toString(),
        approveNote: j['approveNote']?.toString(),
        events: ((j['events'] as List<dynamic>?) ?? [])
            .whereType<Map<String, dynamic>>()
            .map((e) => (
                  status: e['status']?.toString(),
                  note: e['note']?.toString(),
                  createdAt: DateTime.tryParse('${e['createdAt']}'),
                ))
            .toList(),
      );

  @override
  List<Object?> get props => [guid, status];
}

final class _State extends Equatable {
  const _State({this.loading = true, this.items = const []});

  final bool loading;
  final List<FinanceRequest> items;

  @override
  List<Object?> get props => [loading, items];
}

final class _Cubit extends Cubit<_State> {
  _Cubit() : super(const _State()) {
    load();
  }

  Future<void> load() async {
    emit(const _State());
    final user = sl<AuthBloc>().state.user;
    try {
      final res = await sl<ApiClient>().get<List<dynamic>>(
        ApiPaths.financeRequests,
        query: {
          'userId': ?user?.userId,
          if ((user?.phone ?? '').isNotEmpty) 'phone': user!.phone,
        },
      );
      final items = (res.data ?? [])
          .whereType<Map<String, dynamic>>()
          .map(FinanceRequest.fromJson)
          .toList();
      if (!isClosed) emit(_State(loading: false, items: items));
    } on DioException {
      if (!isClosed) emit(const _State(loading: false));
    }
  }
}

/// Finance requests tracker — the website's stepper + follow-up timeline.
final class FinanceRequestsScreen extends StatelessWidget {
  const FinanceRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => _Cubit(),
      child: const _View(),
    );
  }
}

final class _View extends StatelessWidget {
  const _View();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final state = context.watch<_Cubit>().state;
    final cubit = context.read<_Cubit>();
    final lang = context.watch<LocaleCubit>().state.languageCode;

    return Column(
      children: [
        const AppHeader(),
        Expanded(
          child: state.loading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: cubit.load,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(context.rs(16),
                        context.rs(18), context.rs(16), context.rs(110)),
                    children: [
                      Text(t.finReqTitle,
                          style: TextStyle(
                              fontSize: context.rf(24),
                              fontWeight: FontWeight.w800)),
                      SizedBox(height: context.rs(14)),
                      if (state.items.isEmpty)
                        Padding(
                          padding: EdgeInsets.all(context.rs(36)),
                          child: Center(child: Text(t.finReqEmpty)),
                        ),
                      for (final (i, r) in state.items.indexed)
                        Padding(
                          padding: EdgeInsets.only(bottom: context.rs(14)),
                          child: _RequestCard(request: r, lang: lang)
                              .animate(delay: (35 * (i % 4)).ms)
                              .fadeIn(duration: 220.ms),
                        ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}

final class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.request, required this.lang});

  final FinanceRequest request;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final r = request;
    final stageLabels = [
      t.finStageReceived,
      t.finStageContacting,
      t.finStageSentToBank,
      r.rejected ? t.finStageRejected : t.finStageApproved,
    ];

    return Container(
      padding: EdgeInsets.all(context.rs(16)),
      decoration: softCardDecoration(context,
          tint: r.rejected ? scheme.error : scheme.primary),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            if ((r.bankLogo ?? '').isNotEmpty)
              SizedBox(
                width: context.rs(38),
                height: context.rs(38),
                child: HomeImage(
                    url: r.bankLogo, fit: BoxFit.contain, logicalWidth: 38),
              ),
            SizedBox(width: context.rs(10)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${r.vehicleName(lang)} ${r.modelYear ?? ''}'.trim(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: context.rf(13.5),
                        fontWeight: FontWeight.w800,
                        height: 1.3),
                  ),
                  Text(
                    [
                      r.bankName(lang),
                      if (r.orderId != null) '#${r.orderId}',
                    ].join(' · '),
                    style: TextStyle(
                        fontSize: context.rf(11),
                        color: scheme.onSurface.withValues(alpha: 0.55)),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(
                  horizontal: context.rs(10), vertical: context.rs(4)),
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
                stageLabels[r.stageIndex],
                style: TextStyle(
                  fontSize: context.rf(10),
                  fontWeight: FontWeight.w800,
                  color: r.rejected
                      ? scheme.error
                      : r.status == 'Approved'
                          ? const Color(0xFF1E9E5A)
                          : scheme.primary,
                ),
              ),
            ),
          ]),
          SizedBox(height: context.rs(14)),

          // Stepper.
          Row(children: [
            for (var s = 0; s < stageLabels.length; s++) ...[
              Container(
                width: context.rs(16),
                height: context.rs(16),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: s <= r.stageIndex
                      ? (s == 3 && r.rejected ? scheme.error : scheme.primary)
                      : scheme.outline.withValues(alpha: 0.4),
                ),
                child: s < r.stageIndex ||
                        (s == r.stageIndex && r.status == 'Approved')
                    ? Icon(Icons.check, size: 10, color: scheme.onPrimary)
                    : (s == 3 && r.rejected
                        ? Icon(Icons.close, size: 10, color: scheme.onError)
                        : null),
              ),
              if (s < stageLabels.length - 1)
                Expanded(
                  child: Container(
                    height: 2.2,
                    color: s < r.stageIndex
                        ? scheme.primary
                        : scheme.outline.withValues(alpha: 0.35),
                  ),
                ),
            ],
          ]),
          SizedBox(height: context.rs(5)),
          Row(children: [
            for (var s = 0; s < stageLabels.length; s++)
              Expanded(
                child: Text(
                  stageLabels[s],
                  textAlign: s == 0
                      ? TextAlign.start
                      : s == stageLabels.length - 1
                          ? TextAlign.end
                          : TextAlign.center,
                  style: TextStyle(
                    fontSize: context.rf(8.5),
                    fontWeight:
                        s == r.stageIndex ? FontWeight.w800 : FontWeight.w600,
                    color: s <= r.stageIndex
                        ? (s == 3 && r.rejected
                            ? scheme.error
                            : scheme.primary)
                        : scheme.onSurface.withValues(alpha: 0.45),
                  ),
                ),
              ),
          ]),

          if (r.rejected && (r.rejectReason ?? '').isNotEmpty) ...[
            SizedBox(height: context.rs(10)),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(context.rs(10)),
              decoration: BoxDecoration(
                color: scheme.error.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('${t.finReqReason}: ${r.rejectReason}',
                  style: TextStyle(
                      fontSize: context.rf(11.5), color: scheme.error)),
            ),
          ],
          if ((r.monthlyAmount ?? 0) > 0) ...[
            SizedBox(height: context.rs(10)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(t.finEstMonthly,
                    style: TextStyle(
                        fontSize: context.rf(11.5),
                        color: scheme.onSurface.withValues(alpha: 0.6))),
                PriceText(
                    price: r.monthlyAmount,
                    currency: '',
                    contactForPrice: '',
                    fontSize: context.rf(13)),
              ],
            ),
          ],

          // Follow-up timeline (the website's سجل المتابعة).
          if (r.events.isNotEmpty) ...[
            SizedBox(height: context.rs(12)),
            Text(t.finReqTimeline,
                style: TextStyle(
                    fontSize: context.rf(12), fontWeight: FontWeight.w800)),
            SizedBox(height: context.rs(8)),
            for (final e in r.events)
              Padding(
                padding: EdgeInsets.only(bottom: context.rs(6)),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(top: context.rs(4)),
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: scheme.primary,
                        ),
                      ),
                    ),
                    SizedBox(width: context.rs(8)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            [
                              _stageLabel(context, e.status),
                              if ((e.note ?? '').isNotEmpty) e.note!,
                            ].join(' — '),
                            style: TextStyle(
                                fontSize: context.rf(11.5),
                                fontWeight: FontWeight.w700),
                          ),
                          if (e.createdAt != null)
                            Text(
                              e.createdAt!
                                  .toIso8601String()
                                  .substring(0, 16)
                                  .replaceAll('T', ' '),
                              textDirection: TextDirection.ltr,
                              style: TextStyle(
                                  fontSize: context.rf(9.5),
                                  color: scheme.onSurface
                                      .withValues(alpha: 0.5)),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }

  static String _stageLabel(BuildContext context, String? status) {
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
}
