import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uems/features/events/data/event_repository.dart';
import 'package:uems/features/events/domain/models/event_model.dart';
import 'package:uems/features/notifications/data/notification_service.dart';
import 'package:uems/core/services/certificate_api_service.dart';

/// Provider for managing event state
class EventProvider extends ChangeNotifier {
  final EventRepository _eventRepository = EventRepository();
  final NotificationService _notificationService = NotificationService();

  final CertificateApiService _apiService = CertificateApiService(); 
  StreamSubscription<List<EventModel>>? _eventsSubscription;

  List<EventModel> _allEvents = [];
  List<EventModel> _pendingEvents = [];
  List<EventModel> _approvedEvents = [];
  List<EventModel> _organizerEvents = [];
  Map<DateTime, List<EventModel>> _eventsByDate = {};
  EventModel? _selectedEvent;
  bool _isLoading = false;
  String? _error;

  // Getters
  List<EventModel> get allEvents => _allEvents;
  List<EventModel> get pendingEvents => _pendingEvents;
  List<EventModel> get approvedEvents => _approvedEvents;
  List<EventModel> get organizerEvents => _organizerEvents;
  Map<DateTime, List<EventModel>> get eventsByDate => _eventsByDate;
  EventModel? get selectedEvent => _selectedEvent;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Get only upcoming approved events (not past)
  List<EventModel> get upcomingApprovedEvents {
    return _allEvents.where((e) => e.isApproved && !e.isPast).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  /// Get only past events
  List<EventModel> get pastEvents {
    return _allEvents.where((e) => e.isPast).toList()
      ..sort((a, b) => b.date.compareTo(a.date)); // Most recent first
  }

  /// Get upcoming events only (for student display)
  List<EventModel> get upcomingEvents {
    return _approvedEvents.where((e) => !e.isPast).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  @override
  void dispose() {
    _eventsSubscription?.cancel();
    super.dispose();
  }

  /// Load all events with Real-Time updates
  void startRealtimeEvents() {
    _isLoading = true;
    notifyListeners();

    _eventsSubscription?.cancel();
    _eventsSubscription = _eventRepository.getEventsStream().listen(
      (events) {
        _allEvents = events;
        // Update derived lists
        _pendingEvents = events.where((e) => e.isPending).toList();
        _approvedEvents = events.where((e) => e.isApproved).toList();
        
        // Re-process calendar events if needed
        // (Simplified: just notify listeners, screens should rebuild)
        
        _isLoading = false;
        notifyListeners();
      },
      onError: (e) {
        _error = e.toString();
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  // Keep legacy load methods for explicit refreshing or specific queries if needed,
  // but startRealtimeEvents handles the main list.

  /// Load all events (legacy - calls realtime now)
  Future<void> loadAllEvents() async {
    startRealtimeEvents();
  }

  // ... (Other load methods can remain as is, but createEvent needs update)

  /// Create event (Syncs with Firebase AND Laravel API)
  Future<String?> createEvent(EventModel event) async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Create in Firestore
      final eventId = await _eventRepository.createEvent(event);
      _error = null;

      // 2. Sync to Laravel API (for Conflict Checking & SQL Storage)
      // Convert EventModel to API-friendly Map
      final apiMap = {
        'id': eventId, // Use Firestore ID if possible, or let API handle it
        'title': event.title,
        'description': event.description,
        'date': event.date.toIso8601String().split('T')[0], // YYYY-MM-DD
        'startTime': event.startTime,
        'endTime': event.endTime,
        'venue': event.venue,
        'organizerId': event.organizerId,
        'organizerName': event.organizerName,
        'status': event.status,
        'eventType': event.eventType,
        'entryFee': event.entryFee,
        'posterBase64': event.posterBase64,
        'certificateTemplateBase64': event.certificateTemplateBase64,
        'template_config': event.templateConfig,
      };

      await _apiService.createEvent(apiMap);
      
      // Send notification to all students if event is approved (admin created)
      if (event.status == 'approved' && eventId != null) {
        await _notificationService.sendEventNotification(
          eventTitle: event.title,
          eventId: eventId,
          eventDate: event.date,
          eventImageBase64: event.posterBase64,
        );
      }
      
      // Helper: No need to reload events if stream is active, but safeguard doesn't hurt.
      
      _isLoading = false;
      notifyListeners();
      return eventId;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Load pending events (for admin)
  Future<void> loadPendingEvents() async {
    _isLoading = true;
    notifyListeners();

    try {
      _pendingEvents = await _eventRepository.getPendingEvents();
      _error = null;
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Load approved events (for students)
  Future<void> loadApprovedEvents() async {
    _isLoading = true;
    notifyListeners();

    try {
      _approvedEvents = await _eventRepository.getApprovedEvents();
      _error = null;
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Load organizer's events
  Future<void> loadOrganizerEvents(String organizerId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _organizerEvents = await _eventRepository.getEventsByOrganizer(organizerId);
      _error = null;
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Load events for calendar (date range)
  Future<void> loadEventsForCalendar(DateTime start, DateTime end) async {
    try {
      final events = await _eventRepository.getEventsForDateRange(start, end);
      _eventsByDate = {};
      
      for (final event in events) {
        final dateKey = DateTime(event.date.year, event.date.month, event.date.day);
        if (_eventsByDate[dateKey] == null) {
          _eventsByDate[dateKey] = [];
        }
        _eventsByDate[dateKey]!.add(event);
      }
      
      notifyListeners();
    } catch (e) {
      _error = e.toString();
    }
  }

  /// Get events for a specific date
  List<EventModel> getEventsForDate(DateTime date) {
    final dateKey = DateTime(date.year, date.month, date.day);
    return _eventsByDate[dateKey] ?? [];
  }

  /// Load a single event
  Future<void> loadEvent(String eventId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _selectedEvent = await _eventRepository.getEventById(eventId);
      _error = null;
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }



  /// Approve event
  Future<bool> approveEvent(String eventId) async {
    try {
      await _eventRepository.approveEvent(eventId);
      
      // Update local list
      _pendingEvents.removeWhere((e) => e.id == eventId);
      notifyListeners();
      
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  /// Reject event
  Future<bool> rejectEvent(String eventId) async {
    try {
      await _eventRepository.rejectEvent(eventId);
      
      // Update local list
      _pendingEvents.removeWhere((e) => e.id == eventId);
      notifyListeners();
      
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  /// Update event
  Future<bool> updateEvent(String eventId, Map<String, dynamic> updates) async {
    try {
      await _eventRepository.updateEvent(eventId, updates);
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  /// Delete event
  Future<bool> deleteEvent(String eventId) async {
    try {
      // 1. Delete from Firestore (Real-time update)
      await _eventRepository.deleteEvent(eventId);
      
      // 2. Delete from Laravel API (Conflict Check clean-up)
      await _apiService.deleteEvent(eventId);
      
      // Update local lists (Though stream listener should handle it automatically)
      _allEvents.removeWhere((e) => e.id == eventId);
      _pendingEvents.removeWhere((e) => e.id == eventId);
      _approvedEvents.removeWhere((e) => e.id == eventId);
      _organizerEvents.removeWhere((e) => e.id == eventId);
      
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Clear selected event
  void clearSelectedEvent() {
    _selectedEvent = null;
    notifyListeners();
  }
}
