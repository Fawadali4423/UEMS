/// Cached QR pass model for offline storage
class CachedQrPass {
  final String id; // Unique ID (eventId_studentId)
  final String registrationId;
  final String eventId;
  final String eventName;
  final DateTime eventDate;
  final String studentId;
  final String? rollNumber;
  final String? studentName;
  final String? studentEmail;
  final String qrData;
  final bool isUsed;
  final DateTime cachedAt;

  CachedQrPass({
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
    required this.cachedAt,
  });

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'registrationId': registrationId,
      'eventId': eventId,
      'eventName': eventName,
      'eventDate': eventDate.toIso8601String(),
      'studentId': studentId,
      'rollNumber': rollNumber,
      'studentName': studentName,
      'studentEmail': studentEmail,
      'qrData': qrData,
      'isUsed': isUsed,
      'cachedAt': cachedAt.toIso8601String(),
    };
  }

  /// Create from JSON
  factory CachedQrPass.fromJson(Map<String, dynamic> json) {
    return CachedQrPass(
      id: json['id'] as String,
      registrationId: json['registrationId'] as String,
      eventId: json['eventId'] as String,
      eventName: json['eventName'] as String,
      eventDate: DateTime.parse(json['eventDate'] as String),
      studentId: json['studentId'] as String,
      rollNumber: json['rollNumber'] as String?,
      studentName: json['studentName'] as String?,
      studentEmail: json['studentEmail'] as String?,
      qrData: json['qrData'] as String,
      isUsed: json['isUsed'] as bool? ?? false,
      cachedAt: DateTime.parse(json['cachedAt'] as String),
    );
  }

  /// Check if pass is expired (event date has passed)
  bool get isExpired => eventDate.isBefore(DateTime.now());

  /// Check if cache is stale (older than 7 days)
  bool get isStale {
    final staleDate = DateTime.now().subtract(const Duration(days: 7));
    return cachedAt.isBefore(staleDate);
  }
}
