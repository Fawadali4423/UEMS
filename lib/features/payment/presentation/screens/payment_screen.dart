import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:uems/app/theme.dart';
import 'package:uems/core/widgets/animated_button.dart';
import 'package:uems/core/widgets/custom_text_field.dart';
import 'package:uems/core/widgets/glassmorphism_card.dart';
import 'package:uems/features/payment/domain/models/payment_model.dart';
import 'package:uems/features/payment/presentation/providers/payment_provider.dart';

/// Payment screen for processing event registration payments
class PaymentScreen extends StatefulWidget {
  final String eventId;
  final String eventName;
  final double amount;
  final String studentId;
  final Function(String transactionId) onPaymentSuccess;

  const PaymentScreen({
    super.key,
    required this.eventId,
    required this.eventName,
    required this.amount,
    required this.studentId,
    required this.onPaymentSuccess,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _transactionIdController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  File? _selectedImage;
  bool _isUploading = false;

  @override
  void dispose() {
    _transactionIdController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  Future<void> _handlePayment() async {
    if (!_formKey.currentState!.validate()) return;
    
    // In a real app, you would upload the image to storage here and get a URL.
    // For this mock/demo, we'll just skip the upload or simulate it.
    
    final paymentProvider = Provider.of<PaymentProvider>(context, listen: false);
    
    // Simulate image upload if image selected
    String? screenshotUrl;
    if (_selectedImage != null) {
      // Mock URL
      screenshotUrl = 'file://${_selectedImage!.path}'; 
    }

    final result = await paymentProvider.submitManualPayment(
      eventId: widget.eventId,
      studentId: widget.studentId,
      amount: widget.amount,
      transactionId: _transactionIdController.text.trim(),
      screenshotUrl: screenshotUrl,
    );

    if (result != null && result.success) {
      if (mounted) {
        widget.onPaymentSuccess(result.transactionId ?? 'MANUAL_PENDING');
        Navigator.pop(context, true);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Payment submitted for approval!'),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else if (mounted && result != null && !result.success) {
      _showErrorSnackbar(result.errorMessage ?? 'Payment failed');
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark ? AppTheme.darkGradient : null,
          color: isDark ? null : Colors.grey[100],
        ),
        child: SafeArea(
          child: Column(
            children: [
              // App Bar
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.arrow_back_ios_rounded,
                        color: isDark ? Colors.white : Colors.grey[800],
                      ),
                    ),
                    Text(
                      'Payment',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.grey[900],
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn().slideY(begin: -0.1, end: 0),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Event & Amount Card
                        GlassmorphismCard(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              Icon(
                                Icons.event_rounded,
                                size: 48,
                                color: AppTheme.primaryColor,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                widget.eventName,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.grey[900],
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.successColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: AppTheme.successColor.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Text(
                                  'PKR ${widget.amount.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.successColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1, end: 0),

                        const SizedBox(height: 24),

                        // Payment Method Selection
                        Text(
                          'Select Payment Method',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 12),

                        Consumer<PaymentProvider>(
                          builder: (context, provider, _) {
                            return Row(
                              children: [
                                Expanded(
                                  child: _buildPaymentMethodCard(
                                    method: PaymentMethod.jazzcash,
                                    isSelected: provider.selectedMethod == PaymentMethod.jazzcash,
                                    onTap: () => provider.selectMethod(PaymentMethod.jazzcash),
                                    isDark: isDark,
                                    color: const Color(0xFFE32536),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildPaymentMethodCard(
                                    method: PaymentMethod.easypaisa,
                                    isSelected: provider.selectedMethod == PaymentMethod.easypaisa,
                                    onTap: () => provider.selectMethod(PaymentMethod.easypaisa),
                                    isDark: isDark,
                                    color: const Color(0xFF3AAF50),
                                  ),
                                ),
                              ],
                            );
                          },
                        ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0),

                        const SizedBox(height: 24),

                        const SizedBox(height: 24),
                        
                        // Admin Wallet Details (Conditional)
                        Consumer<PaymentProvider>(
                          builder: (context, provider, _) {
                            if (provider.selectedMethod == null) return const SizedBox.shrink();
                            
                            final isJazzCash = provider.selectedMethod == PaymentMethod.jazzcash;
                            final color = isJazzCash ? const Color(0xFFE32536) : const Color(0xFF3AAF50);
                            
                            return GlassmorphismCard(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.admin_panel_settings_rounded, color: color),
                                      const SizedBox(width: 10),
                                      Text(
                                        'Admin Wallet Details',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: isDark ? Colors.white : Colors.grey[900],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 24),
                                  _buildDetailRow(
                                    'Account Name', 
                                    'University Event Admin', 
                                    isDark
                                  ),
                                  const SizedBox(height: 12),
                                  _buildDetailRow(
                                    'Account Number', 
                                    isJazzCash ? '0300-1234567' : '0345-7654321', 
                                    isDark,
                                    isCopyable: true,
                                  ),
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: color.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.info_outline, size: 16, color: color),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Please send exactly PKR ${widget.amount.toStringAsFixed(0)} to the above account.',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: color,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ).animate().fadeIn().slideY(begin: 0.1, end: 0);
                          },
                        ),
                        
                        const SizedBox(height: 24),

                        // Transaction ID Input
                        Text(
                          'Transaction ID',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 8),
                        
                        CustomTextField(
                          controller: _transactionIdController,
                          label: 'Transaction ID',
                          hint: 'e.g. 84732192',
                          prefixIcon: Icons.receipt_long_rounded,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Transaction ID is required';
                            }
                            return null;
                          },
                        ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1, end: 0),

                        const SizedBox(height: 24),
                        
                        // Screenshot Upload
                        Text(
                          'Payment Proof',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 8),
                        
                        InkWell(
                          onTap: _pickImage,
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            height: 150,
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[100],
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey[300]!,
                                style: BorderStyle.solid,
                              ),
                            ),
                            child: _selectedImage != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Stack(
                                      children: [
                                        Image.file(
                                          _selectedImage!,
                                          width: double.infinity,
                                          height: double.infinity,
                                          fit: BoxFit.cover,
                                        ),
                                        Positioned(
                                          right: 8,
                                          top: 8,
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: const BoxDecoration(
                                              color: Colors.black54,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(Icons.edit, color: Colors.white, size: 20),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.add_photo_alternate_rounded,
                                        size: 48,
                                        color: isDark ? Colors.grey[600] : Colors.grey[400],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Upload Screenshot (Optional)',
                                        style: TextStyle(
                                          color: isDark ? Colors.grey[500] : Colors.grey[600],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1, end: 0),

                        const SizedBox(height: 32),

                        // Pay Button
                        Consumer<PaymentProvider>(
                          builder: (context, provider, _) {
                            return AnimatedButton(
                              text: 'Submit Payment Proof',
                              icon: Icons.send_rounded,
                              isLoading: provider.isLoading,
                              onPressed: provider.selectedMethod != null
                                  ? _handlePayment
                                  : null,
                            );
                          },
                        ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1, end: 0),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentMethodCard({
    required PaymentMethod method,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected 
              ? color.withValues(alpha: 0.15)
              : (isDark ? const Color(0xFF2D2D44) : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 2,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ] : null,
        ),
        child: Column(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Image.asset(
                method.iconAsset,
                width: 30,
                height: 30,
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.account_balance_wallet_rounded,
                  color: color,
                  size: 28,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              method.displayName,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isSelected 
                    ? color 
                    : (isDark ? Colors.white : Colors.grey[800]),
              ),
            ),
            if (isSelected)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Icon(
                  Icons.check_circle_rounded,
                  color: color,
                  size: 18,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, bool isDark, {bool isCopyable = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isDark ? Colors.grey[400] : Colors.grey[600],
            fontSize: 14,
          ),
        ),
        Row(
          children: [
            Text(
              value,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.grey[900],
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            if (isCopyable) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: value));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Copied to clipboard')),
                  );
                },
                child: Icon(
                  Icons.copy_rounded,
                  size: 16,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
