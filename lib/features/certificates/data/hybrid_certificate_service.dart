import 'dart:typed_data';
import 'package:uems/core/services/certificate_api_service.dart';
import 'package:uems/features/certificates/data/certificate_service.dart';

/// Hybrid certificate service that supports both local and API generation
class HybridCertificateService {
  final CertificateService _localService = CertificateService();
  final CertificateApiService _apiService = CertificateApiService();
  
  // Toggle between local and API generation
  final bool useApi;
  
  HybridCertificateService({this.useApi = true});

  /// Generate certificate (uses API if enabled, falls back to local)
  Future<CertificateGenerationResult> generateAndSaveCertificate({
    required String eventId,
    required String eventTitle,
    required String studentId,
    required String studentName,
    required String rollNumber,
    required DateTime eventDate,
    String? organizerSignature,
    String? templateImageUrl,
    Map<String, dynamic>? templateConfig,
  }) async {
    if (useApi) {
      try {
        // Try API first
        final apiResponse = await _apiService.generateCertificate(
          eventId: eventId,
          eventName: eventTitle,
          eventDate: eventDate,
          studentId: studentId,
          studentName: studentName,
          rollNumber: rollNumber,
          organizerSignature: organizerSignature,
          templateImageUrl: templateImageUrl,
        );

        // ... existing API success code ...

        return CertificateGenerationResult(
          success: true,
          certificateId: apiResponse.certificateId,
          pdfUrl: apiResponse.pdfUrl,
          pdfBytes: null,
          source: 'api',
        );
      } catch (e) {
        print('API generation failed, falling back to local: $e');
        // Fall back to local generation
        return await _generateLocalCertificate(
          eventId: eventId,
          eventTitle: eventTitle,
          studentId: studentId,
          studentName: studentName,
          rollNumber: rollNumber,
          eventDate: eventDate,
          templateImageUrl: templateImageUrl,
          templateConfig: templateConfig,
          error: e.toString(),
        );
      }
    } else {
      // Use local generation
      return await _generateLocalCertificate(
        eventId: eventId,
        eventTitle: eventTitle,
        studentId: studentId,
        studentName: studentName,
        rollNumber: rollNumber,
        eventDate: eventDate,
        templateImageUrl: templateImageUrl,
        templateConfig: templateConfig,
      );
    }
  }

  /// Generate certificate locally
  Future<CertificateGenerationResult> _generateLocalCertificate({
    required String eventId,
    required String eventTitle,
    required String studentId,
    required String studentName,
    required String rollNumber,
    required DateTime eventDate,
    String? templateImageUrl,
    Map<String, dynamic>? templateConfig,
    String? error,
  }) async {
    try {
      final pdfBytes = await _localService.generateAndSaveCertificate(
        eventId: eventId,
        eventTitle: eventTitle,
        studentId: studentId,
        studentName: studentName,
        rollNumber: rollNumber,
        eventDate: eventDate,
        templateImageUrl: templateImageUrl,
        templateConfig: templateConfig,
      );

      final certificateId = _localService.getCachedCertificate(eventId, studentId)?.id;

      return CertificateGenerationResult(
        success: true,
        certificateId: certificateId!,
        pdfBytes: pdfBytes,
        source: 'local',
        apiError: error,
      );
    } catch (e) {
      return CertificateGenerationResult(
        success: false,
        error: 'Local generation failed: $e',
        apiError: error,
        source: 'local',
      );
    }
  }

  /// Check if certificate exists
  Future<bool> hasCertificate(String eventId, String studentId) async {
    return await _localService.hasCertificate(eventId, studentId);
  }

  /// Print/share certificate
  Future<void> printCertificate(Uint8List pdfBytes, String fileName) async {
    await _localService.printCertificate(pdfBytes, fileName);
  }

  /// Verify certificate via API
  Future<CertificateVerificationResult?> verifyCertificate(String certificateId) async {
    if (useApi) {
      try {
        return await _apiService.verifyCertificate(certificateId);
      } catch (e) {
        print('Certificate verification failed: $e');
        return null;
      }
    }
    return null;
  }

  /// Get student analytics from API
  Future<StudentAnalytics?> getStudentAnalytics(String studentId) async {
    if (useApi) {
      try {
        return await _apiService.getStudentAnalytics(studentId);
      } catch (e) {
        print('Failed to fetch analytics: $e');
        return null;
      }
    }
    return null;
  }
}

/// Certificate Generation Result
class CertificateGenerationResult {
  final bool success;
  final String? certificateId;
  final String? pdfUrl;
  final Uint8List? pdfBytes;
  final String source; // 'api' or 'local'
  final String? error;
  final String? apiError;

  CertificateGenerationResult({
    required this.success,
    this.certificateId,
    this.pdfUrl,
    this.pdfBytes,
    required this.source,
    this.error,
    this.apiError,
  });

  String get statusMessage {
    if (success) {
      if (source == 'api') {
        return 'Certificate generated via API';
      } else if (apiError != null) {
        return 'Generated locally (API unavailable)';
      } else {
        return 'Certificate generated locally';
      }
    } else {
      return error ?? 'Generation failed';
    }
  }
}
