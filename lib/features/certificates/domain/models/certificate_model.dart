import 'package:cloud_firestore/cloud_firestore.dart';

/// Certificate model for generated certificates
class CertificateModel {
  final String id;
  final String eventId;
  final String eventTitle;
  final String studentId;
  final String studentName;
  final DateTime eventDate;
  final DateTime generatedAt;
  final String? pdfUrl; // URL from Laravel API

  CertificateModel({
    required this.id,
    required this.eventId,
    required this.eventTitle,
    required this.studentId,
    required this.studentName,
    required this.eventDate,
    required this.generatedAt,
    this.pdfUrl,
  });

  /// Create from Firestore
  factory CertificateModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CertificateModel(
      id: doc.id,
      eventId: data['eventId'] ?? '',
      eventTitle: data['eventTitle'] ?? '',
      studentId: data['studentId'] ?? '',
      studentName: data['studentName'] ?? '',
      eventDate: (data['eventDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      generatedAt: (data['generatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      pdfUrl: data['pdfUrl'],
    );
  }

  /// Convert to Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'eventId': eventId,
      'eventTitle': eventTitle,
      'studentId': studentId,
      'studentName': studentName,
      'eventDate': Timestamp.fromDate(eventDate),
      'generatedAt': Timestamp.fromDate(generatedAt),
      if (pdfUrl != null) 'pdfUrl': pdfUrl,
    };
  }

  /// Generate document ID
  static String generateId(String eventId, String studentId) {
    return '${eventId}_$studentId';
  }
}
