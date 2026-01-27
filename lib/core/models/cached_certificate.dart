import 'dart:typed_data';
import 'dart:convert';

/// Cached certificate model for offline storage
class CachedCertificate {
  final String id; // Unique ID (eventId_studentId)
  final String eventId;
  final String studentId;
  final String eventTitle;
  final String studentName;
  final DateTime eventDate;
  final DateTime generatedAt;
  final String pdfBase64; // PDF bytes encoded as base64
  final bool isDownloaded;

  CachedCertificate({
    required this.id,
    required this.eventId,
    required this.studentId,
    required this.eventTitle,
    required this.studentName,
    required this.eventDate,
    required this.generatedAt,
    required this.pdfBase64,
    this.isDownloaded = false,
  });

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'eventId': eventId,
      'studentId': studentId,
      'eventTitle': eventTitle,
      'studentName': studentName,
      'eventDate': eventDate.toIso8601String(),
      'generatedAt': generatedAt.toIso8601String(),
      'pdfBase64': pdfBase64,
      'isDownloaded': isDownloaded,
    };
  }

  /// Create from JSON
  factory CachedCertificate.fromJson(Map<String, dynamic> json) {
    return CachedCertificate(
      id: json['id'] as String,
      eventId: json['eventId'] as String,
      studentId: json['studentId'] as String,
      eventTitle: json['eventTitle'] as String,
      studentName: json['studentName'] as String,
      eventDate: DateTime.parse(json['eventDate'] as String),
      generatedAt: DateTime.parse(json['generatedAt'] as String),
      pdfBase64: json['pdfBase64'] as String,
      isDownloaded: json['isDownloaded'] as bool? ?? false,
    );
  }

  /// Convert base64 to bytes
  Uint8List get pdfBytes {
    return base64Decode(pdfBase64);
  }

  /// Create from PDF bytes
  static CachedCertificate fromPdfBytes({
    required String id,
    required String eventId,
    required String studentId,
    required String eventTitle,
    required String studentName,
    required DateTime eventDate,
    required Uint8List pdfBytes,
  }) {
    return CachedCertificate(
      id: id,
      eventId: eventId,
      studentId: studentId,
      eventTitle: eventTitle,
      studentName: studentName,
      eventDate: eventDate,
      generatedAt: DateTime.now(),
      pdfBase64: base64Encode(pdfBytes),
    );
  }

  /// Check if cache is stale (older than 30 days)
  bool get isStale {
    final staleDate = DateTime.now().subtract(const Duration(days: 30));
    return generatedAt.isBefore(staleDate);
  }

  /// Copy with updated fields
  CachedCertificate copyWith({
    bool? isDownloaded,
  }) {
    return CachedCertificate(
      id: id,
      eventId: eventId,
      studentId: studentId,
      eventTitle: eventTitle,
      studentName: studentName,
      eventDate: eventDate,
      generatedAt: generatedAt,
      pdfBase64: pdfBase64,
      isDownloaded: isDownloaded ?? this.isDownloaded,
    );
  }
}
