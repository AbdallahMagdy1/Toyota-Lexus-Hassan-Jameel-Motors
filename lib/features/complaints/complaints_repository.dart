import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/network/api_client.dart';
import 'complaints_models.dart';

/// Complaints cycle — the same three procedures the website's contact page
/// uses (submit + tracker + reply), over /api/app/complaints/*.
final class ComplaintsRepository {
  ComplaintsRepository(this._api);

  final ApiClient _api;

  /// Same idea as the website's cookie: remember the phone a guest
  /// submitted with so the tracker works while signed out.
  static const _phoneKey = 'hj_complaint_phone';

  /// The website forces a Saudi mobile: strip 966/leading 0, force leading
  /// 5, 9 digits — identical to the contact form's normalization.
  static String normalizePhone(String raw) {
    var d = raw.replaceAll(RegExp(r'\D'), '');
    if (d.startsWith('966')) d = d.substring(3);
    if (d.startsWith('0')) d = d.substring(1);
    if (!d.startsWith('5')) d = '5$d';
    return d.length > 9 ? d.substring(0, 9) : d;
  }

  static Future<void> rememberPhone(String phone) async {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return;
    final last9 =
        digits.length > 9 ? digits.substring(digits.length - 9) : digits;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_phoneKey, last9);
  }

  static Future<String?> storedPhone() async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getString(_phoneKey);
    return (v == null || v.isEmpty) ? null : v;
  }

  /// Submit a new complaint. Returns (ok, reference) — reference is the
  /// CMP-000001 ticket shown on the success view.
  Future<(bool, String?)> submit({
    int? webUserId,
    required String customerName,
    required String phone,
    String? email,
    required String complaintType,
    String? subject,
    required String body,
    List<ComplaintAttachmentDraft> attachments = const [],
  }) async {
    try {
      final res = await _api.post<Map<String, dynamic>>(
        '/api/app/complaints/submit',
        body: {
          if ((webUserId ?? 0) > 0) 'webUserID': webUserId,
          'customerName': customerName,
          'phone': phone,
          if ((email ?? '').isNotEmpty) 'email': email,
          'complaintType': complaintType,
          if ((subject ?? '').isNotEmpty) 'subject': subject,
          'body': body,
          if (attachments.isNotEmpty)
            'attachments': [
              for (final a in attachments)
                {
                  'fileName': a.fileName,
                  'type': a.mime,
                  'base64': base64Encode(a.bytes),
                },
            ],
        },
      );
      final j = res.data ?? const {};
      final ok = j['ok'] == true;
      if (ok) await rememberPhone(phone);
      return (ok, j['reference']?.toString());
    } on DioException {
      return (false, null);
    }
  }

  /// Customer reply on an Updated complaint.
  Future<bool> reply({
    required String guid,
    int? webUserId,
    String? phone,
    required String message,
  }) async {
    try {
      final res = await _api.post<Map<String, dynamic>>(
        '/api/app/complaints/reply',
        body: {
          'guid': guid,
          if ((webUserId ?? 0) > 0) 'webUserID': webUserId,
          if ((phone ?? '').isNotEmpty) 'phone': phone,
          'message': message,
        },
      );
      return res.data?['ok'] == true;
    } on DioException {
      return false;
    }
  }

  /// Tracker list — by userId when signed in, by remembered phone when a
  /// guest. Null means network failure (the UI shows a retry state).
  Future<List<Complaint>?> myComplaints({int? userId, String? phone}) async {
    try {
      final res = await _api.get<List<dynamic>>(
        '/api/app/complaints/my-complaints',
        query: {
          if ((userId ?? 0) > 0) 'userId': userId,
          if ((phone ?? '').isNotEmpty) 'phone': phone,
        },
      );
      if (res.statusCode != 200 || res.data == null) return null;
      return res.data!
          .whereType<Map<String, dynamic>>()
          .map(Complaint.fromJson)
          .toList();
    } on DioException {
      return null;
    }
  }
}
