import 'dart:math';
import 'package:uems/features/payment/domain/models/payment_model.dart';

/// Simulated payment service for JazzCash and EasyPaisa
/// In production, this would integrate with actual payment APIs
class PaymentService {
  /// Process a payment (simulated)
  /// Returns a PaymentResult with success status and transaction ID
  Future<PaymentResult> processPayment({
    required String eventId,
    required String studentId,
    required double amount,
    required PaymentMethod method,
    required String phoneNumber,
  }) async {
    // Simulate payment processing delay
    await Future.delayed(const Duration(seconds: 2));

    // Validate phone number format for Pakistani mobile
    if (!_isValidPakistaniPhone(phoneNumber)) {
      return PaymentResult(
        success: false,
        errorMessage: 'Invalid phone number format. Use format: 03XXXXXXXXX',
      );
    }

    // Simulate success (90% success rate for demo)
    final random = Random();
    final isSuccess = random.nextDouble() > 0.1;

    if (isSuccess) {
      // Generate mock transaction ID
      final transactionId = _generateTransactionId(method);
      
      return PaymentResult(
        success: true,
        transactionId: transactionId,
        method: method,
        amount: amount,
      );
    } else {
      return PaymentResult(
        success: false,
        errorMessage: 'Payment failed. Please try again or use a different payment method.',
      );
    }
  }

  /// Verify a payment (simulated)
  Future<bool> verifyPayment({
    required String transactionId,
    required PaymentMethod method,
  }) async {
    // Simulate verification delay
    await Future.delayed(const Duration(milliseconds: 500));
    
    // In production, verify with payment provider API
    return transactionId.isNotEmpty;
  }

  /// Validate Pakistani phone number
  bool _isValidPakistaniPhone(String phone) {
    // Format: 03XXXXXXXXX (11 digits starting with 03)
    final phoneRegex = RegExp(r'^03[0-9]{9}$');
    return phoneRegex.hasMatch(phone.replaceAll(RegExp(r'[\s-]'), ''));
  }

  /// Generate mock transaction ID
  String _generateTransactionId(PaymentMethod method) {
    final prefix = method == PaymentMethod.jazzcash ? 'JC' : 'EP';
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final random = Random().nextInt(9999).toString().padLeft(4, '0');
    return '$prefix$timestamp$random';
  }
}

/// Result of a payment operation
class PaymentResult {
  final bool success;
  final String? transactionId;
  final PaymentMethod? method;
  final double? amount;
  final String? errorMessage;

  PaymentResult({
    required this.success,
    this.transactionId,
    this.method,
    this.amount,
    this.errorMessage,
  });
}
