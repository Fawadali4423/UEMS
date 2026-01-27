/// Payment model for transaction records
class PaymentModel {
  final String id;
  final String eventId;
  final String studentId;
  final double amount;
  final PaymentMethod method;
  final PaymentStatus status;
  final String? transactionId; // From payment provider
  final String? phoneNumber;
  final DateTime createdAt;
  final DateTime? completedAt;

  final String? manualTransactionId;
  final String? screenshotUrl;
  final String? adminComment;

  PaymentModel({
    required this.id,
    required this.eventId,
    required this.studentId,
    required this.amount,
    required this.method,
    this.status = PaymentStatus.pending,
    this.transactionId, // System generated or Provider ID
    this.manualTransactionId, // User entered ID
    this.screenshotUrl,
    this.adminComment,
    this.phoneNumber,
    required this.createdAt,
    this.completedAt,
  });

  /// Create a copy with updated fields
  PaymentModel copyWith({
    PaymentStatus? status,
    String? transactionId,
    DateTime? completedAt,
    String? adminComment,
  }) {
    return PaymentModel(
      id: id,
      eventId: eventId,
      studentId: studentId,
      amount: amount,
      method: method,
      status: status ?? this.status,
      transactionId: transactionId ?? this.transactionId,
      manualTransactionId: manualTransactionId,
      screenshotUrl: screenshotUrl,
      adminComment: adminComment ?? this.adminComment,
      phoneNumber: phoneNumber,
      createdAt: createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'eventId': eventId,
      'studentId': studentId,
      'amount': amount,
      'method': method.index,
      'status': status.index,
      'transactionId': transactionId,
      'manualTransactionId': manualTransactionId,
      'screenshotUrl': screenshotUrl,
      'adminComment': adminComment,
      'phoneNumber': phoneNumber,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  factory PaymentModel.fromMap(Map<String, dynamic> map, String id) {
    return PaymentModel(
      id: id,
      eventId: map['eventId'] ?? '',
      studentId: map['studentId'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      method: PaymentMethod.values[map['method'] ?? 0],
      status: PaymentStatus.values[map['status'] ?? 0],
      transactionId: map['transactionId'],
      manualTransactionId: map['manualTransactionId'],
      screenshotUrl: map['screenshotUrl'],
      adminComment: map['adminComment'],
      phoneNumber: map['phoneNumber'],
      createdAt: DateTime.parse(map['createdAt']),
      completedAt: map['completedAt'] != null ? DateTime.parse(map['completedAt']) : null,
    );
  }
}

/// Payment methods supported
enum PaymentMethod {
  jazzcash,
  easypaisa,
}

/// Extension for PaymentMethod
extension PaymentMethodExtension on PaymentMethod {
  String get displayName {
    switch (this) {
      case PaymentMethod.jazzcash:
        return 'JazzCash';
      case PaymentMethod.easypaisa:
        return 'EasyPaisa';
    }
  }

  String get iconAsset {
    switch (this) {
      case PaymentMethod.jazzcash:
        return 'assets/icons/jazzcash.png';
      case PaymentMethod.easypaisa:
        return 'assets/icons/easypaisa.png';
    }
  }
}

/// Payment status
enum PaymentStatus {
  pending,
  processing,
  completed,
  failed,
  cancelled,
}

/// Extension for PaymentStatus
extension PaymentStatusExtension on PaymentStatus {
  String get displayName {
    switch (this) {
      case PaymentStatus.pending:
        return 'Pending';
      case PaymentStatus.processing:
        return 'Processing';
      case PaymentStatus.completed:
        return 'Completed';
      case PaymentStatus.failed:
        return 'Failed';
      case PaymentStatus.cancelled:
        return 'Cancelled';
    }
  }

  bool get isSuccess => this == PaymentStatus.completed;
  bool get isPending => this == PaymentStatus.pending || this == PaymentStatus.processing;
  bool get isFailed => this == PaymentStatus.failed || this == PaymentStatus.cancelled;
}
