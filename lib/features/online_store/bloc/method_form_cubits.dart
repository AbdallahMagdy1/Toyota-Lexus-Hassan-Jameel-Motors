import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../auth/domain/app_user.dart';
import '../../home/domain/home_models.dart';
import '../data/online_store_repository.dart';
import '../domain/online_store_models.dart';

/// Shared bits for the three purchase forms — validation rules are a 1:1
/// port of the website's OnlineConfirm.tsx.

bool _phone9(String v) => RegExp(r'^\d{9}$').hasMatch(v.trim());
bool _identity10(String v) => RegExp(r'^\d{10}$').hasMatch(v.trim());
bool _email(String v) => RegExp(r'^\S+@\S+\.\S+$').hasMatch(v.trim());
String _fullPhone(String v) => '+966${v.trim()}';

String? _prefillPhone(AppUser? u) {
  final p = u?.phone?.replaceFirst('+966', '').replaceFirst(RegExp(r'^0'), '');
  return p != null && RegExp(r'^\d{9}$').hasMatch(p) ? p : null;
}

/* ─────────────────────────── Contact (callback) ─────────────────────────── */

final class ContactFormState extends Equatable {
  const ContactFormState({
    this.custGroupId = 'G4',
    this.cityId,
    this.quantity = 1,
    this.busy = false,
    this.errors = const {},
    this.serverError,
  });

  final String custGroupId;
  final String? cityId;
  final int quantity;
  final bool busy;
  final Map<String, String> errors;
  final String? serverError;

  ContactFormState copyWith({
    String? custGroupId,
    String? cityId,
    int? quantity,
    bool? busy,
    Map<String, String>? errors,
    String? serverError,
    bool clearServerError = false,
  }) =>
      ContactFormState(
        custGroupId: custGroupId ?? this.custGroupId,
        cityId: cityId ?? this.cityId,
        quantity: quantity ?? this.quantity,
        busy: busy ?? this.busy,
        errors: errors ?? this.errors,
        serverError: clearServerError ? null : (serverError ?? this.serverError),
      );

  @override
  List<Object?> get props => [custGroupId, cityId, quantity, busy, errors, serverError];
}

final class ContactFormCubit extends Cubit<ContactFormState> {
  ContactFormCubit(this._repo, this.vehicle, this.settings,
      {required this.lang, AppUser? user, CarColor? color})
      : _color = color,
        super(ContactFormState(
          custGroupId: settings.custGroups.isEmpty
              ? 'G4'
              : (settings.custGroups.first.id ?? 'G4'),
          cityId: settings.cities.isEmpty ? null : settings.cities.first.id,
        )) {
    if (user != null) {
      name.text = user.displayName(lang);
      email.text = user.email ?? '';
      final p = _prefillPhone(user);
      if (p != null) phone.text = p;
    }
  }

  final OnlineStoreRepository _repo;
  final OnlineVehicle vehicle;
  final FormSettings settings;
  final String lang;
  final CarColor? _color;

  final name = TextEditingController();
  final phone = TextEditingController();
  final email = TextEditingController();
  final identity = TextEditingController();
  final note = TextEditingController();

  CustGroup? get custGroup => settings.custGroups
      .where((g) => g.id == state.custGroupId)
      .firstOrNull;
  bool get needIdentity => custGroup?.needIdentity ?? true;

  void setCustGroup(String id) => emit(state.copyWith(custGroupId: id));
  void setCity(String? id) => emit(state.copyWith(cityId: id));
  void setQuantity(int q) => emit(state.copyWith(quantity: q.clamp(1, 20)));

  /// Website `valid` (OnlineConfirm L1211): name≥2, phone 9 digits, email
  /// required, city, identity 10 digits, quantity ≥ 1.
  bool _validate() {
    final e = <String, String>{};
    if (name.text.trim().length < 2) e['name'] = 'required';
    if (!_phone9(phone.text)) e['phone'] = 'phone';
    if (!_email(email.text)) e['email'] = 'email';
    if (state.cityId == null) e['city'] = 'required';
    if (!_identity10(identity.text)) e['identity'] = 'identity';
    emit(state.copyWith(errors: e, clearServerError: true));
    return e.isEmpty;
  }

  Future<SubmissionResult?> submit() async {
    if (!_validate()) return null;
    emit(state.copyWith(busy: true));
    final city = settings.cities.where((c) => c.id == state.cityId).firstOrNull;
    final res = await _repo.submitContact({
      'name': name.text.trim(),
      'phone': _fullPhone(phone.text),
      'email': email.text.trim(),
      'address': city?.name(lang) ?? state.cityId,
      'quantity': state.quantity,
      'colorID': _color?.colorId,
      'brandID': vehicle.brandId,
      'productGroupID': vehicle.carGroupId,
      'productTypeID': vehicle.type,
      'modelYear': vehicle.year,
      'custGroupID': state.custGroupId,
      'addtionalNo': identity.text.trim(), // (sic) — backend DTO spelling
      'note': note.text.trim().isEmpty ? null : note.text.trim(),
    });
    if (isClosed) return null;
    emit(state.copyWith(busy: false, serverError: res.ok ? null : res.error ?? 'failed'));
    return res.ok ? res : null;
  }

  @override
  Future<void> close() {
    for (final c in [name, phone, email, identity, note]) {
      c.dispose();
    }
    return super.close();
  }
}

/* ───────────────────────── Quick reservation ───────────────────────── */

final class ReserveFormState extends Equatable {
  const ReserveFormState({
    this.custGroupId = 'G4',
    this.cityId,
    this.busy = false,
    this.errors = const {},
    this.serverError,
  });

  final String custGroupId;
  final String? cityId;
  final bool busy;
  final Map<String, String> errors;
  final String? serverError;

  ReserveFormState copyWith({
    String? custGroupId,
    String? cityId,
    bool? busy,
    Map<String, String>? errors,
    String? serverError,
    bool clearServerError = false,
  }) =>
      ReserveFormState(
        custGroupId: custGroupId ?? this.custGroupId,
        cityId: cityId ?? this.cityId,
        busy: busy ?? this.busy,
        errors: errors ?? this.errors,
        serverError: clearServerError ? null : (serverError ?? this.serverError),
      );

  @override
  List<Object?> get props => [custGroupId, cityId, busy, errors, serverError];
}

final class ReserveFormCubit extends Cubit<ReserveFormState> {
  ReserveFormCubit(this._repo, this.vehicle, this.settings,
      {required this.lang,
      required this.downPayment,
      this.sn,
      AppUser? user,
      CarColor? color})
      : _user = user,
        _color = color,
        super(ReserveFormState(
          custGroupId: settings.custGroups.isEmpty
              ? 'G4'
              : (settings.custGroups.first.id ?? 'G4'),
          cityId: settings.cities.isEmpty ? null : settings.cities.first.id,
        )) {
    if (user != null) {
      name.text = user.displayName(lang);
      email.text = user.email ?? '';
      final p = _prefillPhone(user);
      if (p != null) phone.text = p;
    }
  }

  final OnlineStoreRepository _repo;
  final OnlineVehicle vehicle;
  final FormSettings settings;
  final String lang;
  final double downPayment;
  final String? sn;
  final AppUser? _user;
  final CarColor? _color;

  final name = TextEditingController();
  final phone = TextEditingController();
  final email = TextEditingController();
  final identity = TextEditingController();

  bool get needIdentity => settings.custGroups
          .where((g) => g.id == state.custGroupId)
          .firstOrNull
          ?.needIdentity ??
      true;

  void setCustGroup(String id) => emit(state.copyWith(custGroupId: id));
  void setCity(String? id) => emit(state.copyWith(cityId: id));

  /// Website ReserveForm validation: name≥2, phone 9 digits, city, identity.
  bool _validate() {
    final e = <String, String>{};
    if (name.text.trim().length < 2) e['name'] = 'required';
    if (!_phone9(phone.text)) e['phone'] = 'phone';
    if (state.cityId == null) e['city'] = 'required';
    if (!_identity10(identity.text)) e['identity'] = 'identity';
    emit(state.copyWith(errors: e, clearServerError: true));
    return e.isEmpty;
  }

  /// The old store's BUY cycle, faithful to the website's OnlineConfirm:
  /// down-payment reservation via Site_Reservation_Car_Payment. Returns the
  /// raw result map on success (urlPayment / sadadNumber / orderId).
  Future<Map<String, dynamic>?> payAndReserve() async {
    if (!_validate()) return null;
    emit(state.copyWith(busy: true));
    final res = await _repo.reservationPay({
      'userId': '${_user?.userId ?? ''}',
      'productId': vehicle.productId,
      'sn': sn,
      'year': vehicle.year,
      'modelName': vehicle.groupEn,
      'city': state.cityId,
      'paymentAmount': downPayment,
      'miniDownPayment': downPayment,
      'finalTotal': vehicle.minPrice ?? 0,
      'notificationWhatsApp': 0,
      'lang': lang,
      'callbackUrl': 'https://hjapp.payment/online?PaymentType=full',
    });
    if (isClosed) return null;
    final url = '${res?['urlPayment'] ?? ''}';
    final sadad = '${res?['sadadNumber'] ?? ''}';
    final status = '${res?['status'] ?? ''}'.toLowerCase();
    final msg = '${res?['messageError'] ?? ''}';
    // URL / Sadad WIN over messageError (legacy SP quirk, like the website).
    final ok = res != null &&
        ((url.isNotEmpty && url != 'null') ||
            (sadad.isNotEmpty && sadad != 'null') ||
            status == 'success');
    emit(state.copyWith(
        busy: false,
        serverError:
            ok ? null : (msg.isNotEmpty && msg != 'null' ? msg : 'failed')));
    return ok ? res : null;
  }

  Future<SubmissionResult?> submit() async {
    if (!_validate()) return null;
    emit(state.copyWith(busy: true));
    final res = await _repo.submitReservation({
      'name': name.text.trim(),
      'phone': _fullPhone(phone.text),
      'email': email.text.trim().isEmpty ? null : email.text.trim(),
      'city': state.cityId,
      'custGroupID': state.custGroupId,
      if (needIdentity)
        'identityNo': identity.text.trim()
      else ...{
        'identityNo': identity.text.trim(),
        'commercialIdentity': identity.text.trim(),
      },
      'productID': vehicle.productId,
      'colorID': _color?.colorId,
      'productTypeID': vehicle.type,
      'modelYear': vehicle.year,
      'paymentAmount': downPayment,
      'paymentPlatform': 'MobileApp',
    });
    if (isClosed) return null;
    emit(state.copyWith(busy: false, serverError: res.ok ? null : res.error ?? 'failed'));
    return res.ok ? res : null;
  }

  @override
  Future<void> close() {
    for (final c in [name, phone, email, identity]) {
      c.dispose();
    }
    return super.close();
  }
}

/* ─────────────────────────── Finance request ─────────────────────────── */

final class FinanceFormState extends Equatable {
  const FinanceFormState({
    this.step = 0,
    this.custGroupId = 'G4',
    this.cityId,
    this.gender = 1,
    this.whatsapp = true,
    this.workType,
    this.salaryBankId,
    this.q1 = -1,
    this.q2 = -1,
    this.q3 = -1,
    this.q4 = -1,
    this.financeBankId,
    this.docs = const {},
    this.busy = false,
    this.errors = const {},
    this.serverError,
  });

  final int step; // 0 personal | 1 work | 2 documents
  final String custGroupId;
  final String? cityId;
  final int gender; // 1 male, 2 female
  final bool whatsapp;
  final String? workType; // private | governmental
  final String? salaryBankId;
  final int q1, q2, q3, q4; // -1 unanswered, 0 no, 1 yes
  final String? financeBankId; // the Pick-a-bank selection
  final Map<String, String> docs; // key → base64
  final bool busy;
  final Map<String, String> errors;
  final String? serverError;

  FinanceFormState copyWith({
    int? step,
    String? custGroupId,
    String? cityId,
    int? gender,
    bool? whatsapp,
    String? workType,
    String? salaryBankId,
    int? q1,
    int? q2,
    int? q3,
    int? q4,
    String? financeBankId,
    Map<String, String>? docs,
    bool? busy,
    Map<String, String>? errors,
    String? serverError,
    bool clearServerError = false,
  }) =>
      FinanceFormState(
        step: step ?? this.step,
        custGroupId: custGroupId ?? this.custGroupId,
        cityId: cityId ?? this.cityId,
        gender: gender ?? this.gender,
        whatsapp: whatsapp ?? this.whatsapp,
        workType: workType ?? this.workType,
        salaryBankId: salaryBankId ?? this.salaryBankId,
        q1: q1 ?? this.q1,
        q2: q2 ?? this.q2,
        q3: q3 ?? this.q3,
        q4: q4 ?? this.q4,
        financeBankId: financeBankId ?? this.financeBankId,
        docs: docs ?? this.docs,
        busy: busy ?? this.busy,
        errors: errors ?? this.errors,
        serverError: clearServerError ? null : (serverError ?? this.serverError),
      );

  @override
  List<Object?> get props => [
        step, custGroupId, cityId, gender, whatsapp, workType, salaryBankId,
        q1, q2, q3, q4, financeBankId, docs, busy, errors, serverError,
      ];
}

final class FinanceFormCubit extends Cubit<FinanceFormState> {
  FinanceFormCubit(this._repo, this.vehicle, this.settings,
      {required this.lang,
      this.user,
      CarColor? color,
      String? initialBankId})
      : _color = color,
        super(FinanceFormState(
          custGroupId: settings.custGroups.isEmpty
              ? 'G4'
              : (settings.custGroups.first.id ?? 'G4'),
          cityId: settings.cities.isEmpty ? null : settings.cities.first.id,
          financeBankId: initialBankId,
        )) {
    if (user != null) {
      final u = user!;
      fullNameEn.text = [u.firstNameEn, u.lastNameEn].whereType<String>().join(' ').trim();
      fullNameAr.text = [u.firstNameAr, u.lastNameAr].whereType<String>().join(' ').trim();
      email.text = u.email ?? '';
      final p = _prefillPhone(u);
      if (p != null) phone.text = p;
    }
    period.text = '60'; // website default
  }

  final OnlineStoreRepository _repo;
  final OnlineVehicle vehicle;
  final FormSettings settings;
  final String lang;
  final AppUser? user;
  final CarColor? _color;
  final _picker = ImagePicker();

  // Personal
  final fullNameAr = TextEditingController();
  final fullNameEn = TextEditingController();
  final phone = TextEditingController();
  final email = TextEditingController();
  final identity = TextEditingController();
  // Work
  final job = TextEditingController();
  final income = TextEditingController();
  final firstPayment = TextEditingController();
  final monthlyAmount = TextEditingController();
  final period = TextEditingController();
  final violations = TextEditingController();
  final obligations = TextEditingController();
  final message = TextEditingController();

  bool get needIdentity => settings.custGroups
          .where((g) => g.id == state.custGroupId)
          .firstOrNull
          ?.needIdentity ??
      true;

  void setCustGroup(String id) => emit(state.copyWith(custGroupId: id));
  void setCity(String? id) => emit(state.copyWith(cityId: id));
  void setGender(int g) => emit(state.copyWith(gender: g));
  void setWhatsapp(bool v) => emit(state.copyWith(whatsapp: v));
  void setWorkType(String v) => emit(state.copyWith(workType: v));
  void setSalaryBank(String? id) => emit(state.copyWith(salaryBankId: id));
  void setQuestion(int index, int value) => emit(switch (index) {
        1 => state.copyWith(q1: value),
        2 => state.copyWith(q2: value),
        3 => state.copyWith(q3: value),
        _ => state.copyWith(q4: value),
      });
  void setFinanceBank(String? id) => emit(state.copyWith(financeBankId: id));

  /// Pick an image (gallery), 4MB cap like the website FileField.
  Future<void> pickDoc(String key) async {
    final file = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (file == null || isClosed) return;
    final bytes = await file.readAsBytes();
    if (bytes.lengthInBytes > 4 * 1024 * 1024) {
      emit(state.copyWith(errors: {...state.errors, key: 'tooBig'}));
      return;
    }
    final docs = Map<String, String>.from(state.docs)..[key] = base64Encode(bytes);
    final errors = Map<String, String>.from(state.errors)..remove(key);
    emit(state.copyWith(docs: docs, errors: errors));
  }

  void removeDoc(String key) {
    final docs = Map<String, String>.from(state.docs)..remove(key);
    emit(state.copyWith(docs: docs));
  }

  /// Step validations — website personalValid / workValid / docsValid.
  bool _validateStep(int step) {
    final e = <String, String>{};
    switch (step) {
      case 0:
        if (fullNameEn.text.trim().length < 2 && fullNameAr.text.trim().length < 2) {
          e['fullName'] = 'required';
        }
        if (!_phone9(phone.text)) e['phone'] = 'phone';
        if (!_identity10(identity.text)) e['identity'] = 'identity';
        if (state.cityId == null) e['city'] = 'required';
      case 1:
        if (job.text.trim().length < 2) e['job'] = 'required';
        if ((double.tryParse(income.text.trim()) ?? 0) <= 0) e['income'] = 'required';
        if (state.workType == null) e['workType'] = 'required';
        if (state.salaryBankId == null) e['salaryBank'] = 'required';
        if (state.q1 < 0 || state.q2 < 0 || state.q3 < 0 || state.q4 < 0) {
          e['questions'] = 'required';
        }
      case 2:
        if (state.financeBankId == null) e['financeBank'] = 'required';
        for (final k in requiredDocKeys) {
          if (!state.docs.containsKey(k)) e[k] = 'required';
        }
    }
    emit(state.copyWith(errors: e, clearServerError: true));
    return e.isEmpty;
  }

  /// Salary letter only for individuals (G4), like the website.
  List<String> get requiredDocKeys => [
        'identityImage',
        'license',
        'insurance',
        'accountStatement',
        if (state.custGroupId == 'G4') 'salaryDefinitionLetter',
      ];

  void next() {
    if (_validateStep(state.step)) emit(state.copyWith(step: state.step + 1));
  }

  void back() => emit(state.copyWith(step: (state.step - 1).clamp(0, 2)));
  void goToStep(int s) {
    if (s < state.step) emit(state.copyWith(step: s));
  }

  Future<SubmissionResult?> submit() async {
    if (!_validateStep(2)) return null;
    emit(state.copyWith(busy: true));
    final res = await _repo.submitFinance({
      'fullNameAr': fullNameAr.text.trim(),
      'fullNameEn': fullNameEn.text.trim(),
      'phoneNumber': _fullPhone(phone.text),
      'webUserID': user?.userId,
      'email': email.text.trim().isEmpty ? null : email.text.trim(),
      'custType': state.custGroupId,
      if (needIdentity)
        'identityNo': identity.text.trim()
      else
        'cn': identity.text.trim(),
      'productID': vehicle.productId,
      'colorID': _color?.colorId,
      'colorGroup': vehicle.carGroupId,
      'modelYear': vehicle.year,
      'bankID': state.financeBankId,
      'source': 'OnlineStore',
      'job': job.text.trim(),
      'income': double.tryParse(income.text.trim()),
      'monthlyAmount': double.tryParse(monthlyAmount.text.trim()),
      'firstPayment': double.tryParse(firstPayment.text.trim()),
      'period': int.tryParse(period.text.trim()) ?? 60,
      'gender': state.gender,
      'city': state.cityId,
      'message': message.text.trim().isEmpty ? null : message.text.trim(),
      'workType': state.workType,
      'salaryTransfer': state.salaryBankId,
      'notificationWhatsApp': state.whatsapp ? 1 : 0,
      'questions1': state.q1,
      'questions2': state.q2,
      'questions3': state.q3,
      'questions4': state.q4,
      // Website: violations only when q2=yes, obligations only when q4=yes.
      'violations': state.q2 == 1 ? (double.tryParse(violations.text.trim()) ?? 0) : 0,
      'obligations': state.q4 == 1 ? (double.tryParse(obligations.text.trim()) ?? 0) : 0,
      'identityImage': state.docs['identityImage'],
      'license': state.docs['license'],
      'insurance': state.docs['insurance'],
      'accountStatement': state.docs['accountStatement'],
      'salaryDefinitionLetter': state.docs['salaryDefinitionLetter'],
    });
    if (isClosed) return null;
    emit(state.copyWith(busy: false, serverError: res.ok ? null : res.error ?? 'failed'));
    return res.ok ? res : null;
  }

  @override
  Future<void> close() {
    for (final c in [
      fullNameAr, fullNameEn, phone, email, identity, job, income,
      firstPayment, monthlyAmount, period, violations, obligations, message,
    ]) {
      c.dispose();
    }
    return super.close();
  }
}
