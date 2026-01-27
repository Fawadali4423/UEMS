import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:uems/app/theme.dart';
import 'package:uems/core/widgets/glassmorphism_card.dart';
import 'package:uems/features/attendance/data/attendance_repository.dart';
import 'package:uems/features/auth/data/user_repository.dart';
import 'package:uems/features/registration/presentation/providers/registration_provider.dart';
import 'package:uems/core/services/local_storage_service.dart';
import 'package:uems/core/services/connectivity_service.dart';
import 'package:uems/core/models/offline_attendance_item.dart';
import 'package:uems/core/providers/sync_provider.dart';
import 'package:uems/core/widgets/sync_button.dart';
import 'package:uems/features/auth/presentation/providers/auth_provider.dart';

/// QR Scanner screen for organizers to mark attendance
class QrScannerScreen extends StatefulWidget {
  final String eventId;

  const QrScannerScreen({super.key, required this.eventId});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController _scannerController = MobileScannerController();
  final AttendanceRepository _attendanceRepository = AttendanceRepository();
  final UserRepository _userRepository = UserRepository();
  final LocalStorageService _storageService = LocalStorageService();
  final ConnectivityService _connectivityService = ConnectivityService();

  bool _isProcessing = false;
  String? _lastScannedCode;
  ScanResult? _scanResult;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _processQrCode(String qrData) async {
    if (_isProcessing || qrData == _lastScannedCode) return;

    setState(() {
      _isProcessing = true;
      _lastScannedCode = qrData;
    });

    final regProvider = Provider.of<RegistrationProvider>(context, listen: false);
    final syncProvider = Provider.of<SyncProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Validate QR code
    final pass = await regProvider.validateQrCode(qrData);

    if (pass == null) {
      setState(() {
        _scanResult = ScanResult(
          success: false,
          message: 'Invalid QR code',
          studentName: null,
        );
        _isProcessing = false;
      });
      return;
    }

    // Check if pass is for this event
    if (pass.eventId != widget.eventId) {
      setState(() {
        _scanResult = ScanResult(
          success: false,
          message: 'Pass is for a different event',
          studentName: null,
        );
        _isProcessing = false;
      });
      return;
    }

    // Check if already checked in
    final isAttended = await _attendanceRepository.hasAttended(
      widget.eventId,
      pass.studentId,
    );

    if (isAttended) {
      final student = await _userRepository.getUserById(pass.studentId);
      setState(() {
        _scanResult = ScanResult(
          success: false,
          message: 'Already checked in',
          studentName: student?.name,
        );
        _isProcessing = false;
      });
      return;
    }

    // Check online status
    final isOnline = await _connectivityService.checkConnection();

    // Mark attendance
    try {
      if (isOnline) {
        // Online: Mark attendance immediately
        await _attendanceRepository.markAttendance(widget.eventId, pass.studentId);
        await regProvider.markAttendance(widget.eventId, pass.studentId);

        final student = await _userRepository.getUserById(pass.studentId);

        setState(() {
          _scanResult = ScanResult(
            success: true,
            message: 'Check-in successful!',
            studentName: student?.name,
          );
        });
      } else {
        // Offline: Queue for later sync
        final attendanceItem = OfflineAttendanceItem(
          studentId: pass.studentId,
          eventId: widget.eventId,
          qrData: qrData,
          scannedAt: DateTime.now(),
          scannedBy: authProvider.currentUser?.uid ?? 'unknown',
        );

        await _storageService.queueOfflineAttendance(attendanceItem);
        await syncProvider.updatePendingSyncCount();

        final student = await _userRepository.getUserById(pass.studentId);

        setState(() {
          _scanResult = ScanResult(
            success: true,
            message: 'Queued for sync (Offline)',
            studentName: student?.name,
          );
        });
      }
    } catch (e) {
      setState(() {
        _scanResult = ScanResult(
          success: false,
          message: isOnline ? 'Failed to mark attendance' : 'Failed to queue',
          studentName: null,
        );
      });
    }

    setState(() => _isProcessing = false);

    // Reset after delay
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) {
      setState(() {
        _scanResult = null;
        _lastScannedCode = null;
      });
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
                      'Scan QR Pass',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.grey[900],
                      ),
                    ),
                    const Spacer(),
                    // Sync button
                    const SyncButton(showLabel: false),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => _scannerController.toggleTorch(),
                      icon: Icon(
                        Icons.flash_on_rounded,
                        color: isDark ? Colors.white : Colors.grey[800],
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn().slideY(begin: -0.1, end: 0),

              // Scanner
              Expanded(
                child: Stack(
                  children: [
                    // Camera
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: MobileScanner(
                            controller: _scannerController,
                            onDetect: (capture) {
                              final barcodes = capture.barcodes;
                              if (barcodes.isNotEmpty) {
                                final qrData = barcodes.first.rawValue;
                                if (qrData != null) {
                                  _processQrCode(qrData);
                                }
                              }
                            },
                          ),
                        ),
                      ),
                    ),

                    // Scan overlay
                    Center(
                      child: Container(
                        width: 250,
                        height: 250,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: _scanResult?.success == true
                                ? AppTheme.successColor
                                : (_scanResult?.success == false
                                    ? AppTheme.errorColor
                                    : AppTheme.primaryColor),
                            width: 3,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: _isProcessing
                            ? const Center(child: CircularProgressIndicator())
                            : null,
                      ),
                    ),

                    // Result overlay
                    if (_scanResult != null)
                      Positioned(
                        bottom: 100,
                        left: 20,
                        right: 20,
                        child: GlassmorphismCard(
                          child: Row(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: _scanResult!.success
                                      ? AppTheme.successColor.withValues(alpha: 0.2)
                                      : AppTheme.errorColor.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  _scanResult!.success
                                      ? Icons.check_circle_rounded
                                      : Icons.error_rounded,
                                  color: _scanResult!.success
                                      ? AppTheme.successColor
                                      : AppTheme.errorColor,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (_scanResult!.studentName != null)
                                      Text(
                                        _scanResult!.studentName!,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: isDark ? Colors.white : Colors.grey[900],
                                        ),
                                      ),
                                    Text(
                                      _scanResult!.message,
                                      style: TextStyle(
                                        color: _scanResult!.success
                                            ? AppTheme.successColor
                                            : AppTheme.errorColor,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ).animate()
                          .fadeIn(duration: 200.ms)
                          .slideY(begin: 0.1, end: 0),
                      ),
                  ],
                ),
              ),

              // Instructions
              Padding(
                padding: const EdgeInsets.all(20),
                child: GlassmorphismCard(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: AppTheme.primaryColor,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Point camera at the student\'s QR pass to mark attendance',
                          style: TextStyle(
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ScanResult {
  final bool success;
  final String message;
  final String? studentName;

  ScanResult({
    required this.success,
    required this.message,
    this.studentName,
  });
}
