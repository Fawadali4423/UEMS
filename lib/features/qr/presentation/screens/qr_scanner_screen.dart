import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:uems/app/theme.dart';
import 'package:uems/core/widgets/glassmorphism_card.dart';

/// QR Scanner screen for admin to scan student passes
class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  MobileScannerController? _controller;
  bool _isScanned = false;
  Map<String, String>? _scannedData;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isScanned) return;
    
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;
    
    final code = barcodes.first.rawValue;
    if (code == null) return;

    // Parse QR code: UEMS_PASS|eventId|studentId|studentName|studentEmail
    if (code.startsWith('UEMS_PASS|')) {
      final parts = code.split('|');
      if (parts.length >= 5) {
        setState(() {
          _isScanned = true;
          _scannedData = {
            'eventId': parts[1],
            'studentId': parts[2],
            'studentName': parts[3],
            'studentEmail': parts[4],
          };
        });
        _controller?.stop();
        _showStudentProfile();
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid QR code. Not a valid event pass.'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  void _showStudentProfile() {
    if (_scannedData == null) return;
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            
            // Success Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: Colors.white,
                size: 48,
              ),
            ),
            const SizedBox(height: 20),
            
            Text(
              'Valid Event Pass',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.grey[900],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Student verified successfully',
              style: TextStyle(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Student Info Card
            GlassmorphismCard(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Avatar
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        _scannedData!['studentName']!.isNotEmpty 
                            ? _scannedData!['studentName']![0].toUpperCase()
                            : 'S',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Name
                  Text(
                    _scannedData!['studentName']!,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.grey[900],
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Email
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.email_outlined,
                        size: 16,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _scannedData!['studentEmail']!,
                        style: TextStyle(
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const Spacer(),
            
            // Action Buttons
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _resetScanner();
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Scan Another'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.successColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Done'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).then((_) {
      if (mounted && _isScanned) {
        _resetScanner();
      }
    });
  }

  void _resetScanner() {
    setState(() {
      _isScanned = false;
      _scannedData = null;
    });
    _controller?.start();
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
              // Header
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
                      'Scan QR Pass',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.grey[900],
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => _controller?.toggleTorch(),
                      icon: Icon(
                        Icons.flash_on_rounded,
                        color: isDark ? Colors.white : Colors.grey[800],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Scanner View
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppTheme.primaryColor.withValues(alpha: 0.5),
                      width: 2,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: _controller != null
                        ? MobileScanner(
                            controller: _controller!,
                            onDetect: _onDetect,
                          )
                        : const Center(child: CircularProgressIndicator()),
                  ),
                ),
              ),
              
              // Instructions
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Point the camera at a student\'s QR pass',
                  style: TextStyle(
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
