import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uems/core/constants/app_constants.dart';
import 'package:uems/features/registration/domain/models/registration_model.dart';

/// Repository for registration and pass operations
class RegistrationRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _registrationsRef =>
      _firestore.collection(AppConstants.registrationsCollection);

  CollectionReference<Map<String, dynamic>> get _passesRef =>
      _firestore.collection(AppConstants.passesCollection);

  CollectionReference<Map<String, dynamic>> get _eventsRef =>
      _firestore.collection(AppConstants.eventsCollection);

  /// Register for an event (free events)
  Future<String> registerForEvent({
    required String eventId,
    required String eventName,
    required DateTime eventDate,
    required String studentId,
    required String rollNumber,
    required String studentName,
    required String studentEmail,
    bool isPaidEvent = false,
    double? entryFee,
    String? paymentId,
  }) async {
    final docId = RegistrationModel.generateId(eventId, studentId);
    
    // Check if already registered
    final existing = await _registrationsRef.doc(docId).get();
    if (existing.exists) {
      throw Exception('Already registered for this event');
    }

    // Generate registration ID
    final registrationId = RegistrationModel.generateRegistrationId();

    // Determine payment status
    String paymentStatus;
    double? amountPaid;
    if (!isPaidEvent) {
      paymentStatus = 'not_required';
    } else if (paymentId != null) {
      paymentStatus = 'completed';
      amountPaid = entryFee;
    } else {
      paymentStatus = 'pending';
    }

    // Create registration with student details
    final registration = RegistrationModel(
      id: docId,
      registrationId: registrationId,
      eventId: eventId,
      studentId: studentId,
      rollNumber: rollNumber,
      studentName: studentName,
      studentEmail: studentEmail,
      paymentStatus: paymentStatus,
      paymentId: paymentId,
      amountPaid: amountPaid,
      registeredAt: DateTime.now(),
    );

    await _registrationsRef.doc(docId).set(registration.toFirestore());

    // Generate QR pass with comprehensive info
    await _generatePass(
      registrationId: registrationId,
      eventId: eventId,
      eventName: eventName,
      eventDate: eventDate,
      studentId: studentId,
      rollNumber: rollNumber,
      studentName: studentName,
      studentEmail: studentEmail,
      paymentId: paymentId,
    );

    // Update participant count
    await _eventsRef.doc(eventId).update({
      'participantCount': FieldValue.increment(1),
    });

    return registrationId;
  }

  /// Generate QR pass for registration
  Future<void> _generatePass({
    required String registrationId,
    required String eventId,
    required String eventName,
    required DateTime eventDate,
    required String studentId,
    required String rollNumber,
    required String studentName,
    required String studentEmail,
    String? paymentId,
  }) async {
    final passId = PassModel.generateId(eventId, studentId);
    
    // Generate verification hash if payment exists
    String? verificationHash;
    if (paymentId != null) {
      final input = '${paymentId}_${studentId}_UEMS_SECURE';
      verificationHash = base64Encode(utf8.encode(input));
    }

    // Generate comprehensive QR data as JSON
    final qrDataMap = {
      'type': 'UEMS_PASS',
      'registrationId': registrationId,
      'eventId': eventId,
      'eventName': eventName,
      'eventDate': eventDate.toIso8601String(),
      'studentId': studentId,
      'rollNumber': rollNumber,
      'studentName': studentName,
      if (paymentId != null) 'paymentId': paymentId,
      if (verificationHash != null) 'verificationHash': verificationHash,
    };
    final qrData = jsonEncode(qrDataMap);

    final pass = PassModel(
      id: passId,
      registrationId: registrationId,
      eventId: eventId,
      eventName: eventName,
      eventDate: eventDate,
      studentId: studentId,
      rollNumber: rollNumber,
      studentName: studentName,
      studentEmail: studentEmail,
      qrData: qrData,
      createdAt: DateTime.now(),
    );

    await _passesRef.doc(passId).set(pass.toFirestore());
  }

  /// Check if student is registered for event
  Future<bool> isRegistered(String eventId, String studentId) async {
    final docId = RegistrationModel.generateId(eventId, studentId);
    final doc = await _registrationsRef.doc(docId).get();
    return doc.exists;
  }

  /// Get registration
  Future<RegistrationModel?> getRegistration(String eventId, String studentId) async {
    final docId = RegistrationModel.generateId(eventId, studentId);
    final doc = await _registrationsRef.doc(docId).get();
    if (!doc.exists) return null;
    return RegistrationModel.fromFirestore(doc);
  }

  /// Get pass for registration
  Future<PassModel?> getPass(String eventId, String studentId) async {
    final passId = PassModel.generateId(eventId, studentId);
    final doc = await _passesRef.doc(passId).get();
    if (!doc.exists) return null;
    return PassModel.fromFirestore(doc);
  }

  /// Get all passes for a student
  Future<List<PassModel>> getStudentPasses(String studentId) async {
    try {
      final snapshot = await _passesRef
          .where('studentId', isEqualTo: studentId)
          .get();

      final passes = snapshot.docs
          .map((doc) => PassModel.fromFirestore(doc))
          .toList();
      
      // Sort by creation date in memory
      passes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return passes;
    } catch (e) {
      return [];
    }
  }

  /// Get all registrations for a student
  Future<List<RegistrationModel>> getStudentRegistrations(String studentId) async {
    try {
      final snapshot = await _registrationsRef
          .where('studentId', isEqualTo: studentId)
          .get();

      final registrations = snapshot.docs
          .map((doc) => RegistrationModel.fromFirestore(doc))
          .toList();
      
      // Sort by registration date in memory
      registrations.sort((a, b) => b.registeredAt.compareTo(a.registeredAt));
      
      return registrations;
    } catch (e) {
      return [];
    }
  }

  /// Stream student registrations (Real-time)
  Stream<List<RegistrationModel>> getStudentRegistrationsStream(String studentId) {
    return _registrationsRef
        .where('studentId', isEqualTo: studentId)
        .snapshots()
        .map((snapshot) {
          final registrations = snapshot.docs
              .map((doc) => RegistrationModel.fromFirestore(doc))
              .toList();
          registrations.sort((a, b) => b.registeredAt.compareTo(a.registeredAt));
          return registrations;
        });
  }

  /// Stream student passes (Real-time)
  Stream<List<PassModel>> getStudentPassesStream(String studentId) {
    return _passesRef
        .where('studentId', isEqualTo: studentId)
        .snapshots()
        .map((snapshot) {
          final passes = snapshot.docs
              .map((doc) => PassModel.fromFirestore(doc))
              .toList();
          passes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return passes;
        });
  }

  /// Get all registrations for an event
  Future<List<RegistrationModel>> getEventRegistrations(String eventId) async {
    try {
      final snapshot = await _registrationsRef
          .where('eventId', isEqualTo: eventId)
          .get();

      final registrations = snapshot.docs
          .map((doc) => RegistrationModel.fromFirestore(doc))
          .toList();
      
      // Sort by registration date in memory
      registrations.sort((a, b) => b.registeredAt.compareTo(a.registeredAt));
      
      return registrations;
    } catch (e) {
      // Return empty list on error
      return [];
    }
  }

  /// Update payment status
  Future<void> updatePaymentStatus({
    required String eventId,
    required String studentId,
    required String paymentId,
    required double amountPaid,
  }) async {
    final docId = RegistrationModel.generateId(eventId, studentId);
    
    await _registrationsRef.doc(docId).update({
      'paymentId': paymentId,
      'amountPaid': amountPaid,
      'paymentStatus': 'completed',
    });

    // Fetch registration to get details for pass generation
    final registration = await getRegistration(eventId, studentId);
    if (registration != null) {
      // Fetch event details
      final eventDoc = await _eventsRef.doc(eventId).get();
      final eventName = eventDoc.data()?['title'] as String? ?? 'Event';
      final eventDate = (eventDoc.data()?['date'] as Timestamp?)?.toDate() ?? DateTime.now();

      await _generatePass(
        registrationId: registration.registrationId,
        eventId: eventId,
        eventName: eventName,
        eventDate: eventDate,
        studentId: studentId,
        rollNumber: registration.rollNumber ?? '',
        studentName: registration.studentName ?? '',
        studentEmail: registration.studentEmail ?? '',
        paymentId: paymentId,
      );
    }
  }

  /// Mark pass as used
  Future<void> markPassAsUsed(String eventId, String studentId) async {
    final passId = PassModel.generateId(eventId, studentId);
    await _passesRef.doc(passId).update({
      'isUsed': true,
      'usedAt': Timestamp.now(),
    });
  }

  /// Validate QR data and return pass if valid
  Future<PassModel?> validateQrData(String qrData) async {
    try {
      // Try to parse as JSON (new format)
      final data = jsonDecode(qrData) as Map<String, dynamic>;
      if (data['type'] != 'UEMS_PASS') return null;
      
      final eventId = data['eventId'] as String?;
      final studentId = data['studentId'] as String?;
      
      if (eventId == null || studentId == null) return null;
      
      final pass = await getPass(eventId, studentId);
      return pass;
    } catch (_) {
      // Try legacy format: UEMS_PASS|eventId|studentId|...
      final parts = qrData.split('|');
      if (parts.length < 3 || parts[0] != 'UEMS_PASS') {
        return null;
      }

      final eventId = parts[1];
      final studentId = parts[2];

      final pass = await getPass(eventId, studentId);
      return pass;
    }
  }

  /// Cancel registration
  Future<void> cancelRegistration(String eventId, String studentId) async {
    final docId = RegistrationModel.generateId(eventId, studentId);
    final passId = PassModel.generateId(eventId, studentId);

    await _registrationsRef.doc(docId).delete();
    await _passesRef.doc(passId).delete();

    await _eventsRef.doc(eventId).update({
      'participantCount': FieldValue.increment(-1),
    });
  }

  /// Get registration count for event
  Future<int> getRegistrationCount(String eventId) async {
    final snapshot = await _registrationsRef
        .where('eventId', isEqualTo: eventId)
        .count()
        .get();
    return snapshot.count ?? 0;
  }

  /// Search registrations for an event by name or roll number
  Future<List<RegistrationModel>> searchEventRegistrations({
    required String eventId,
    required String query,
  }) async {
    final queryUpper = query.toUpperCase();
    
    // Get all registrations for event then filter
    final allRegs = await getEventRegistrations(eventId);
    
    return allRegs.where((reg) {
      final nameMatch = reg.studentName?.toLowerCase().contains(query.toLowerCase()) ?? false;
      final rollMatch = reg.rollNumber?.toUpperCase().contains(queryUpper) ?? false;
      return nameMatch || rollMatch;
    }).toList();
  }
}
