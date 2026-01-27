import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uems/core/constants/app_constants.dart';

/// Repository for attendance operations
class AttendanceRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _attendanceRef =>
      _firestore.collection(AppConstants.attendanceCollection);

  /// Mark attendance for a student
  Future<void> markAttendance(String eventId, String studentId) async {
    await _attendanceRef.doc(eventId).set(
      {studentId: true},
      SetOptions(merge: true),
    );
  }

  /// Check if student has attended
  Future<bool> hasAttended(String eventId, String studentId) async {
    final doc = await _attendanceRef.doc(eventId).get();
    if (!doc.exists) return false;
    final data = doc.data();
    return data?[studentId] == true;
  }

  /// Get all attendees for an event
  Future<List<String>> getEventAttendees(String eventId) async {
    final doc = await _attendanceRef.doc(eventId).get();
    if (!doc.exists) return [];
    final data = doc.data();
    if (data == null) return [];
    return data.keys.where((key) => data[key] == true).toList();
  }

  /// Get attendance count for an event
  Future<int> getAttendanceCount(String eventId) async {
    final attendees = await getEventAttendees(eventId);
    return attendees.length;
  }

  /// Remove attendance (in case of error)
  Future<void> removeAttendance(String eventId, String studentId) async {
    await _attendanceRef.doc(eventId).update({
      studentId: FieldValue.delete(),
    });
  }

  /// Check if student attended any events
  Future<List<String>> getStudentAttendedEvents(String studentId) async {
    final snapshot = await _attendanceRef.get();
    final attendedEvents = <String>[];
    
    for (final doc in snapshot.docs) {
      final data = doc.data();
      if (data[studentId] == true) {
        attendedEvents.add(doc.id);
      }
    }
    
    return attendedEvents;
  }

  /// Get student attendance with event details
  Future<List<Map<String, dynamic>>> getStudentAttendance(String studentId) async {
    final snapshot = await _firestore
        .collectionGroup('attendance')
        .where('studentId', isEqualTo: studentId)
        .orderBy('timestamp', descending: true)
        .get();
    
    return snapshot.docs.map((doc) => doc.data()).toList();
  }
  /// Get all student attendance stats
  Future<Map<String, int>> getAllStudentAttendance() async {
    final snapshot = await _firestore.collectionGroup('attendance').get();
    
    // Map: studentId -> attendanceCount
    final stats = <String, int>{};
    
    for (final doc in snapshot.docs) {
      // Assuming structure is { 'student123': true } or doc contains 'studentId'
      // Based on markAttendance method: doc(eventId).set({studentId: true})
      
      final data = doc.data();
      // Since the structure is event_doc -> { studentId: true, studentId2: true }
      // The collectionGroup query might be problematic if we don't know the exact structure.
      // 
      // Re-checking markAttendance structure:
      // _attendanceRef.doc(eventId).set({studentId: true})
      // So 'attendance' is a top-level collection where Doc ID = Event ID
      // And fields are student IDs.
      
      data.forEach((key, value) {
        if (value == true) {
          stats[key] = (stats[key] ?? 0) + 1;
        }
      });
    }
    
    return stats;
  }
}
