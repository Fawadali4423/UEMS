import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:uems/core/constants/app_constants.dart';
import 'package:uems/features/events/domain/models/event_model.dart';

/// Repository for event data operations in Firestore
class EventRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get reference to events collection
  CollectionReference<Map<String, dynamic>> get _eventsRef =>
      _firestore.collection(AppConstants.eventsCollection);

  /// Create a new event
  Future<String> createEvent(EventModel event) async {
    try {
      final docRef = await _eventsRef.add(event.toFirestore());
      debugPrint('Event created with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('Error creating event: $e');
      rethrow;
    }
  }

  /// Get event by ID
  Future<EventModel?> getEventById(String eventId) async {
    final doc = await _eventsRef.doc(eventId).get();
    if (!doc.exists) return null;
    return EventModel.fromFirestore(doc);
  }

  /// Get event stream by ID
  Stream<EventModel?> getEventStream(String eventId) {
    return _eventsRef.doc(eventId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return EventModel.fromFirestore(doc);
    });
  }

  /// Update event
  Future<void> updateEvent(String eventId, Map<String, dynamic> updates) async {
    updates['updatedAt'] = Timestamp.now();
    await _eventsRef.doc(eventId).update(updates);
  }

  /// Delete event
  Future<void> deleteEvent(String eventId) async {
    await _eventsRef.doc(eventId).delete();
  }

  /// Get all events (simple query - no index needed)
  Future<List<EventModel>> getAllEvents() async {
    final snapshot = await _eventsRef.get();
    final events = snapshot.docs.map((doc) => EventModel.fromFirestore(doc)).toList();
    // Sort client-side
    events.sort((a, b) => b.date.compareTo(a.date));
    return events;
  }

  /// Stream all events
  Stream<List<EventModel>> getEventsStream() {
    return _eventsRef.snapshots().map((snapshot) {
      final events = snapshot.docs.map((doc) => EventModel.fromFirestore(doc)).toList();
      events.sort((a, b) => b.date.compareTo(a.date));
      return events;
    });
  }

  /// Get events by status (simple where - no index needed)
  Future<List<EventModel>> getEventsByStatus(String status) async {
    try {
      final snapshot = await _eventsRef
          .where('status', isEqualTo: status)
          .get();
      final events = snapshot.docs.map((doc) => EventModel.fromFirestore(doc)).toList();
      // Sort client-side
      events.sort((a, b) => a.date.compareTo(b.date));
      return events;
    } catch (e) {
      debugPrint('Error getting events by status: $e');
      return [];
    }
  }

  /// Stream events by status
  Stream<List<EventModel>> getEventsByStatusStream(String status) {
    return _eventsRef
        .where('status', isEqualTo: status)
        .snapshots()
        .map((snapshot) {
          final events = snapshot.docs.map((doc) => EventModel.fromFirestore(doc)).toList();
          events.sort((a, b) => a.date.compareTo(b.date));
          return events;
        });
  }

  /// Get pending events
  Future<List<EventModel>> getPendingEvents() async {
    return getEventsByStatus(AppConstants.statusPending);
  }

  /// Stream pending events
  Stream<List<EventModel>> getPendingEventsStream() {
    return getEventsByStatusStream(AppConstants.statusPending);
  }

  /// Get approved events
  Future<List<EventModel>> getApprovedEvents() async {
    return getEventsByStatus(AppConstants.statusApproved);
  }

  /// Stream approved events
  Stream<List<EventModel>> getApprovedEventsStream() {
    return getEventsByStatusStream(AppConstants.statusApproved);
  }

  /// Get events by organizer
  Future<List<EventModel>> getEventsByOrganizer(String organizerId) async {
    try {
      final snapshot = await _eventsRef
          .where('organizerId', isEqualTo: organizerId)
          .get();
      final events = snapshot.docs.map((doc) => EventModel.fromFirestore(doc)).toList();
      events.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return events;
    } catch (e) {
      debugPrint('Error getting events by organizer: $e');
      return [];
    }
  }

  /// Stream events by organizer
  Stream<List<EventModel>> getEventsByOrganizerStream(String organizerId) {
    return _eventsRef
        .where('organizerId', isEqualTo: organizerId)
        .snapshots()
        .map((snapshot) {
          final events = snapshot.docs.map((doc) => EventModel.fromFirestore(doc)).toList();
          events.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return events;
        });
  }

  /// Approve event
  Future<void> approveEvent(String eventId) async {
    await updateEvent(eventId, {'status': AppConstants.statusApproved});
  }

  /// Reject event
  Future<void> rejectEvent(String eventId) async {
    await updateEvent(eventId, {'status': AppConstants.statusRejected});
  }

  /// Mark event as completed
  Future<void> completeEvent(String eventId) async {
    await updateEvent(eventId, {'status': AppConstants.statusCompleted});
  }

  /// Increment participant count
  Future<void> incrementParticipantCount(String eventId) async {
    await _eventsRef.doc(eventId).update({
      'participantCount': FieldValue.increment(1),
      'updatedAt': Timestamp.now(),
    });
  }

  /// Decrement participant count
  Future<void> decrementParticipantCount(String eventId) async {
    await _eventsRef.doc(eventId).update({
      'participantCount': FieldValue.increment(-1),
      'updatedAt': Timestamp.now(),
    });
  }

  /// Get events for a specific date (simplified - client-side filtering)
  Future<List<EventModel>> getEventsForDate(DateTime date) async {
    try {
      final snapshot = await _eventsRef
          .where('status', isEqualTo: AppConstants.statusApproved)
          .get();

      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      return snapshot.docs
          .map((doc) => EventModel.fromFirestore(doc))
          .where((event) => 
              event.date.isAfter(startOfDay.subtract(const Duration(seconds: 1))) &&
              event.date.isBefore(endOfDay.add(const Duration(seconds: 1))))
          .toList();
    } catch (e) {
      debugPrint('Error getting events for date: $e');
      return [];
    }
  }

  /// Get events for date range (for calendar - simplified)
  Future<List<EventModel>> getEventsForDateRange(DateTime start, DateTime end) async {
    try {
      final snapshot = await _eventsRef
          .where('status', isEqualTo: AppConstants.statusApproved)
          .get();

      return snapshot.docs
          .map((doc) => EventModel.fromFirestore(doc))
          .where((event) => 
              event.date.isAfter(start.subtract(const Duration(days: 1))) &&
              event.date.isBefore(end.add(const Duration(days: 1))))
          .toList();
    } catch (e) {
      debugPrint('Error getting events for date range: $e');
      return [];
    }
  }

  /// Get upcoming events
  Future<List<EventModel>> getUpcomingEvents() async {
    try {
      final now = DateTime.now();
      final snapshot = await _eventsRef
          .where('status', isEqualTo: AppConstants.statusApproved)
          .get();

      final events = snapshot.docs
          .map((doc) => EventModel.fromFirestore(doc))
          .where((event) => event.date.isAfter(now))
          .toList();
      
      events.sort((a, b) => a.date.compareTo(b.date));
      return events.take(10).toList();
    } catch (e) {
      debugPrint('Error getting upcoming events: $e');
      return [];
    }
  }

  /// Search events by title
  Future<List<EventModel>> searchEvents(String query) async {
    try {
      final queryLower = query.toLowerCase();
      final snapshot = await _eventsRef
          .where('status', isEqualTo: AppConstants.statusApproved)
          .get();

      return snapshot.docs
          .map((doc) => EventModel.fromFirestore(doc))
          .where((event) => event.title.toLowerCase().contains(queryLower))
          .take(20)
          .toList();
    } catch (e) {
      debugPrint('Error searching events: $e');
      return [];
    }
  }
}
