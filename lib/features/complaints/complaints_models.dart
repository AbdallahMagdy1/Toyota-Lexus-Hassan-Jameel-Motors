import 'dart:typed_data';

/// Complaints cycle — wire models for /api/app/complaints/* (the website's
/// contact-page complaints rebuilt for mobile).

/// One complaint as returned by GET /api/app/complaints/my-complaints.
final class Complaint {
  const Complaint({
    required this.guid,
    required this.ticketNo,
    required this.complaintType,
    required this.department,
    this.subject,
    required this.body,
    required this.status,
    this.createdDate,
    this.updatedDate,
    this.solvedDate,
    this.attachments = const [],
    this.events = const [],
  });

  final String guid;
  final String ticketNo; // e.g. CMP-000001
  final String complaintType; // Sales | SpareParts | Maintenance | Other
  final String department;
  final String? subject;
  final String body;
  final String status; // New | Updated | Solved
  final DateTime? createdDate;
  final DateTime? updatedDate;
  final DateTime? solvedDate;
  final List<String> attachments; // CDN urls
  final List<ComplaintEvent> events;

  /// 3-step stage position: received → updated → solved.
  int get stageIndex => switch (status) {
        'Solved' => 2,
        'Updated' => 1,
        _ => 0,
      };

  /// The customer may reply only while the staff ball is back in their
  /// court (status Updated) — mirrors the website tracker.
  bool get canReply => status == 'Updated';

  factory Complaint.fromJson(Map<String, dynamic> json) => Complaint(
        guid: json['guid']?.toString() ?? '',
        ticketNo: json['ticketNo']?.toString() ?? '',
        complaintType: json['complaintType']?.toString() ?? 'Other',
        department: json['department']?.toString() ?? '',
        subject: json['subject']?.toString(),
        body: json['body']?.toString() ?? '',
        status: json['status']?.toString() ?? 'New',
        createdDate: DateTime.tryParse(json['createdDate']?.toString() ?? ''),
        updatedDate: DateTime.tryParse(json['updatedDate']?.toString() ?? ''),
        solvedDate: DateTime.tryParse(json['solvedDate']?.toString() ?? ''),
        attachments: (json['attachments'] as List<dynamic>? ?? const [])
            .map((e) => e.toString())
            .where((s) => s.isNotEmpty)
            .toList(),
        events: (json['events'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(ComplaintEvent.fromJson)
            .toList(),
      );
}

/// One conversation entry (customer message or staff reply).
final class ComplaintEvent {
  const ComplaintEvent({
    required this.authorType,
    this.note,
    this.statusAfter,
    this.createdAt,
    this.attachments = const [],
  });

  final String authorType; // Customer | Staff
  final String? note;
  final String? statusAfter;
  final DateTime? createdAt;
  final List<String> attachments;

  bool get isStaff => authorType == 'Staff';

  factory ComplaintEvent.fromJson(Map<String, dynamic> json) => ComplaintEvent(
        authorType: json['authorType']?.toString() ?? 'Customer',
        note: json['note']?.toString(),
        statusAfter: json['statusAfter']?.toString(),
        createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
        attachments: (json['attachments'] as List<dynamic>? ?? const [])
            .map((e) => e.toString())
            .where((s) => s.isNotEmpty)
            .toList(),
      );
}

/// A locally-picked photo staged for upload — bytes kept for the thumbnail,
/// base64-encoded (no data: prefix) only at submit time.
final class ComplaintAttachmentDraft {
  const ComplaintAttachmentDraft({
    required this.fileName,
    required this.mime,
    required this.bytes,
  });

  final String fileName;
  final String mime;
  final Uint8List bytes;
}
