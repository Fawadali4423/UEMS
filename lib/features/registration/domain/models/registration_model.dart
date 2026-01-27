import 'package:cloud_firestore/cloud_firestore.dart';

/// Registration model for event registrations
class RegistrationModel {
  final String id;
  final String registrationId; // Unique display ID for QR
  final String eventId;
  final String studentId;
  final String? rollNumber; // Student roll number
  final String? studentName;
  final String? studentEmail;
  final String paymentStatus; // 'pending', 'completed', 'not_required'
  final String? paymentId;
  final double? amountPaid;
  final String? paymentProofUrl;
  final DateTime registeredAt;

  RegistrationModel({
    required this.id,
    required this.registrationId,
    required this.eventId,
    required this.studentId,
    this.rollNumber,
    this.studentName,
    this.studentEmail,
    this.paymentStatus = 'not_required',
    this.paymentId,
    this.amountPaid,
    this.paymentProofUrl,
    required this.registeredAt,
  });

  /// Create from Firestore
  factory RegistrationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RegistrationModel(
      id: doc.id,
      registrationId: data['registrationId'] ?? doc.id.substring(0, 8).toUpperCase(),
      eventId: data['eventId'] ?? '',
      studentId: data['studentId'] ?? '',
      rollNumber: data['rollNumber'],
      studentName: data['studentName'],
      studentEmail: data['studentEmail'],
      paymentStatus: data['paymentStatus'] ?? 'not_required',
      paymentId: data['paymentId'],
      amountPaid: (data['amountPaid'] as num?)?.toDouble(),
      paymentProofUrl: data['paymentProofUrl'],
      registeredAt: (data['registeredAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'registrationId': registrationId,
      'eventId': eventId,
      'studentId': studentId,
      'rollNumber': rollNumber,
      'studentName': studentName,
      'studentEmail': studentEmail,
      'paymentStatus': paymentStatus,
      'paymentId': paymentId,
      'amountPaid': amountPaid,
      'paymentProofUrl': paymentProofUrl,
      'registeredAt': Timestamp.fromDate(registeredAt),
    };
  }

  /// Generate document ID
  static String generateId(String eventId, String studentId) {
    return '${eventId}_$studentId';
  }

  /// Generate unique registration ID
  static String generateRegistrationId() {
    final now = DateTime.now();
    return 'REG${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}${now.millisecondsSinceEpoch.toString().substring(8)}';
  }

  /// Check if payment is required
  bool get isPaymentRequired => paymentStatus == 'pending';

  /// Check if payment is completed
  bool get isPaymentCompleted => paymentStatus == 'completed';
}

/// Pass model for QR passes
class PassModel {
  final String id;
  final String registrationId; // Unique registration ID
  final String eventId;
  final String eventName;
  final DateTime eventDate;
  final String studentId;
  final String? rollNumber;
  final String? studentName;
  final String? studentEmail;
  final String qrData;
  final bool isUsed;
  final DateTime createdAt;
  final DateTime? usedAt;

  PassModel({
    required this.id,
    required this.registrationId,
    required this.eventId,
    required this.eventName,
    required this.eventDate,
    required this.studentId,
    this.rollNumber,
    this.studentName,
    this.studentEmail,
    required this.qrData,
    this.isUsed = false,
    required this.createdAt,
    this.usedAt,
  });

  /// Create from Firestore
  factory PassModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PassModel(
      id: doc.id,
      registrationId: data['registrationId'] ?? '',
      eventId: data['eventId'] ?? '',
      eventName: data['eventName'] ?? '',
      eventDate: (data['eventDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      studentId: data['studentId'] ?? '',
      rollNumber: data['rollNumber'],
      studentName: data['studentName'],
      studentEmail: data['studentEmail'],
      qrData: data['qrData'] ?? '',
      isUsed: data['isUsed'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      usedAt: (data['usedAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'registrationId': registrationId,
      'eventId': eventId,
      'eventName': eventName,
      'eventDate': Timestamp.fromDate(eventDate),
      'studentId': studentId,
      'rollNumber': rollNumber,
      'studentName': studentName,
      'studentEmail': studentEmail,
      'qrData': qrData,
      'isUsed': isUsed,
      'createdAt': Timestamp.fromDate(createdAt),
      'usedAt': usedAt != null ? Timestamp.fromDate(usedAt!) : null,
    };
  }

  /// Copy with
  PassModel copyWith({
    bool? isUsed,
    DateTime? usedAt,
  }) {
    return PassModel(
      id: id,
      registrationId: registrationId,
      eventId: eventId,
      eventName: eventName,
      eventDate: eventDate,
      studentId: studentId,
      rollNumber: rollNumber,
      studentName: studentName,
      studentEmail: studentEmail,
      qrData: qrData,
      isUsed: isUsed ?? this.isUsed,
      createdAt: createdAt,
      usedAt: usedAt ?? this.usedAt,
    );
  }

  /// Check if pass is expired (event date has passed)
  bool get isExpired => eventDate.isBefore(DateTime.now());

  /// Generate document ID
  static String generateId(String eventId, String studentId) {
    return '${eventId}_$studentId';
  }
}
