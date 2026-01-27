import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uems/app/theme.dart';
import 'package:uems/core/widgets/glassmorphism_card.dart';
import 'package:uems/core/services/certificate_api_service.dart';
import 'package:uems/features/events/presentation/providers/event_provider.dart';
import 'package:uems/features/events/domain/models/event_model.dart';
import 'package:uems/features/events/presentation/widgets/certificate_template_editor.dart';
import 'dart:convert';

/// Admin screen to upload certificates for events using Laravel API
class UploadCertificatesScreen extends StatefulWidget {
  const UploadCertificatesScreen({super.key});

  @override
  State<UploadCertificatesScreen> createState() => _UploadCertificatesScreenState();
}

class _UploadCertificatesScreenState extends State<UploadCertificatesScreen> {
  final ImagePicker _picker = ImagePicker();
  final CertificateApiService _apiService = CertificateApiService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  bool _isUploading = false;
  String? _selectedEventId;
  File? _templateFile;
  Map<String, dynamic>? _templateConfig;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<EventProvider>(context, listen: false).loadAllEvents();
    });
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
                child: Consumer<EventProvider>(
                  builder: (context, provider, _) {
                    if (provider.isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final pastEvents = provider.pastEvents;

                    if (pastEvents.isEmpty) {
                      return _buildEmptyState(isDark);
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: pastEvents.length,
                      itemBuilder: (context, index) {
                        final event = pastEvents[index];
                        return _buildEventCard(event, isDark);
                      },
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

  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(20),
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
                  'Upload Certificates',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.grey[900],
                  ),
                ),
                Text(
                  'Upload to Laravel API',
                  style: TextStyle(
                    fontSize: 14,
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

  Widget _buildEventCard(EventModel event, bool isDark) {
    return FutureBuilder<bool>(
      future: _hasCertificate(event.id),
      builder: (context, snapshot) {
        final hasCert = snapshot.data ?? false;

        return GlassmorphismCard(
          margin: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: hasCert ? AppTheme.primaryGradient : 
                          LinearGradient(colors: [Colors.grey[600]!, Colors.grey[700]!]),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      hasCert ? Icons.check_circle_rounded : Icons.upload_file_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.grey[900],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today_rounded,
                              size: 12,
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${event.date.day}/${event.date.month}/${event.date.year}',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Icon(
                              Icons.location_on_rounded,
                              size: 12,
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                event.venue,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (hasCert) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.successColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.cloud_done_rounded,
                        size: 16,
                        color: AppTheme.successColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Certificate Uploaded',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.successColor,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => _pickAndEditCertificate(event),
                        child: const Text('Replace'),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isUploading ? null : () => _pickAndEditCertificate(event),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.cloud_upload_rounded, size: 18),
                    label: Text(
                      _isUploading && _selectedEventId == event.id
                          ? 'Uploading to API...'
                          : 'Upload to Laravel API',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_busy_rounded,
            size: 80,
            color: isDark ? Colors.grey[700] : Colors.grey[300],
          ),
          const SizedBox(height: 24),
          Text(
            'No Completed Events',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.grey[900],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Certificates can only be uploaded for past events',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _hasCertificate(String eventId) async {
    try {
      final doc = await _firestore
          .collection('event_certificates')
          .doc(eventId)
          .get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  Future<void> _pickAndEditCertificate(EventModel event) async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
      maxWidth: 1920,
    );

    if (image == null) return;

    final file = File(image.path);
    
    if (!mounted) return;

    // Show Editor Dialog
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        insetPadding: EdgeInsets.zero,
        backgroundColor: Colors.black87,
        child: Column(
          children: [
            AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: const Text('Design Certificate'),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
              actions: [
                TextButton.icon(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                    _uploadFinalCertificate(event, file, _templateConfig);
                  },
                  icon: const Icon(Icons.check, color: AppTheme.successColor),
                  label: const Text('Save & Upload', style: TextStyle(color: AppTheme.successColor)),
                ),
              ],
            ),
            Expanded(
              child: CertificateTemplateEditor(
                templateImage: file,
                onConfigChanged: (config) {
                   _templateConfig = config;
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _uploadFinalCertificate(EventModel event, File imageFile, Map<String, dynamic>? config) async {
    setState(() {
      _isUploading = true;
      _selectedEventId = event.id;
    });

    try {
      final bytes = await imageFile.readAsBytes();
      final fileName = 'certificate_${event.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final base64Image = base64Encode(bytes);

      // Upload to Laravel API
      final imageUrl = await _apiService.uploadCertificateImage(
        bytes,
        fileName,
        event.id,
        config, // Send config to API
      );

      // Save metadata to Firestore (Including Config!)
      await _firestore.collection('event_certificates').doc(event.id).set({
        'eventId': event.id,
        'eventTitle': event.title,
        'imageUrl': imageUrl,
        'imageBase64': base64Image, // Backup
        'templateConfig': config, // Store the coordinates
        'uploadedAt': Timestamp.now(),
        'uploadedBy': 'admin',
        'source': 'laravel_api',
      });
      
      // ALSO update the main Event document so MyCertificatesScreen (via EventModel) can see it if needed
      // But MyCertificatesScreen uses event_certificates for uploaded ones.
      // However, we should keep them in sync if possible.
      // For now, storing in event_certificates is enough for the "Uploaded" section.

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Certificate Template Saved & Uploaded for ${event.title}'),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _selectedEventId = null;
          _templateConfig = null;
        });
      }
    }
  }
}
