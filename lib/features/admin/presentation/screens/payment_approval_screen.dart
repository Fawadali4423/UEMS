import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:uems/app/theme.dart';
import 'package:uems/core/utils/date_utils.dart' as date_utils;
import 'package:uems/core/widgets/glassmorphism_card.dart';
import 'package:uems/features/payment/domain/models/payment_model.dart';
import 'package:uems/features/payment/presentation/providers/payment_provider.dart';

class PaymentApprovalScreen extends StatefulWidget {
  const PaymentApprovalScreen({super.key});

  @override
  State<PaymentApprovalScreen> createState() => _PaymentApprovalScreenState();
}

class _PaymentApprovalScreenState extends State<PaymentApprovalScreen> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final paymentProvider = Provider.of<PaymentProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Approvals'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: isDark ? Colors.white : Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        padding: const EdgeInsets.only(top: 100), // Space for AppBar
        decoration: BoxDecoration(
          gradient: isDark ? AppTheme.darkGradient : null,
          color: isDark ? null : Colors.grey[50],
        ),
        child: StreamBuilder<List<PaymentModel>>(
          stream: paymentProvider.getPendingPayments(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            final payments = snapshot.data ?? [];

            if (payments.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle_outline_rounded,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No pending payments',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: payments.length,
              itemBuilder: (context, index) {
                final payment = payments[index];
                return _buildPaymentCard(context, payment, isDark, paymentProvider);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildPaymentCard(BuildContext context, PaymentModel payment, bool isDark, PaymentProvider provider) {
    return GlassmorphismCard(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: payment.method == PaymentMethod.jazzcash 
                      ? const Color(0xFFE32536).withValues(alpha: 0.1) 
                      : const Color(0xFF3AAF50).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: payment.method == PaymentMethod.jazzcash 
                        ? const Color(0xFFE32536) 
                        : const Color(0xFF3AAF50),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                     Icon(
                        Icons.account_balance_wallet,
                        size: 14,
                        color: payment.method == PaymentMethod.jazzcash 
                            ? const Color(0xFFE32536) 
                            : const Color(0xFF3AAF50),
                     ),
                     const SizedBox(width: 4),
                     Text(
                      payment.method.displayName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: payment.method == PaymentMethod.jazzcash 
                            ? const Color(0xFFE32536) 
                            : const Color(0xFF3AAF50),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                date_utils.DateTimeUtils.formatCheckInTime(payment.createdAt),
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'PKR ${payment.amount.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 8),
           Row(
            children: [
              Icon(Icons.person_outline, size: 16, color: Colors.grey[500]),
              const SizedBox(width: 4),
              Text(
                'Student ID: ${payment.studentId.substring(0, 8)}...',
                style: TextStyle(color: Colors.grey[500], fontFamily: 'Courier'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.receipt_long, size: 16, color: Colors.grey[500]),
              const SizedBox(width: 4),
              SelectableText(
                'Txn: ${payment.manualTransactionId ?? "N/A"}',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87, 
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Courier'
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (payment.screenshotUrl != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                height: 100,
                width: double.infinity,
                color: Colors.black12,
                  child: Stack(
                  fit: StackFit.expand,
                  children: [
                    GestureDetector(
                      onTap: () => _showProofDialog(context, payment.screenshotUrl!),
                      child: Hero(
                        tag: 'proof_${payment.id}',
                        child: _buildProofImage(payment.screenshotUrl!),
                      ),
                    ),
                    Positioned(
                       bottom: 4,
                       right: 4,
                       child: GestureDetector(
                         onTap: () => _showProofDialog(context, payment.screenshotUrl!),
                         child: Container(
                           padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                           decoration: BoxDecoration(
                             color: Colors.black54,
                             borderRadius: BorderRadius.circular(12),
                           ),
                           child: Row(
                             mainAxisSize: MainAxisSize.min,
                             children: const [
                               Icon(Icons.fullscreen, color: Colors.white, size: 12),
                               SizedBox(width: 4),
                               Text('Tap to View', style: TextStyle(color: Colors.white, fontSize: 10)),
                             ],
                           ),
                         ),
                       ),
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showRejectDialog(context, provider, payment.id),
                  icon: const Icon(Icons.close, color: AppTheme.errorColor),
                  label: const Text('Reject', style: TextStyle(color: AppTheme.errorColor)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: AppTheme.errorColor),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _handleApprove(context, provider, payment.id),
                  icon: const Icon(Icons.check, color: Colors.white),
                  label: const Text('Approve', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.successColor,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1, end: 0);
  }

  Future<void> _handleApprove(BuildContext context, PaymentProvider provider, String paymentId) async {
    try {
      await provider.approvePayment(paymentId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment approved! QR Pass generated.'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.errorColor),
        );
      }
    }
  }

  Future<void> _showRejectDialog(BuildContext context, PaymentProvider provider, String paymentId) async {
    final reasonController = TextEditingController();
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please provide a reason for rejection:'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: 'e.g., Invalid Transaction ID',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (reasonController.text.isEmpty) return;
              
              Navigator.pop(context); // Close dialog
              
              try {
                await provider.rejectPayment(paymentId, reasonController.text);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Payment rejected.'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.errorColor),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
            child: const Text('Reject', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildProofImage(String url, {BoxFit fit = BoxFit.cover}) {
    if (url.startsWith('http')) {
      return Image.network(
        url,
        fit: fit,
        errorBuilder: _buildErrorWidget,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                  : null,
              color: Colors.white,
            ),
          );
        },
      );
    } else if (url.startsWith('file://') || !url.contains('://')) {
      // Handle file:// URI or raw path
      final path = url.startsWith('file://') ? url.replaceFirst('file://', '') : url;
      return Image.file(
        File(path),
        fit: fit,
        errorBuilder: _buildErrorWidget,
      );
    }
    return _buildErrorWidget(context, 'Invalid URL scheme', StackTrace.empty);
  }

  Widget _buildErrorWidget(BuildContext context, Object error, StackTrace? stackTrace) {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.grey[200],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.broken_image, size: 30, color: Colors.grey[500]),
          const SizedBox(height: 8),
          const Text(
            'Image Error',
            style: TextStyle(fontSize: 12, color: Colors.black, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            error.toString().replaceAll('Exception:', ''),
            style: TextStyle(fontSize: 10, color: Colors.grey[600]),
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Future<void> _showProofDialog(BuildContext context, String imageUrl) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          alignment: Alignment.center,
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                color: Colors.black87,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
            
            InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Center(
                child: Hero(
                  tag: 'proof_dialog', 
                  child: _buildProofImage(imageUrl, fit: BoxFit.contain),
                ),
              ),
            ),

            Positioned(
              top: 40,
              right: 20,
              child: SafeArea(
                child: Material(
                  color: Colors.transparent,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 30),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
            ),
             Positioned(
              bottom: 40,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Pinch to zoom',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
