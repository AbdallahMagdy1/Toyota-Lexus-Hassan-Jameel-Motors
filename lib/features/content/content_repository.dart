import 'package:dio/dio.dart';

import '../../core/constants/api_paths.dart';
import '../../core/network/api_client.dart';
import 'content_models.dart';

/// News + Contact — the website's /news and /contact cycles.
final class ContentRepository {
  ContentRepository(this._api);

  final ApiClient _api;

  Future<List<NewsItem>> news() async {
    try {
      final res = await _api.get<Map<String, dynamic>>(
        ApiPaths.news,
        query: {'page': 1, 'pageSize': 50},
      );
      return ((res.data?['items'] as List<dynamic>?) ?? [])
          .whereType<Map<String, dynamic>>()
          .map(NewsItem.fromJson)
          .toList();
    } on DioException {
      return const [];
    }
  }

  /// Full article by slug ({article, latest}) — the list rows don't carry
  /// the body, the website's /news/[slug] does.
  Future<NewsItem?> newsDetail(String slug) async {
    try {
      final res = await _api.get<Map<String, dynamic>>(
          '${ApiPaths.news}/${Uri.encodeComponent(slug)}');
      final article = res.data?['article'];
      return article is Map<String, dynamic>
          ? NewsItem.fromJson(article)
          : null;
    } on DioException {
      return null;
    }
  }

  Future<ContactPage> contact() async {
    try {
      final res = await _api.get<Map<String, dynamic>>(ApiPaths.contact);
      return res.data == null
          ? const ContactPage()
          : ContactPage.fromJson(res.data!);
    } on DioException {
      return const ContactPage();
    }
  }

  /// Website payload: {name, email?, phone (5XXXXXXXX), subject, message}.
  Future<bool> sendMessage({
    required String name,
    String? email,
    required String phone,
    required int subject,
    required String message,
  }) async {
    try {
      final res = await _api.post<Map<String, dynamic>>(
        ApiPaths.contactMessages,
        body: {
          'name': name,
          'email': (email ?? '').isEmpty ? null : email,
          'phone': phone,
          'subject': subject,
          'message': message,
        },
      );
      return res.data?['ok'] == true;
    } on DioException {
      return false;
    }
  }
}
