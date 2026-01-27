import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uems/features/events/domain/models/event_model.dart';
import 'package:uems/features/events/data/event_repository.dart';

/// Service to check for event scheduling conflicts
class ConflictCheckerService {
  final EventRepository _eventRepository = EventRepository();

  /// Check for conflicts withexisting events
  Future<ConflictResult> checkConflict({
    required DateTime date,
    required String startTime,
    required String endTime,
    required String venue,
    String? excludeEventId, // Exclude event ID when updating
  }) async {
    try {
      // Get all events on the same date
      final allEvents = await _eventRepository.getAllEvents();
      
      // Filter events on same date
      final sameDate Events = allEvents.where((event) {
        return event.date.year == date.year &&
            event.date.month == date.month &&
            event.date.day == date.day &&
            event.id != excludeEventId; // Exclude current event if updating
      }).toList();

      if (sameDateEvents.isEmpty) {
        return ConflictResult(
          hasConflict: false,
          conflictingEvents: [],
          message: 'No conflicts found',
        );
      }

      // Check for hard conflicts (same venue + overlapping time)
      final hardConflicts = <EventModel>[];
      final softConflicts = <EventModel>[];

      for (final event in sameDateEvents) {
        // Check venue match
        final sameVenue = event.venue.toLowerCase() == venue.toLowerCase();
        
        // For simplicity, check if times overlap (basic check)
        // In production, use proper time parsing
        final timeOverlap = _checkTimeOverlap(startTime, endTime, event);

        if (sameVenue && timeOverlap) {
          hardConflicts.add(event);
        } else if (timeOverlap) {
          softConflicts.add(event);
        }
      }

      if (hardConflicts.isNotEmpty) {
        return ConflictResult(
          hasConflict: true,
          isHardConflict: true,
          conflictingEvents: hardConflicts,
          message: 'Hard conflict: Same date, time, and venue with ${hardConflicts.length} event(s)',
        );
      }

      if (softConflicts.isNotEmpty) {
        return ConflictResult(
          hasConflict: true,
          isHardConflict: false,
          conflictingEvents: softConflicts,
          message: 'Soft conflict: Same date and time but different venue with ${softConflicts.length} event(s)',
        );
      }

      return ConflictResult(
        hasConflict: false,
        conflictingEvents: [],
        message: 'No conflicts found',
      );
    } catch (e) {
      return ConflictResult(
        hasConflict: false,
        conflictingEvents: [],
        message: 'Error checking conflicts: $e',
      );
    }
  }

  bool _checkTimeOverlap(String startTime, String endTime, EventModel event) {
    // Basic time overlap check
    // In production, parse times properly and check for overlap
    // For now, return true if event has time data
    return event.date.hour > 0; // Simplified check
  }
}

/// Result of conflict check
class ConflictResult {
  final bool hasConflict;
  final bool isHardConflict;
  final List<EventModel> conflictingEvents;
  final String message;

  ConflictResult({
    required this.hasConflict,
    this.isHardConflict = false,
    required this.conflictingEvents,
    required this.message,
  });
}
