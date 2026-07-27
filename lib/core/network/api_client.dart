import 'package:dio/dio.dart';

import '../constants/api_paths.dart';

/// Thin Dio wrapper — one client for the whole app, injected via get_it.
final class ApiClient {
  ApiClient([Dio? dio])
      : dio = dio ??
            Dio(BaseOptions(
              baseUrl: ApiPaths.baseUrl,
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 20),
              headers: {'Content-Type': 'application/json'},
              // The API answers 401 for bad credentials — treat it as data,
              // not an exception, so blocs can map it to a friendly message.
              validateStatus: (s) => s != null && s < 500,
            ));

  final Dio dio;

  Future<Response<T>> get<T>(String path, {Map<String, dynamic>? query}) =>
      dio.get<T>(path, queryParameters: query);

  Future<Response<T>> post<T>(String path, {Object? body}) =>
      dio.post<T>(path, data: body);
}
