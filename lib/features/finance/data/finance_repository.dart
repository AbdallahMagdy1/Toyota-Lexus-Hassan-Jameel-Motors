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

  Future<FinanceFilters> filters() async {
    try {
      final res = await _api.get<Map<String, dynamic>>(ApiPaths.financeFilters);
      return res.data == null
          ? const FinanceFilters()
          : FinanceFilters.fromJson(res.data!);
    } on DioException {
      return const FinanceFilters();
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
