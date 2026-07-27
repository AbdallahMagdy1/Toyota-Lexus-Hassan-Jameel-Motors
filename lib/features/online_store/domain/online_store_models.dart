import 'package:equatable/equatable.dart';

String? _s(dynamic v) => v?.toString();
double? _d(dynamic v) => v is num ? v.toDouble() : double.tryParse('$v');
int? _i(dynamic v) => v is num ? v.toInt() : int.tryParse('$v');

/// Bank financing offer — every figure is precomputed by the API
/// (OnlineService.GetBankOffersAsync); the app only renders.
final class BankOffer extends Equatable {
  const BankOffer({
    this.bankId,
    this.nameAr,
    this.nameEn,
    this.logo,
    this.financePeriodMonths = 60,
    this.downPayment,
    this.lastPayment,
    this.adminFees,
    this.monthlyInstallment,
    this.totalCost,
    this.minSalary,
  });

  final String? bankId;
  final String? nameAr;
  final String? nameEn;
  final String? logo;
  final int financePeriodMonths;
  final double? downPayment;
  final double? lastPayment;
  final double? adminFees;
  final double? monthlyInstallment;
  final double? totalCost;
  final double? minSalary;

  String name(String lang) => (lang == 'ar' ? nameAr : nameEn) ?? nameEn ?? nameAr ?? '';

  factory BankOffer.fromJson(Map<String, dynamic> j) => BankOffer(
        bankId: _s(j['bankId']),
        nameAr: _s(j['nameAr']),
        nameEn: _s(j['nameEn']),
        logo: _s(j['logo']),
        financePeriodMonths: _i(j['financePeriodMonths']) ?? 60,
        downPayment: _d(j['downPayment']),
        lastPayment: _d(j['lastPayment']),
        adminFees: _d(j['adminFees']),
        monthlyInstallment: _d(j['monthlyInstallment']),
        totalCost: _d(j['totalCost']),
        minSalary: _d(j['minSalary']),
      );

  @override
  List<Object?> get props => [bankId];
}

final class CustGroup extends Equatable {
  const CustGroup({this.id, this.nameAr, this.nameEn, this.needIdentity = true});

  final String? id; // G4 = individual, G3 = company
  final String? nameAr;
  final String? nameEn;
  final bool needIdentity;

  String name(String lang) => (lang == 'ar' ? nameAr : nameEn) ?? nameEn ?? nameAr ?? '';

  factory CustGroup.fromJson(Map<String, dynamic> j) => CustGroup(
        id: _s(j['id']),
        nameAr: _s(j['nameAr']),
        nameEn: _s(j['nameEn']),
        needIdentity: j['needIdentity'] != false,
      );

  @override
  List<Object?> get props => [id];
}

final class City extends Equatable {
  const City({this.id, this.nameAr, this.nameEn});

  final String? id;
  final String? nameAr;
  final String? nameEn;

  String name(String lang) => (lang == 'ar' ? nameAr : nameEn) ?? nameEn ?? nameAr ?? '';

  factory City.fromJson(Map<String, dynamic> j) =>
      City(id: _s(j['id']), nameAr: _s(j['nameAr']), nameEn: _s(j['nameEn']));

  @override
  List<Object?> get props => [id];
}

final class FormSettings extends Equatable {
  const FormSettings({this.custGroups = const [], this.cities = const []});

  final List<CustGroup> custGroups;
  final List<City> cities;

  factory FormSettings.fromJson(Map<String, dynamic> j) => FormSettings(
        custGroups: (j['custGroups'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(CustGroup.fromJson)
            .toList(),
        cities: (j['cities'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(City.fromJson)
            .toList(),
      );

  @override
  List<Object?> get props => [custGroups, cities];
}

final class ReservationSettings extends Equatable {
  const ReservationSettings({this.toyotaDownPayment = 2500, this.lexusDownPayment = 5000});

  final double toyotaDownPayment;
  final double lexusDownPayment;

  /// Website fallbacks: Lexus 5000, Toyota 2500.
  double forBrand(String brandKey) =>
      brandKey == 'lexus' ? lexusDownPayment : toyotaDownPayment;

  factory ReservationSettings.fromJson(Map<String, dynamic> j) => ReservationSettings(
        toyotaDownPayment: _d(j['toyotaDownPayment']) ?? 2500,
        lexusDownPayment: _d(j['lexusDownPayment']) ?? 5000,
      );

  @override
  List<Object?> get props => [toyotaDownPayment, lexusDownPayment];
}

final class SubmissionResult extends Equatable {
  const SubmissionResult({required this.ok, this.error, this.reference});

  final bool ok;
  final String? error; // SP RAISERROR text (e.g. the 24h-dedupe Arabic message)
  final String? reference; // "HJ-…" on reservations

  factory SubmissionResult.fromJson(Map<String, dynamic> j) => SubmissionResult(
        ok: j['ok'] == true,
        error: _s(j['error']),
        reference: _s(j['reference']),
      );

  @override
  List<Object?> get props => [ok, error, reference];
}
