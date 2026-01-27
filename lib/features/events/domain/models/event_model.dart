import 'package:cloud_firestore/cloud_firestore.dart';

/// Event model representing an event in the system
class EventModel {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final String startTime;
  final String endTime;
  final String venue;
  final String organizerId;
  final String organizerName;
  final String status; // 'pending', 'approved', 'rejected', 'completed'
  final String eventType; // 'free' or 'paid'
  final double? entryFee; // Entry fee in PKR (null for free events)
  final String? posterBase64;
  final String? certificateTemplateBase64;
  final Map<String, dynamic>? templateConfig;
  final int participantCount;
  final DateTime createdAt;
  final DateTime? updatedAt;

  EventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.venue,
    required this.organizerId,
    this.organizerName = '',
    this.status = 'pending',
    this.eventType = 'free',
    this.entryFee,
    this.posterBase64,
    this.certificateTemplateBase64,
    this.templateConfig,
    this.participantCount = 0,
    required this.createdAt,
    this.updatedAt,
  });

  /// Create EventModel from Firestore document
  factory EventModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EventModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      startTime: data['startTime'] ?? '',
      endTime: data['endTime'] ?? '',
      venue: data['venue'] ?? '',
      organizerId: data['organizerId'] ?? '',
      organizerName: data['organizerName'] ?? '',
      status: data['status'] ?? 'pending',
      eventType: data['eventType'] ?? 'free',
      entryFee: (data['entryFee'] as num?)?.toDouble(),
      posterBase64: data['posterBase64'],
      certificateTemplateBase64: data['certificateTemplateBase64'],
      templateConfig: data['templateConfig'],
      participantCount: data['participantCount'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Create EventModel from API JSON
  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: json['id'].toString(),
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      date: DateTime.parse(json['date']),
      startTime: json['start_time'] ?? '',
      endTime: json['end_time'] ?? '',
      venue: json['venue'] ?? '',
      organizerId: json['organizer_id'].toString(),
      organizerName: json['organizer_name'] ?? '',
      status: json['status'] ?? 'pending',
      eventType: json['event_type'] ?? 'free',
      entryFee: (json['entry_fee'] as num?)?.toDouble(),
      posterBase64: json['poster_base64'],
      certificateTemplateBase64: json['certificate_template_base64'],
      templateConfig: json['template_config'],
      participantCount: json['participant_count'] ?? 0,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }

  /// Convert EventModel to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'date': Timestamp.fromDate(date),
      'startTime': startTime,
      'endTime': endTime,
      'venue': venue,
      'organizerId': organizerId,
      'organizerName': organizerName,
      'status': status,
      'eventType': eventType,
      'entryFee': entryFee,
      'posterBase64': posterBase64,
      'certificateTemplateBase64': certificateTemplateBase64,
      'templateConfig': templateConfig,
      'participantCount': participantCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  /// Check if event is pending
  bool get isPending => status == 'pending';

  /// Check if event is approved
  bool get isApproved => status == 'approved';

  /// Check if event is rejected
  bool get isRejected => status == 'rejected';

  /// Check if event is completed
  bool get isCompleted => status == 'completed';

  /// Check if event is upcoming (including today)
  bool get isUpcoming {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final eventDate = DateTime(date.year, date.month, date.day);
    return eventDate.isAtSameMomentAs(today) || eventDate.isAfter(today);
  }

  /// Check if event is past (before today)
  bool get isPast {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final eventDate = DateTime(date.year, date.month, date.day);
    return eventDate.isBefore(today);
  }

  /// Check if event is paid
  bool get isPaid => eventType == 'paid';

  /// Check if event is free
  bool get isFree => eventType == 'free';

  @override
  String toString() {
    return 'EventModel(id: $id, title: $title, date: $date, status: $status)';
  }
}
