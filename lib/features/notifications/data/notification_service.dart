import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Model representing a notification
class NotificationModel {
  final String id;
  final String title;
  final String body;
  final String type; // 'event', 'certificate', 'general'
  final String? eventId;
  final String? imageBase64;
  final String targetRole; // 'all', 'student', 'admin'
  final DateTime createdAt;
  final bool isRead;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.eventId,
    this.imageBase64,
    this.targetRole = 'all',
    required this.createdAt,
    this.isRead = false,
  });

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      id: doc.id,
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      type: data['type'] ?? 'general',
      eventId: data['eventId'],
      imageBase64: data['imageBase64'],
      targetRole: data['targetRole'] ?? 'all',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: data['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'body': body,
      'type': type,
      'eventId': eventId,
      'imageBase64': imageBase64,
      'targetRole': targetRole,
      'createdAt': Timestamp.fromDate(createdAt),
      'isRead': isRead,
    };
  }
}

/// Service for handling notifications
class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'notifications';

  /// Send notification to all students about new event
  Future<void> sendEventNotification({
    required String eventTitle,
    required String eventId,
    required DateTime eventDate,
    String? eventImageBase64,
  }) async {
    try {
      final notification = NotificationModel(
        id: '',
        title: '📅 New Event: $eventTitle',
        body: 'A new event has been scheduled for ${eventDate.day}/${eventDate.month}/${eventDate.year}. Tap to view details and register!',
        type: 'event',
        eventId: eventId,
        imageBase64: eventImageBase64,
        targetRole: 'student',
        createdAt: DateTime.now(),
      );

      await _firestore.collection(_collection).add(notification.toFirestore());
      debugPrint('Notification sent successfully');
    } catch (e) {
      debugPrint('Failed to send notification: $e');
    }
  }

  /// Get all notifications for a role (simplified query - no composite index needed)
  Stream<List<NotificationModel>> getNotifications(String role) {
    // Simple query - get all notifications, filter client-side
    return _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => NotificationModel.fromFirestore(doc))
              .where((n) => n.targetRole == 'all' || n.targetRole == role)
              .toList();
        });
  }

  /// Get unread notifications count
  Stream<int> getUnreadCount(String role) {
    return _firestore
        .collection(_collection)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => NotificationModel.fromFirestore(doc))
              .where((n) => n.targetRole == 'all' || n.targetRole == role)
              .length;
        });
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore.collection(_collection).doc(notificationId).update({
        'isRead': true,
      });
    } catch (e) {
      debugPrint('Failed to mark notification as read: $e');
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead(String role) async {
    try {
      final batch = _firestore.batch();
      final notifications = await _firestore
          .collection(_collection)
          .where('isRead', isEqualTo: false)
          .get();

      for (var doc in notifications.docs) {
        final data = doc.data();
        final targetRole = data['targetRole'] ?? 'all';
        if (targetRole == 'all' || targetRole == role) {
          batch.update(doc.reference, {'isRead': true});
        }
      }

      await batch.commit();
    } catch (e) {
      debugPrint('Failed to mark all notifications as read: $e');
    }
  }

  /// Send broadcast notification to all students (from admin)
  Future<bool> sendBroadcastNotification({
    required String title,
    required String message,
  }) async {
    try {
      final notification = NotificationModel(
        id: '',
        title: '📢 $title',
        body: message,
        type: 'general',
        targetRole: 'student',
        createdAt: DateTime.now(),
      );

      await _firestore.collection(_collection).add(notification.toFirestore());
      debugPrint('Broadcast sent successfully');
      return true;
    } catch (e) {
      debugPrint('Failed to send broadcast: $e');
      return false;
    }
  }

  /// Send confirmation notification to organizer when they create a proposal
  Future<void> sendProposalConfirmation({
    required String proposalTitle,
    required String proposalId,
    required String organizerName,
  }) async {
    try {
      final notification = NotificationModel(
        id: '',
        title: '✅ Event Proposal Submitted',
        body: 'Your proposal "$proposalTitle" has been submitted successfully! We will review it and notify you once it\'s approved.',
        type: 'general',
        targetRole: 'student',
        createdAt: DateTime.now(),
      );

      await _firestore.collection(_collection).add(notification.toFirestore());
      debugPrint('Proposal confirmation sent to $organizerName');
    } catch (e) {
      debugPrint('Failed to send proposal confirmation: $e');
    }
  }
}
