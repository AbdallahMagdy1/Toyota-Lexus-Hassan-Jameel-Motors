import 'package:dio/dio.dart';

import '../../../core/constants/api_paths.dart';
import '../../../core/network/api_client.dart';
import '../domain/finance_models.dart';

/// Finance-page cycle — same endpoints/DTOs as the website's /finance page.
final class FinanceRepository {
  FinanceRepository(this._api);

  final ApiClient _api;

  Future<List<FinanceBank>> banks() async {
    try {
      final res = await _api.get<List<dynamic>>(ApiPaths.financeBanks);
      return (res.data ?? [])
          .whereType<Map<String, dynamic>>()
          .map(FinanceBank.fromJson)
          .toList();
    } on DioException {
      return const [];
    }
  }

  /// The agreed applicant types — G4 individuals / G3 companies — used
  /// whenever the API answers without custGroups so the "نوع مقدم الطلب"
  /// picker is never empty.
  static const List<FinanceCustGroup> kDefaultCustGroups = [
    FinanceCustGroup(
        id: 'G4', nameAr: 'أفراد', nameEn: 'Individuals', needIdentity: true),
    FinanceCustGroup(
        id: 'G3',
        nameAr: 'شركات ومؤسسات',
        nameEn: 'Companies & Organizations',
        needIdentity: false),
  ];

  static FinanceFilters _withCustGroupFallback(FinanceFilters f) =>
      f.custGroups.isNotEmpty
          ? f
          : FinanceFilters(groups: f.groups, custGroups: kDefaultCustGroups);

  Future<FinanceFilters> filters() async {
    try {
      final res = await _api.get<Map<String, dynamic>>(ApiPaths.financeFilters);
      return _withCustGroupFallback(res.data == null
          ? const FinanceFilters()
          : FinanceFilters.fromJson(res.data!));
    } on DioException {
      return _withCustGroupFallback(const FinanceFilters());
    }
  }

  /// The bank-priced lineup — refetched whenever the financier changes,
  /// exactly like the website.
  Future<List<FinanceVehicle>> vehiclesByBank(String priceListTypeId) async {
    try {
      final res = await _api.get<List<dynamic>>(
        ApiPaths.financeVehicles,
        query: {'bank': priceListTypeId},
      );
      return (res.data ?? [])
          .whereType<Map<String, dynamic>>()
          .map(FinanceVehicle.fromJson)
          .toList();
    } on DioException {
      return const [];
    }
  }
}
