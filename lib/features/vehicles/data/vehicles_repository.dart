import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../home/domain/home_models.dart';
import '../domain/vehicle_models.dart';

/// Vehicle model detail — same Site_Vehicle_* cycle as the website page.
final class VehiclesRepository {
  VehiclesRepository(this._api);

  final ApiClient _api;

  Future<List<T>> _list<T>(String path, T Function(Map<String, dynamic>) parse) async {
    try {
      final res = await _api.get<List<dynamic>>(path);
      return (res.data ?? []).whereType<Map<String, dynamic>>().map(parse).toList();
    } on DioException {
      return const [];
    }
  }

  Future<SliderVehicle?> detail(String slug) async {
    try {
      final res = await _api.get<Map<String, dynamic>>('/api/app/vehicles/$slug');
      return res.statusCode == 200 && res.data != null
          ? SliderVehicle.fromJson(res.data!)
          : null;
    } on DioException {
      return null;
    }
  }

  Future<List<VehicleTrim>> trims(String slug) =>
      _list('/api/app/vehicles/$slug/trims', VehicleTrim.fromJson);

  Future<List<VehicleColor>> colors(String slug) =>
      _list('/api/app/vehicles/$slug/colors', VehicleColor.fromJson);

  Future<List<VehicleColorImage>> colorImages(String slug) =>
      _list('/api/app/vehicles/$slug/color-images', VehicleColorImage.fromJson);

  Future<List<VehicleFeature>> features(String slug) =>
      _list('/api/app/vehicles/$slug/features', VehicleFeature.fromJson);

  Future<List<VehicleGalleryItem>> gallery(String slug) =>
      _list('/api/app/vehicles/$slug/gallery', VehicleGalleryItem.fromJson);

  Future<List<EquipmentRow>> equipments(String slug) =>
      _list('/api/app/vehicles/$slug/equipments', EquipmentRow.fromJson);
}
