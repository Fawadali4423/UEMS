import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uems/app/routes.dart';
import 'package:uems/app/theme.dart';
import 'package:uems/core/widgets/glassmorphism_card.dart';
import 'package:uems/features/auth/presentation/providers/auth_provider.dart';
import 'package:uems/features/certificates/data/certificate_service.dart';
import 'package:uems/features/certificates/domain/models/certificate_model.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uems/features/attendance/data/attendance_repository.dart';
import 'package:uems/features/events/presentation/providers/event_provider.dart';
import 'package:uems/features/registration/data/registration_repository.dart';
import 'package:uems/core/services/certificate_api_service.dart';
import 'package:printing/printing.dart';

/// Screen showing all certificates for a student
class MyCertificatesScreen extends StatefulWidget {
  const MyCertificatesScreen({super.key});

  @override
  State<MyCertificatesScreen> createState() => _MyCertificatesScreenState();
}

class _MyCertificatesScreenState extends State<MyCertificatesScreen> {
  final CertificateService _certificateService = CertificateService();
  final CertificateApiService _apiService = CertificateApiService();
  final RegistrationRepository _regRepository = RegistrationRepository();
  final AttendanceRepository _attendanceRepository = AttendanceRepository();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  List<CertificateModel> _generatedCertificates = [];
  List<Map<String, dynamic>> _uploadedCertificates = [];
  List<Map<String, dynamic>> _pendingCertificates = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCertificates();
    });
  }

  Future<void> _loadCertificates() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final studentId = authProvider.currentUser?.uid ?? '';

    if (mounted) setState(() => _isLoading = true);

    // Load generated certificates
    try {
      _generatedCertificates = await _certificateService.getStudentCertificates(studentId);
    } catch (e) {
      print('Error loading generated certificates: $e');
      if (mounted && e.toString().contains('requires an index')) {
           print('Missing Index Error: $e'); 
      }
    }
    
    // Load uploaded certificates
    try {
      await _loadUploadedCertificates(studentId);
    } catch (e) {
      print('Error loading uploaded certificates: $e');
    }

    // Load pending certificates
    try {
      await _loadPendingCertificates(studentId);
    } catch (e) {
      print('Error loading pending certificates: $e');
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadPendingCertificates(String studentId) async {
    // 1. Get attended event IDs
    final attendedEventIds = await _attendanceRepository.getStudentAttendedEvents(studentId);
    
    if (attendedEventIds.isEmpty) return;

    final pendingList = <Map<String, dynamic>>[];
    
    // 2. Filter events where certificate checks return false
    for (final eventId in attendedEventIds) {
      // Check in generated list
      final hasGenerated = _generatedCertificates.any((c) => c.eventId == eventId);
      // Check in uploaded list
      final hasUploaded = _uploadedCertificates.any((c) => c['eventId'] == eventId);
      
      if (!hasGenerated && !hasUploaded) {
         try {
           final eventDoc = await _firestore.collection('events').doc(eventId).get();
           if (eventDoc.exists) {
             final data = eventDoc.data()!;
             pendingList.add({
               'eventId': eventId,
               'title': data['title'] ?? 'Unknown Event',
               'date': (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
             });
           }
         } catch (e) {
           print('Error fetching event details for $eventId: $e');
         }
      }
    }

    if (mounted) {
      setState(() {
        _pendingCertificates = pendingList;
      });
    }
  }

  Future<void> _loadUploadedCertificates(String studentId) async {
    try {
      // Get all attended events for this student
      final registrations = await _regRepository.getStudentRegistrations(studentId);
      
      final uploadedCerts = <Map<String, dynamic>>[];
      
      for (var registration in registrations) {
        // Check if admin has uploaded a certificate for this event
        final certDoc = await _firestore
            .collection('event_certificates')
            .doc(registration.eventId)
            .get();
            
        if (certDoc.exists) {
          final data = certDoc.data()!;
          uploadedCerts.add({
            'eventId': registration.eventId,
            'eventTitle': data['eventTitle'] ?? 'Event',
            'imageUrl': data['imageUrl'],
            'templateConfig': data['templateConfig'], // Fetch config
            'uploadedAt': data['uploadedAt'] as Timestamp,
          });
        }
      }
      
      if (mounted) {
        setState(() {
          _uploadedCertificates = uploadedCerts;
        });
      }
    } catch (e) {
      print('Error loading uploaded certificates: $e');
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
              _buildHeader(isDark),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : (_generatedCertificates.isEmpty && _uploadedCertificates.isEmpty && _pendingCertificates.isEmpty)
                        ? _buildEmptyState(isDark)
                        : ListView(
                            padding: const EdgeInsets.all(20),
                            children: [
                              if (_uploadedCertificates.isNotEmpty) ...[
                                _buildSectionHeader(
                                  'Event Certificates',
                                  'Uploaded by organizers',
                                  isDark,
                                ),
                                const SizedBox(height: 12),
                                ..._uploadedCertificates.asMap().entries.map((entry) {
                                  return _buildUploadedCertCard(
                                    entry.value,
                                    isDark,
                                    entry.key,
                                  );
                                }),
                                const SizedBox(height: 24),
                              ],
                              if (_generatedCertificates.isNotEmpty) ...[
                                _buildSectionHeader(
                                  'Generated Certificates',
                                  'Auto-generated attendance certificates',
                                  isDark,
                                ),
                                const SizedBox(height: 12),
                                ..._generatedCertificates.asMap().entries.map((entry) {
                                  return _buildGeneratedCertCard(
                                    entry.value,
                                    isDark,
                                    entry.key,
                                  );
                                }),
                                const SizedBox(height: 24),
                              ],
                              if (_pendingCertificates.isNotEmpty) ...[
                                _buildSectionHeader(
                                  'Pending Certificates',
                                  'Events you attended - Generate your certificate now!',
                                  isDark,
                                  isAction: true,
                                ),
                                const SizedBox(height: 12),
                                ..._pendingCertificates.asMap().entries.map((entry) {
                                  return _buildPendingCertCard(
                                    entry.value,
                                    isDark,
                                    entry.key,
                                  );
                                }),
                              ],
                            ],
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Padding(
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'My Certificates',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.grey[900],
                  ),
                ),
                Text(
                  '${_generatedCertificates.length + _uploadedCertificates.length} certificates',
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
    ).animate().fadeIn().slideY(begin: -0.1, end: 0);
  }

  Widget _buildSectionHeader(String title, String subtitle, bool isDark, {bool isAction = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isAction ? AppTheme.primaryColor : (isDark ? Colors.white : Colors.grey[900]),
              ),
            ),
            if (isAction) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('NEW', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
              ),
            ]
          ],
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildUploadedCertCard(Map<String, dynamic> cert, bool isDark, int index) {
    return GlassmorphismCard(
      margin: const EdgeInsets.only(bottom: 16),
      onTap: () => _viewUploadedCertificate(cert),
      child: Row(
        children: [
          // Certificate preview image
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              cert['imageUrl'],
              width: 70,
              height: 70,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stack) => Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.image_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cert['eventTitle'],
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.grey[900],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.verified_rounded,
                      size: 14,
                      color: AppTheme.accentColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Official Certificate',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.accentColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: isDark ? Colors.grey[600] : Colors.grey[400],
          ),
        ],
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: 100 * index)).slideX(begin: 0.05, end: 0);
  }

  Widget _buildGeneratedCertCard(CertificateModel cert, bool isDark, int index) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    return GlassmorphismCard(
      margin: const EdgeInsets.only(bottom: 16),
      onTap: () => Navigator.pushNamed(
        context,
        AppRoutes.certificate,
        arguments: {
          'eventId': cert.eventId,
          'studentId': authProvider.currentUser?.uid ?? '',
        },
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.card_membership_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cert.eventTitle,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.grey[900],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 14,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${cert.eventDate.day}/${cert.eventDate.month}/${cert.eventDate.year}',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.successColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.download_rounded,
                  size: 16,
                  color: AppTheme.successColor,
                ),
                const SizedBox(width: 4),
                Text(
                  'PDF',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.successColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: 100 * (index + _uploadedCertificates.length))).slideX(begin: 0.05, end: 0);
  }

  Widget _buildPendingCertCard(Map<String, dynamic> event, bool isDark, int index) {
    // Helper to format date
    final date = event['date'] as DateTime;
    final dateStr = '${date.day}/${date.month}/${date.year}';
    
    return GlassmorphismCard(
      margin: const EdgeInsets.only(bottom: 16),
      onTap: () {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        Navigator.pushNamed(
          context,
          AppRoutes.certificate,
          arguments: {
            'eventId': event['eventId'],
            'studentId': authProvider.currentUser?.uid ?? '',
          },
        ).then((_) => _loadCertificates()); // Reload on return
      },
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
            ),
            child: Icon(
              Icons.auto_awesome_rounded,
              color: AppTheme.primaryColor,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event['title'],
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.grey[900],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 14,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      dateStr,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                 Text(
                  'Generate',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 4),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 14,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: 100 * (index + _uploadedCertificates.length + _generatedCertificates.length))).slideX(begin: 0.05, end: 0);
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.card_membership_rounded,
            size: 80,
            color: isDark ? Colors.grey[600] : Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No certificates yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Attend events to earn certificates',
            style: TextStyle(
              color: isDark ? Colors.grey[500] : Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  void _viewUploadedCertificate(Map<String, dynamic> cert) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Close button
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ),
              // Certificate image
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  cert['imageUrl'],
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 16),
              // Download button
              ElevatedButton.icon(
                onPressed: () => _downloadCertificate(
                  cert['imageUrl'], 
                  cert['eventTitle'],
                  true, // isImage
                  cert['templateConfig'] // Pass config
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                icon: const Icon(Icons.download_rounded),
                label: const Text('Download'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _downloadCertificate(String url, String eventName, bool isImage, [Map<String, dynamic>? templateConfig]) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // Security Check: Ensure user is logged in
    final user = authProvider.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Security Warning: You must be logged in.')),
      );
      return;
    }

    try {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Generating certificate...'),
            duration: Duration(seconds: 1),
          ),
        );
      }

      if (isImage) {
        // Dynamic Template Generation
        // URL is the image URL, we use it as a template
        final pdfBytes = await _certificateService.generateAndSaveCertificate(
          eventId: 'uploaded_${DateTime.now().millisecondsSinceEpoch}', // Dummy ID or match event
          eventTitle: eventName,
          studentId: user.uid,
          studentName: user.name,
          rollNumber: user.rollNumber ?? '',
          eventDate: DateTime.now(),
          templateImageUrl: url,
          templateConfig: templateConfig,
        );

        await Printing.sharePdf(
          bytes: pdfBytes,
          filename: 'Certificate_${eventName.replaceAll(' ', '_')}.pdf',
        );

      } else {
        // Download PDF via API Service
        final pdfBytes = await _apiService.downloadCertificatePdf(url);
        await Printing.sharePdf(
          bytes: pdfBytes,
          filename: 'Certificate_${eventName.replaceAll(' ', '_')}.pdf',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download failed: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }
}
