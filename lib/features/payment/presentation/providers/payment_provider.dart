import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uems/features/payment/data/payment_repository.dart';
import 'package:uems/features/payment/domain/models/payment_model.dart';
import 'package:uems/features/payment/domain/models/payment_result.dart';
import 'package:uems/features/registration/data/registration_repository.dart';

/// Provider for managing payment state
class PaymentProvider extends ChangeNotifier {
  final PaymentRepository _paymentRepository = PaymentRepository();
  final RegistrationRepository _registrationRepository = RegistrationRepository();

  bool _isLoading = false;
  String? _error;
  PaymentResult? _lastResult;
  PaymentMethod? _selectedMethod;
  List<PaymentModel> _pendingPayments = [];
  
  StreamSubscription<List<PaymentModel>>? _paymentSubscription;

  @override
  void dispose() {
    _paymentSubscription?.cancel();
    super.dispose();
  }

  bool get isLoading => _isLoading;
  String? get error => _error;
  PaymentResult? get lastResult => _lastResult;
  PaymentMethod? get selectedMethod => _selectedMethod;
  int get pendingPaymentCount => _pendingPayments.length;

  /// Select payment method
  void selectMethod(PaymentMethod method) {
    _selectedMethod = method;
    notifyListeners();
  }

  /// Process manual payment submission
  Future<PaymentResult?> submitManualPayment({
    required String eventId,
    required String studentId,
    required double amount,
    required String transactionId,
    String? screenshotUrl,
  }) async {
    if (_selectedMethod == null) {
      _error = 'Please select a payment method';
      notifyListeners();
      return null;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _paymentRepository.submitPayment(
        eventId: eventId,
        studentId: studentId,
        amount: amount,
        method: _selectedMethod!,
        transactionId: transactionId,
        screenshotUrl: screenshotUrl,
      );

      _lastResult = result;
      
      if (!result.success) {
        _error = result.errorMessage;
      }

      _isLoading = false;
      notifyListeners();
      return result;
    } catch (e) {
      _error = 'Payment failed: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Get student's payment status for an event
  Future<PaymentModel?> getPaymentForEvent(String eventId, String studentId) async {
    try {
      return await _paymentRepository.getStudentPaymentForEvent(eventId, studentId);
    } catch (e) {
      print('Error checking payment status: $e');
      return null;
    }
  }
  
  // Admin Methods

  /// Load pending payments
  void loadPendingPayments() {
    _paymentSubscription?.cancel();
    _paymentSubscription = getPendingPayments().listen((payments) {
      _pendingPayments = payments;
      notifyListeners();
    }, onError: (e) {
      print('Error loading pending payments: $e');
    });
  }

  Stream<List<PaymentModel>> getPendingPayments() {
    return _paymentRepository.getPendingPayments();
  }

  Future<void> approvePayment(String paymentId) async {
    try {
      // 1. Update Payment Status in Firestore
      await _paymentRepository.updatePaymentStatus(
        paymentId: paymentId, 
        status: PaymentStatus.completed
      );

      // 2. Fetch payment details to get student info
      final payment = await _paymentRepository.getPaymentById(paymentId);
      
      if (payment != null) {
        // 3. Update Registration (which regenerates the Pass with QR hash)
        await _registrationRepository.updatePaymentStatus(
          eventId: payment.eventId,
          studentId: payment.studentId,
          paymentId: paymentId,
          amountPaid: payment.amount,
        );
      }
      
      notifyListeners();
    } catch (e) {
      print('Error approving payment: $e');
      rethrow;
    }
  }

  Future<void> rejectPayment(String paymentId, String reason) async {
    await _paymentRepository.updatePaymentStatus(
      paymentId: paymentId, 
      status: PaymentStatus.failed,
      adminComment: reason
    );
    notifyListeners();
  }

  /// Reset payment state
  void reset() {
    _isLoading = false;
    _error = null;
    _lastResult = null;
    _selectedMethod = null;
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
