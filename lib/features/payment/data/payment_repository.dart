import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uems/features/payment/domain/models/payment_model.dart';
import 'package:uems/features/payment/domain/models/payment_result.dart';
import 'package:uuid/uuid.dart';

class PaymentRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  // Collection reference
  CollectionReference get _paymentsRef => _firestore.collection('event_payments');

  /// Submit a new manual payment
  Future<PaymentResult> submitPayment({
    required String eventId,
    required String studentId,
    required double amount,
    required PaymentMethod method,
    required String transactionId, // User entered ID
    String? screenshotUrl,
  }) async {
    try {
      final id = _uuid.v4();
      final now = DateTime.now();
      
      final payment = PaymentModel(
        id: id,
        eventId: eventId,
        studentId: studentId,
        amount: amount,
        method: method,
        status: PaymentStatus.pending,
        manualTransactionId: transactionId,
        screenshotUrl: screenshotUrl,
        createdAt: now,
      );

      await _paymentsRef.doc(id).set(payment.toMap());

      return PaymentResult(
        success: true,
        transactionId: id, // Internal ID
        method: method,
        amount: amount,
      );
    } catch (e) {
      return PaymentResult(
        success: false,
        errorMessage: 'Failed to submit payment: ${e.toString()}',
      );
    }
  }

  /// Get pending payments for admin
  Stream<List<PaymentModel>> getPendingPayments() {
    return _paymentsRef
        .where('status', isEqualTo: PaymentStatus.pending.index)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return PaymentModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  /// Get payments for a specific event (Admin/Organizer view)
  Stream<List<PaymentModel>> getEventPayments(String eventId) {
    return _paymentsRef
        .where('eventId', isEqualTo: eventId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return PaymentModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  /// Get student's payment for a specific event
  Future<PaymentModel?> getStudentPaymentForEvent(String eventId, String studentId) async {
    final snapshot = await _paymentsRef
        .where('eventId', isEqualTo: eventId)
        .where('studentId', isEqualTo: studentId)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    
    return PaymentModel.fromMap(snapshot.docs.first.data() as Map<String, dynamic>, snapshot.docs.first.id);
  }

  /// Update payment status (Approve/Reject)
  Future<void> updatePaymentStatus({
    required String paymentId,
    required PaymentStatus status,
    String? adminComment,
  }) async {
    final updates = <String, dynamic>{
      'status': status.index,
      'completedAt': DateTime.now().toIso8601String(),
    };

    if (adminComment != null) {
      updates['adminComment'] = adminComment;
    }

    await _paymentsRef.doc(paymentId).update(updates);
  }

  /// Get payment by ID
  Future<PaymentModel?> getPaymentById(String paymentId) async {
    final doc = await _paymentsRef.doc(paymentId).get();
    if (!doc.exists) return null;
    return PaymentModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }
}
