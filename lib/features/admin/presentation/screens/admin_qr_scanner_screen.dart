import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:uems/app/theme.dart';
import 'package:uems/core/widgets/glassmorphism_card.dart';
import 'package:uems/features/auth/data/user_repository.dart';
import 'package:uems/features/auth/domain/models/user_model.dart';
import 'package:uems/features/registration/data/registration_repository.dart';
import 'package:uems/features/registration/domain/models/registration_model.dart';

/// Admin QR Scanner screen for verifying student passes
class AdminQrScannerScreen extends StatefulWidget {
  const AdminQrScannerScreen({super.key});

  @override
  State<AdminQrScannerScreen> createState() => _AdminQrScannerScreenState();
}

class _AdminQrScannerScreenState extends State<AdminQrScannerScreen> {
  final RegistrationRepository _registrationRepository = RegistrationRepository();
  final UserRepository _userRepository = UserRepository();
  MobileScannerController? _scannerController;
  
  bool _isScanning = true;
  bool _isProcessing = false;
  PassModel? _scannedPass;
  UserModel? _scannedUser;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
    );
  }

  @override
  void dispose() {
    _scannerController?.dispose();
    super.dispose();
  }

  Future<void> _handleScan(String qrData) async {
    if (_isProcessing || !_isScanning) return;
    
    setState(() {
      _isProcessing = true;
      _isScanning = false;
    });

    try {
      final pass = await _registrationRepository.validateQrData(qrData);
      
      if (pass != null) {
        // Fetch user details for profile picture
        final user = await _userRepository.getUserById(pass.studentId);

        setState(() {
          _scannedPass = pass;
          _scannedUser = user;
          _errorMessage = null;
        });
      } else {
        setState(() {
          _scannedPass = null;
          _scannedUser = null;
          _errorMessage = 'Invalid QR code. This pass is not recognized.';
        });
      }
    } catch (e) {
      setState(() {
        _scannedPass = null;
        _scannedUser = null;
        _errorMessage = 'Error scanning: ${e.toString()}';
      });
    }

    setState(() => _isProcessing = false);
  }

  void _resetScanner() {
    setState(() {
      _isScanning = true;
      _scannedPass = null;
      _scannedUser = null;
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

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
                    Expanded(
                      child: Text(
                        'QR Pass Scanner',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.grey[900],
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        _scannerController?.toggleTorch();
                      },
                      icon: Icon(
                        Icons.flash_on_rounded,
                        color: isDark ? Colors.white : Colors.grey[800],
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn().slideY(begin: -0.1, end: 0),

              // Scanner or Result
              Expanded(
                child: _isScanning
                    ? _buildScannerView(size, isDark)
                    : _buildResultView(isDark),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScannerView(Size size, bool isDark) {
    return Column(
      children: [
        // Scanner
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                MobileScanner(
                  controller: _scannerController,
                  onDetect: (capture) {
                    final barcodes = capture.barcodes;
                    if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
                      _handleScan(barcodes.first.rawValue!);
                    }
                  },
                ),
                // Scan overlay
                Center(
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.5),
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                // Corner decorations
                Positioned(
                  top: (size.height * 0.5 - 125) / 2 - 50,
                  left: (size.width - 40 - 250) / 2,
                  child: _buildCorner(true, true),
                ),
                Positioned(
                  top: (size.height * 0.5 - 125) / 2 - 50,
                  right: (size.width - 40 - 250) / 2,
                  child: _buildCorner(true, false),
                ),
                Positioned(
                  bottom: (size.height * 0.5 - 125) / 2 - 50,
                  left: (size.width - 40 - 250) / 2,
                  child: _buildCorner(false, true),
                ),
                Positioned(
                  bottom: (size.height * 0.5 - 125) / 2 - 50,
                  right: (size.width - 40 - 250) / 2,
                  child: _buildCorner(false, false),
                ),
              ],
            ),
          ),
        ),

        // Instructions
        Padding(
          padding: const EdgeInsets.all(20),
          child: GlassmorphismCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.qr_code_scanner_rounded,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Scan Student Pass',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.grey[900],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Point camera at QR code to verify student details',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0),
      ],
    );
  }

  Widget _buildResultView(bool isDark) {
    if (_isProcessing) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          if (_scannedPass != null) ...[
            // Success Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.successColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: AppTheme.successColor,
                size: 48,
              ),
            ).animate().scale(duration: 300.ms, curve: Curves.elasticOut),

            const SizedBox(height: 16),

            Text(
              'Pass Verified!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.successColor,
              ),
            ).animate().fadeIn(delay: 100.ms),

            const SizedBox(height: 24),

            // Student Profile Picture (If available)
             if (_scannedUser != null && _scannedUser!.profileImageBase64 != null) ...[
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.primaryColor,
                    width: 3,
                  ),
                  image: DecorationImage(
                    image: MemoryImage(
                      base64Decode(_scannedUser!.profileImageBase64!),
                    ),
                    fit: BoxFit.cover,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 150.ms).scale(),
              const SizedBox(height: 24),
            ],

            // Student Details Card
            GlassmorphismCard(
              child: Column(
                children: [
                  _buildDetailRow('Name', _scannedPass!.studentName ?? 'N/A', Icons.person_rounded, isDark),
                  const Divider(height: 24),
                  _buildDetailRow('Roll Number', _scannedPass!.rollNumber ?? 'N/A', Icons.badge_rounded, isDark),
                  const Divider(height: 24),
                  _buildDetailRow('Email', _scannedPass!.studentEmail ?? 'N/A', Icons.email_rounded, isDark),
                  const Divider(height: 24),
                  _buildDetailRow('Event', _scannedPass!.eventName, Icons.event_rounded, isDark),
                  const Divider(height: 24),
                  _buildDetailRow('Registration ID', _scannedPass!.registrationId, Icons.confirmation_number_rounded, isDark),
                  const Divider(height: 24),
                  _buildDetailRow(
                    'Status',
                    _scannedPass!.isUsed ? 'Already Checked In' : 'Valid Pass',
                    _scannedPass!.isUsed ? Icons.check_circle_rounded : Icons.verified_rounded,
                    isDark,
                    valueColor: _scannedPass!.isUsed ? AppTheme.warningColor : AppTheme.successColor,
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0),
          ] else if (_errorMessage != null) ...[
            // Error Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.errorColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_rounded,
                color: AppTheme.errorColor,
                size: 48,
              ),
            ).animate().scale(duration: 300.ms, curve: Curves.elasticOut),

            const SizedBox(height: 16),

            Text(
              'Invalid Pass',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.errorColor,
              ),
            ).animate().fadeIn(delay: 100.ms),

            const SizedBox(height: 16),

            GlassmorphismCard(
              padding: const EdgeInsets.all(16),
              child: Text(
                _errorMessage!,
                style: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ).animate().fadeIn(delay: 200.ms),
          ],

          const SizedBox(height: 32),

          // Scan Again Button
          ElevatedButton.icon(
            onPressed: _resetScanner,
            icon: const Icon(Icons.qr_code_scanner_rounded),
            label: const Text('Scan Another Pass'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1, end: 0),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon, bool isDark, {Color? valueColor}) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppTheme.primaryColor, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey[500] : Colors.grey[600],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? (isDark ? Colors.white : Colors.grey[900]),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCorner(bool isTop, bool isLeft) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        border: Border(
          top: isTop ? const BorderSide(color: AppTheme.primaryColor, width: 3) : BorderSide.none,
          bottom: !isTop ? const BorderSide(color: AppTheme.primaryColor, width: 3) : BorderSide.none,
          left: isLeft ? const BorderSide(color: AppTheme.primaryColor, width: 3) : BorderSide.none,
          right: !isLeft ? const BorderSide(color: AppTheme.primaryColor, width: 3) : BorderSide.none,
        ),
      ),
    );
  }
}
