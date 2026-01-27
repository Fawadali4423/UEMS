import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:uems/app/theme.dart';
import 'package:uems/core/widgets/animated_button.dart';
import 'package:uems/core/widgets/glassmorphism_card.dart';
import 'package:uems/features/auth/presentation/providers/auth_provider.dart';
import 'package:uems/features/certificates/data/hybrid_certificate_service.dart';
import 'package:uems/features/events/presentation/providers/event_provider.dart';
import 'package:uems/features/attendance/data/attendance_repository.dart';

/// Screen for viewing and downloading certificates
class CertificateScreen extends StatefulWidget {
  final String eventId;
  final String studentId;

  const CertificateScreen({
    super.key,
    required this.eventId,
    required this.studentId,
  });

  @override
  State<CertificateScreen> createState() => _CertificateScreenState();
}

class _CertificateScreenState extends State<CertificateScreen> {
  final HybridCertificateService _certificateService = HybridCertificateService(
    useApi: true, // Set to true to use Laravel API, false for local PDF only
  );
  final AttendanceRepository _attendanceRepository = AttendanceRepository();

  bool _isLoading = false;
  bool _hasAttended = false;
  bool _hasCertificate = false;
  Uint8List? _pdfBytes;
  String? _certificateUrl;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkEligibility();
      Provider.of<EventProvider>(context, listen: false).loadEvent(widget.eventId);
    });
  }

  Future<void> _checkEligibility() async {
    setState(() => _isLoading = true);

    _hasAttended = await _attendanceRepository.hasAttended(
      widget.eventId,
      widget.studentId,
    );

    _hasCertificate = await _certificateService.hasCertificate(
      widget.eventId,
      widget.studentId,
    );

    setState(() => _isLoading = false);
  }

  Future<void> _generateCertificate() async {
    setState(() => _isLoading = true);

    final eventProvider = Provider.of<EventProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final event = eventProvider.selectedEvent;
    final user = authProvider.currentUser;

    if (event == null || user == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      // Use HybridCertificateService - tries API first, falls back to local
      final result = await _certificateService.generateAndSaveCertificate(
        eventId: widget.eventId,
        eventTitle: event.title,
        studentId: widget.studentId,
        studentName: user.name,
        rollNumber: user.rollNumber ?? user.email,
        eventDate: event.date,
        organizerSignature: 'Event Organizer',
        templateImageUrl: event.certificateTemplateBase64,
        templateConfig: event.templateConfig,
      );

      if (result.success) {
        setState(() {
          _hasCertificate = true;
          _pdfBytes = result.pdfBytes;
          _certificateUrl = result.pdfUrl;
          _isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.statusMessage),
              backgroundColor: AppTheme.successColor,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        throw Exception(result.error ?? 'Failed to generate certificate');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _downloadCertificate() async {
    final eventProvider = Provider.of<EventProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final event = eventProvider.selectedEvent;
    final user = authProvider.currentUser;

    if (event == null || user == null) return;

    setState(() => _isLoading = true);

    try {
      // Use already generated PDF bytes
      if (_pdfBytes != null) {
        await _certificateService.printCertificate(
          _pdfBytes!,
          'Certificate_${event.title.replaceAll(' ', '_')}_${user.name.replaceAll(' ', '_')}',
        );
      } else {
        throw Exception('Certificate not generated yet');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to download: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }

    setState(() => _isLoading = false);
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
                      'Certificate',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.grey[900],
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn().slideY(begin: -0.1, end: 0),

              // Content
              Expanded(
                child: Consumer<EventProvider>(
                  builder: (context, eventProvider, _) {
                    if (eventProvider.isLoading || _isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final event = eventProvider.selectedEvent;
                    if (event == null) {
                      return const Center(child: Text('Event not found'));
                    }

                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          // Certificate Preview
                          GlassmorphismCard(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              children: [
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    gradient: AppTheme.primaryGradient,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Icon(
                                    Icons.card_membership_rounded,
                                    size: 40,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  'Certificate of Participation',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : Colors.grey[900],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  event.title,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${event.date.day}/${event.date.month}/${event.date.year}',
                                  style: TextStyle(
                                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ).animate().fadeIn(delay: 100.ms).scale(
                            begin: const Offset(0.95, 0.95),
                            end: const Offset(1, 1),
                          ),

                          const SizedBox(height: 24),

                          // Status Card
                          GlassmorphismCard(
                            child: Column(
                              children: [
                                _buildStatusRow(
                                  icon: Icons.event_available_rounded,
                                  label: 'Attendance',
                                  value: _hasAttended ? 'Confirmed' : 'Not Attended',
                                  isSuccess: _hasAttended,
                                  isDark: isDark,
                                ),
                                const Divider(),
                                _buildStatusRow(
                                  icon: Icons.card_membership_rounded,
                                  label: 'Certificate',
                                  value: _hasCertificate ? 'Generated' : 'Not Generated',
                                  isSuccess: _hasCertificate,
                                  isDark: isDark,
                                ),
                              ],
                            ),
                          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0),

                          const SizedBox(height: 30),

                          // Action Buttons
                          if (!_hasAttended)
                            GlassmorphismCard(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.info_outline_rounded,
                                    color: AppTheme.warningColor,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'You need to attend the event to get a certificate',
                                      style: TextStyle(
                                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else if (!_hasCertificate)
                            AnimatedButton(
                              text: 'Generate Certificate',
                              icon: Icons.add_rounded,
                              isLoading: _isLoading,
                              onPressed: _generateCertificate,
                            )
                          else
                            AnimatedButton(
                              text: 'Download Certificate',
                              icon: Icons.download_rounded,
                              isLoading: _isLoading,
                              onPressed: _downloadCertificate,
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusRow({
    required IconData icon,
    required String label,
    required String value,
    required bool isSuccess,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: (isSuccess ? AppTheme.successColor : AppTheme.warningColor)
                  .withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: isSuccess ? AppTheme.successColor : AppTheme.warningColor,
              size: 20,
            ),
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
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.grey[900],
                  ),
                ),
              ],
            ),
          ),
          Icon(
            isSuccess ? Icons.check_circle_rounded : Icons.pending_rounded,
            color: isSuccess ? AppTheme.successColor : AppTheme.warningColor,
          ),
        ],
      ),
    );
  }
}
