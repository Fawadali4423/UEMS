import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:uems/app/theme.dart';
import 'package:uems/core/services/certificate_api_service.dart';
import 'package:uems/core/widgets/animated_button.dart';
import 'package:uems/core/widgets/custom_text_field.dart';
import 'package:uems/core/widgets/glassmorphism_card.dart';

/// Public screen to verify certificates via ID
class VerifyCertificateScreen extends StatefulWidget {
  const VerifyCertificateScreen({super.key});

  @override
  State<VerifyCertificateScreen> createState() => _VerifyCertificateScreenState();
}

class _VerifyCertificateScreenState extends State<VerifyCertificateScreen> {
  final _certificateIdController = TextEditingController();
  final _apiService = CertificateApiService();
  
  bool _isLoading = false;
  CertificateVerificationResult? _result;
  String? _error;

  @override
  void dispose() {
    _certificateIdController.dispose();
    super.dispose();
  }

  Future<void> _verifyCertificate() async {
    final id = _certificateIdController.text.trim();
    if (id.isEmpty) {
      setState(() => _error = 'Please enter a certificate ID');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _result = null;
    });

    try {
      final result = await _apiService.verifyCertificate(id);
      
      if (mounted) {
        setState(() {
          _result = result;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().contains('Certificate not found') 
              ? 'Certificate not found. Please check the ID.'
              : 'Verification failed. Please check your connection.';
          _isLoading = false;
        });
      }
    }
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Back Button
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.arrow_back_ios_rounded,
                      color: isDark ? Colors.white : Colors.grey[800],
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),

                // Header
                Icon(
                  Icons.verified_user_rounded,
                  size: 64,
                  color: AppTheme.primaryColor,
                ).animate().scale(delay: 100.ms),
                
                const SizedBox(height: 16),
                
                Text(
                  'Verify Certificate',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.grey[900],
                  ),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 200.ms),
                
                const SizedBox(height: 8),
                
                Text(
                  'Enter the unique certificate ID to verify its authenticity',
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 300.ms),

                const SizedBox(height: 40),

                // Input Section
                GlassmorphismCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      CustomTextField(
                        controller: _certificateIdController,
                        label: 'Certificate ID',
                        hint: 'e.g. CERT-12345-ABC',
                        prefixIcon: Icons.fingerprint_rounded,
                        onChanged: (_) {
                          if (_error != null) setState(() => _error = null);
                        },
                      ),
                      
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(Icons.error_outline_rounded, 
                                color: AppTheme.errorColor, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _error!,
                                style: TextStyle(
                                  color: AppTheme.errorColor,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 20),

                      AnimatedButton(
                        text: 'Verify Now',
                        icon: Icons.check_circle_outline_rounded,
                        isLoading: _isLoading,
                        onPressed: _verifyCertificate,
                      ),
                    ],
                  ),
                ).animate().slideY(begin: 0.2, end: 0, delay: 400.ms),

                const SizedBox(height: 30),

                // Result Section
                if (_result != null)
                  _buildResultCard(_result!, isDark)
                      .animate()
                      .fadeIn()
                      .slideY(begin: 0.2, end: 0),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultCard(CertificateVerificationResult result, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: result.valid 
            ? AppTheme.successColor.withOpacity(0.1)
            : AppTheme.errorColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: result.valid ? AppTheme.successColor : AppTheme.errorColor,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Icon(
            result.valid ? Icons.verified_rounded : Icons.cancel_rounded,
            size: 48,
            color: result.valid ? AppTheme.successColor : AppTheme.errorColor,
          ),
          const SizedBox(height: 16),
          Text(
            result.valid ? 'Valid Certificate' : 'Invalid Certificate',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: result.valid ? AppTheme.successColor : AppTheme.errorColor,
            ),
          ),
          
          if (result.valid) ...[
            const SizedBox(height: 24),
            _buildDetailRow('Student Name', result.studentName, isDark),
            const Divider(height: 24),
            _buildDetailRow('Event', result.eventName, isDark),
            const Divider(height: 24),
            _buildDetailRow(
              'Issued On', 
              '${result.issueDate.day}/${result.issueDate.month}/${result.issueDate.year}', 
              isDark
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, bool isDark) {
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
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.grey[900],
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
