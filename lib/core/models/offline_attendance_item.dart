import 'package:uuid/uuid.dart';

/// Offline attendance item for queuing scans when offline
class OfflineAttendanceItem {
  final String id;
  final String studentId;
  final String eventId;
  final String qrData;
  final DateTime scannedAt;
  final String scannedBy; // Admin/organizer who scanned
  final bool synced;
  final DateTime? syncedAt;

  OfflineAttendanceItem({
    String? id,
    required this.studentId,
    required this.eventId,
    required this.qrData,
    required this.scannedAt,
    required this.scannedBy,
    this.synced = false,
    this.syncedAt,
  }) : id = id ?? const Uuid().v4();

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'studentId': studentId,
      'eventId': eventId,
      'qrData': qrData,
      'scannedAt': scannedAt.toIso8601String(),
      'scannedBy': scannedBy,
      'synced': synced,
      'syncedAt': syncedAt?.toIso8601String(),
    };
  }

  /// Create from JSON
  factory OfflineAttendanceItem.fromJson(Map<String, dynamic> json) {
    return OfflineAttendanceItem(
      id: json['id'] as String,
      studentId: json['studentId'] as String,
      eventId: json['eventId'] as String,
      qrData: json['qrData'] as String,
      scannedAt: DateTime.parse(json['scannedAt'] as String),
      scannedBy: json['scannedBy'] as String,
      synced: json['synced'] as bool? ?? false,
      syncedAt: json['syncedAt'] != null
          ? DateTime.parse(json['syncedAt'] as String)
          : null,
    );
  }

  /// Copy with updated fields
  OfflineAttendanceItem copyWith({
    bool? synced,
    DateTime? syncedAt,
  }) {
    return OfflineAttendanceItem(
      id: id,
      studentId: studentId,
      eventId: eventId,
      qrData: qrData,
      scannedAt: scannedAt,
      scannedBy: scannedBy,
      synced: synced ?? this.synced,
      syncedAt: syncedAt ?? this.syncedAt,
    );
  }

  /// Check if item is pending sync
  bool get isPending => !synced;

  /// Check if scan is recent (within last hour)
  bool get isRecent {
    final hourAgo = DateTime.now().subtract(const Duration(hours: 1));
    return scannedAt.isAfter(hourAgo);
  }
}
