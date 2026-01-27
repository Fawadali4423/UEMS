import 'package:uems/features/payment/domain/models/payment_model.dart';

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
