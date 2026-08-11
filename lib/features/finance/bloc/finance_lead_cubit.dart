import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../auth/domain/app_user.dart';
import '../../online_store/data/online_store_repository.dart';
import '../domain/finance_math.dart';
import '../domain/finance_models.dart';

enum FinanceLeadPhase { editing, busy, done, failed }

/// Website FinanceDocUploads keys — sent verbatim in the submit payload.
const kFinanceDocKinds = [
  'identityImage',
  'license',
  'salaryDefinitionLetter',
  'insurance',
  'accountStatement',
];

final class FinanceLeadState extends Equatable {
  const FinanceLeadState({
    this.phase = FinanceLeadPhase.editing,
    this.period = 60,
    this.advance,
    this.error = false,
    this.workType = '',
    this.docs = const {},
    this.docNames = const {},
    this.accepted = false,
    this.reference,
  });

  final FinanceLeadPhase phase;
  final int period;

  /// Optional down-payment override (null = bank's own advance rate).
  final double? advance;
  final bool error;

  /// جهة العمل — '' unset | 'private' | 'governmental' (website FinanceSector;
  /// unset by default, tap again to deselect).
  final String workType;

  /// Attached documents: kind -> base64 (no data-url prefix).
  final Map<String, String> docs;
  final Map<String, String> docNames;

  /// Privacy consent — the website's PrivacyConsent gate on submit.
  final bool accepted;

  /// Ticket number returned by the backend on success.
  final String? reference;

  FinanceLeadState copyWith({
    FinanceLeadPhase? phase,
    int? period,
    double? Function()? advance,
    bool? error,
    String? workType,
    Map<String, String>? docs,
    Map<String, String>? docNames,
    bool? accepted,
    String? Function()? reference,
  }) =>
      FinanceLeadState(
        phase: phase ?? this.phase,
        period: period ?? this.period,
        advance: advance == null ? this.advance : advance(),
        error: error ?? this.error,
        workType: workType ?? this.workType,
        docs: docs ?? this.docs,
        docNames: docNames ?? this.docNames,
        accepted: accepted ?? this.accepted,
        reference: reference == null ? this.reference : reference(),
      );

  @override
  List<Object?> get props => [
        phase, period, advance, error,
        workType, docs, docNames, accepted, reference,
      ];
}

/// The website's FinanceRequestModal: a live computeFinance estimate next to
/// a lead form, POSTing /online/finance-requests with source "FinancePage".
/// The bank FK travels via offerID (the bank's finance record), exactly like
/// the website. NOTE: the website removed the "Buying as" selector here —
/// finance-page applicants are always individuals (custType G4, national ID).
final class FinanceLeadCubit extends Cubit<FinanceLeadState> {
  FinanceLeadCubit({
    required this.bank,
    required this.car,
    required OnlineStoreRepository onlineRepo,
    required this.user,
    required String lang,
    required this.custGroups,
    int? initialPeriod,
  })  : _online = onlineRepo,
        super(FinanceLeadState(
          period: initialPeriod ?? bank.defaultFinancePeriod,
        )) {
    name.text = user?.displayName(lang) ?? '';
    phone.text = user?.phone ?? '';
    email.text = user?.email ?? '';
    advanceCtrl.addListener(() {
      final v = double.tryParse(advanceCtrl.text.trim());
      emit(state.copyWith(advance: () => (v ?? 0) > 0 ? v : null));
    });
  }

  final FinanceBank bank;
  final FinanceVehicle car;
  final OnlineStoreRepository _online;
  final AppUser? user;
  final List<FinanceCustGroup> custGroups;

  final name = TextEditingController();
  final phone = TextEditingController();
  final email = TextEditingController();
  final identity = TextEditingController();
  final income = TextEditingController();
  final advanceCtrl = TextEditingController();
  final note = TextEditingController();

  double get price => car.minPrice ?? 0;

  FinanceEstimate get estimate => computeFinance(
        price,
        bank,
        state.period > bank.maxFinancePeriod
            ? bank.maxFinancePeriod
            : state.period,
        customFirstPay: state.advance,
      );

  void selectPeriod(int p) => emit(state.copyWith(period: p));

  void setWorkType(String v) => emit(state.copyWith(workType: v));

  void setAccepted(bool v) => emit(state.copyWith(accepted: v));

  void setDoc(String kind, String? base64, String? fileName) {
    final docs = Map<String, String>.from(state.docs);
    final names = Map<String, String>.from(state.docNames);
    if (base64 == null || base64.isEmpty) {
      docs.remove(kind);
      names.remove(kind);
    } else {
      docs[kind] = base64;
      names[kind] = fileName ?? kind;
    }
    emit(state.copyWith(docs: docs, docNames: names));
  }

  /// Absher/Yakeen autofill applied to the form (website applyAbsher).
  void applyAbsher({String? fullName, String? mobile9, String? identityNo}) {
    if ((fullName ?? '').trim().isNotEmpty) name.text = fullName!.trim();
    if ((mobile9 ?? '').trim().isNotEmpty) phone.text = '+966${mobile9!.trim()}';
    if ((identityNo ?? '').trim().isNotEmpty) identity.text = identityNo!.trim();
  }

  String _fullPhone(String raw) {
    var p = raw.trim().replaceAll(RegExp(r'\s'), '');
    if (p.startsWith('+')) return p;
    if (p.startsWith('00')) return '+${p.substring(2)}';
    if (p.startsWith('0')) p = p.substring(1);
    return '+966$p';
  }

  Future<bool> submit() async {
    // Website handleSubmit gates: name, phone (\+?\d{10,15}) and net income.
    final ok = name.text.trim().isNotEmpty &&
        RegExp(r'^\+?\d{10,15}$').hasMatch(_fullPhone(phone.text)) &&
        (double.tryParse(income.text.trim()) ?? 0) > 0;
    if (!ok) {
      emit(state.copyWith(error: true));
      return false;
    }
    emit(state.copyWith(phase: FinanceLeadPhase.busy, error: false));
    final est = estimate;
    final res = await _online.submitFinance({
      'fullNameAr': name.text.trim(),
      'fullNameEn': name.text.trim(),
      'phoneNumber': _fullPhone(phone.text),
      'webUserID': user?.userId,
      'email': email.text.trim().isEmpty ? null : email.text.trim(),
      // Website: applicants here are individuals — custType fixed G4,
      // the number is always an identity number (never a CR).
      'custType': 'G4',
      'identityNo': identity.text.trim().isEmpty ? null : identity.text.trim(),
      'productID': car.productId,
      'colorID': car.colorId,
      'colorGroup': car.colorGroupId,
      'modelYear': car.year,
      'offerID': bank.offerId,
      'source': 'FinancePage',
      'income': double.tryParse(income.text.trim()),
      'monthlyAmount': est.monthly.roundToDouble(),
      'firstPayment': est.firstPay.roundToDouble(),
      'period': est.period,
      'message': note.text.trim().isEmpty ? null : note.text.trim(),
      // Website FinanceDocUploads payload: جهة العمل (only when picked)
      // + base64 documents.
      'workType': state.workType.isEmpty ? null : state.workType,
      for (final kind in kFinanceDocKinds)
        if ((state.docs[kind] ?? '').isNotEmpty) kind: state.docs[kind],
    });
    if (isClosed) return res.ok;
    emit(state.copyWith(
        phase: res.ok ? FinanceLeadPhase.done : FinanceLeadPhase.failed,
        reference: () => res.reference));
    return res.ok;
  }

  @override
  Future<void> close() {
    for (final c in [name, phone, email, identity, income, advanceCtrl, note]) {
      c.dispose();
    }
    return super.close();
  }
}
