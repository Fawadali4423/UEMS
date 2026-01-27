import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:uems/app/theme.dart';
import 'package:uems/core/widgets/glassmorphism_card.dart';
import 'package:uems/features/payment/presentation/providers/payment_provider.dart';
import 'package:uems/features/payment/domain/models/payment_model.dart';
import 'dart:convert';

/// Screen for organizers to approve/reject payments
class PaymentApprovalScreen extends StatelessWidget {
  const PaymentApprovalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // Header note
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: GlassmorphismCard(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: AppTheme.accentColor,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Review payment receipts and approve/reject',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ?Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Payment list
        Expanded(
          child: Consumer<PaymentProvider>(
            builder: (context, provider, _) {
              return StreamBuilder<List<PaymentModel>>(
                stream: provider.getPendingPayments(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Error: ${snapshot.error}'),
                    );
                  }

                  final payments = snapshot.data ?? [];

                  if (payments.isEmpty) {
                    return _buildEmptyState(isDark);
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: payments.length,
                    itemBuilder: (context, index) {
                      return _buildPaymentCard(
                        context,
                        payments[index],
                        isDark,
                        provider,
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentCard(
    BuildContext context,
    PaymentModel payment,
    bool isDark,
    PaymentProvider provider,
  ) {
    return GlassmorphismCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Student info
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      payment.studentId,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.grey[900],
                      ),
                    ),
                    Text(
                      payment.eventId,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              // Amount
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.successColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'PKR ${payment.amount.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.successColor,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Transaction details
          Row(
            children: [
              Icon(
                Icons.receipt_rounded,
                size: 16,
                color: isDark ? Colors.grey[500] : Colors.grey[500],
              ),
              const SizedBox(width: 6),
              Text(
                'Transaction: ${payment.transactionId}',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey[500] : Colors.grey[500],
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Row(
            children: [
              Icon(
                Icons.payment_rounded,
                size: 16,
                color: isDark ? Colors.grey[500] : Colors.grey[500],
              ),
              const SizedBox(width: 6),
              Text(
                'Method: ${payment.method.name}',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey[500] : Colors.grey[500],
                ),
              ),
            ],
          ),

          // Receipt image if available
          if (payment.screenshotUrl != null && payment.screenshotUrl!.isNotEmpty) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => _showFullReceipt(context, payment),
              child: Container(
                width: double.infinity,
                height: 150,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey[800],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(
                    base64Decode(payment.screenshotUrl!),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stack) => const Center(
                      child: Icon(Icons.error_rounded),
                    ),
                  ),
                ),
              ),
            ),
          ],

          const SizedBox(height: 12),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _approvePayment(context, payment, provider),
                  icon: const Icon(Icons.check_circle_rounded, size: 18),
                  label: const Text('Approve'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.successColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _rejectPayment(context, payment, provider),
                  icon: const Icon(Icons.cancel_rounded, size: 18),
                  label: const Text('Reject'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.errorColor,
                    side: BorderSide(color: AppTheme.errorColor),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.05, end: 0);
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.payments_rounded,
            size: 64,
            color: isDark ? Colors.grey[700] : Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'No pending payments',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.grey[900],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Payment receipts will appear here',
            style: TextStyle(
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showFullReceipt(BuildContext context, PaymentModel payment) async {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: const Text('Payment Receipt'),
              automaticallyImplyLeading: true,
            ),
            Expanded(
              child: InteractiveViewer(
                child: Image.memory(
                  base64Decode(payment.screenshotUrl!),
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _approvePayment(
    BuildContext context,
    PaymentModel payment,
    PaymentProvider provider,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve Payment'),
        content: Text('Approve payment of PKR ${payment.amount} from student?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Approve'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await provider.approvePayment(payment.id);
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Payment approved successfully'),
              backgroundColor: AppTheme.successColor,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to approve: $e'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    }
  }

  Future<void> _rejectPayment(
    BuildContext context,
    PaymentModel payment,
    PaymentProvider provider,
  ) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Reject Payment'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Reject payment from student?'),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'Rejection Reason',
                  hintText: 'Why is this payment rejected?',
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('Reject'),
            ),
          ],
        );
      },
    );

    if (reason != null && reason.isNotEmpty) {
      try {
        await provider.rejectPayment(payment.id, reason);
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Payment rejected'),
              backgroundColor: AppTheme.successColor,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to reject: $e'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    }
  }
}
