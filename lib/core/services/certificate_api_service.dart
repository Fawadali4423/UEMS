import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uems/features/certificates/domain/models/certificate_model.dart';
import 'package:uems/core/constants/app_constants.dart';

/// API service for certificate generation using Laravel backend
class CertificateApiService {
  static const String baseUrl = 'https://api.easycode4u.com/uems-api1/uems-api/api';
  // static const String baseUrl = 'http://127.0.0.1:8000/api';
  
  final Dio _dio;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  CertificateApiService() : _dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  )) {
    _setupInterceptors();
  }

  /// Setup interceptors for authentication and logging
  void _setupInterceptors() {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Add Firebase auth token
        try {
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            final token = await user.getIdToken();
            options.headers['Authorization'] = 'Bearer $token';
          }
        } catch (e) {
          print('Error getting auth token: $e');
        }
        return handler.next(options);
      },
      onResponse: (response, handler) {
        print('API Response: ${response.statusCode} - ${response.requestOptions.path}');
        return handler.next(response);
      },
      onError: (error, handler) {
        print('API Error: ${error.response?.statusCode} - ${error.message}');
        return handler.next(error);
      },
    ));
  }

  /// Generate certificate via API
  Future<CertificateApiResponse> generateCertificate({
    required String eventId,
    required String eventName,
    required DateTime eventDate,
    required String studentId,
    required String studentName,
    required String rollNumber,
    String templateType = 'participation',
    String? organizerSignature,
    String? templateImageUrl,
  }) async {
    try {
      final response = await _dio.post(
        '/certificates/generate',
        data: {
          'eventId': eventId,
          'eventName': eventName,
          'eventDate': eventDate.toIso8601String().split('T')[0],
          'studentId': studentId,
          'studentName': studentName,
          'rollNumber': rollNumber,
          'templateType': templateType,
          'organizerSignature': organizerSignature ?? 'Event Organizer',
          'templateImageUrl': templateImageUrl,
          'issueDate': DateTime.now().toIso8601String().split('T')[0],
          'certificateId': CertificateModel.generateId(eventId, studentId),
        },
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return CertificateApiResponse.fromJson(response.data['data']);
      } else {
        throw Exception(response.data['message'] ?? 'Failed to generate certificate');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        throw Exception(e.response?.data['error']['message'] ?? 'Invalid data');
      } else if (e.response?.statusCode == 401) {
        throw Exception('Authentication failed. Please login again.');
      } else if (e.response?.statusCode == 500) {
        throw Exception('Server error. Please try again later.');
      } else {
        throw Exception('Network error: ${e.message}');
      }
    } catch (e) {
      throw Exception('Error generating certificate: $e');
    }
  }

  /// Verify certificate via API
  Future<CertificateVerificationResult> verifyCertificate(String certificateId) async {
    try {
      final response = await _dio.get('/certificates/verify/$certificateId');

      if (response.statusCode == 200 && response.data['success'] == true) {
        return CertificateVerificationResult.fromJson(response.data['data']);
      } else {
        throw Exception('Certificate not found or invalid');
      }
    } catch (e) {
      throw Exception('Error verifying certificate: $e');
    }
  }

  /// Download certificate PDF from URL
  Future<Uint8List> downloadCertificatePdf(String pdfUrl) async {
    try {
      final response = await _dio.get(
        pdfUrl,
        options: Options(responseType: ResponseType.bytes),
      );

      return Uint8List.fromList(response.data);
    } catch (e) {
      throw Exception('Error downloading PDF: $e');
    }
  }

  /// Save certificate metadata to Firestore after API generation
  Future<void> saveCertificateMetadata({
    required String certificateId,
    required String eventId,
    required String eventTitle,
    required String studentId,
    required String studentName,
    required DateTime eventDate,
    required String pdfUrl,
  }) async {
    try {
      final certificate = CertificateModel(
        id: certificateId,
        eventId: eventId,
        eventTitle: eventTitle,
        studentId: studentId,
        studentName: studentName,
        eventDate: eventDate,
        generatedAt: DateTime.now(),
        pdfUrl: pdfUrl,
      );

      await _firestore
          .collection(AppConstants.certificatesCollection)
          .doc(certificateId)
          .set(certificate.toFirestore());
    } catch (e) {
      print('Error saving certificate metadata: $e');
      rethrow;
    }
  }

  /// Get student analytics from API
  Future<StudentAnalytics> getStudentAnalytics(String studentId) async {
    try {
      final response = await _dio.get('/analytics/student/$studentId');

      if (response.statusCode == 200 && response.data['success'] == true) {
        return StudentAnalytics.fromJson(response.data['data']);
      } else {
        throw Exception('Failed to fetch analytics');
      }
    } catch (e) {
      throw Exception('Error fetching student analytics: $e');
    }
  }

  /// Check event conflicts via API
  Future<ConflictCheckResult> checkEventConflicts({
    required String eventId,
    required DateTime date,
    required String startTime,
    required String endTime,
    required String venue,
    int buffer = 30,
    List<String>? excludeEventIds,
  }) async {
    try {
      final response = await _dio.post(
        '/events/check-conflicts',
        data: {
          'eventId': eventId,
          'date': date.toIso8601String().split('T')[0],
          'startTime': startTime,
          'endTime': endTime,
          'venue': venue,
          'buffer': buffer,
          'excludeEventIds': excludeEventIds ?? [],
        },
        options: Options(
          validateStatus: (status) {
            // Accept all status codes to handle them ourselves
            return status != null && status < 600;
          },
        ),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return ConflictCheckResult.fromJson(response.data['data']);
      } else {
        throw Exception('Failed to check conflicts');
      }
    } on DioException catch (e) {
      print('Conflict check API error: ${e.response?.statusCode} - ${e.message}');
      if (e.response?.statusCode == 500) {
        // Server error - return no conflict to allow creation
        print('Server error during conflict check, allowing event creation');
        return ConflictCheckResult(
          hasConflict: false,
          conflictingEvents: [],
          suggestions: [],
        );
      } else if (e.response?.statusCode == 401) {
        throw Exception('Authentication failed. Please login again.');
      } else {
        // Network or other errors - allow creation with warning
        print('Network error during conflict check: ${e.message}');
        return ConflictCheckResult(
          hasConflict: false,
          conflictingEvents: [],
          suggestions: [],
        );
      }
    } catch (e) {
      print('Unexpected error during conflict check: $e');
      // Return no conflict on unexpected errors to not block creation
      return ConflictCheckResult(
        hasConflict: false,
        conflictingEvents: [],
        suggestions: [],
      );
    }
  }

  /// Send push notification via API
  Future<void> sendNotification({
    required String type,
    required List<String> recipients,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      await _dio.post(
        '/notifications/send',
        data: {
          'recipients': {
            'type': 'users',
            'ids': recipients,
          },
          'notification': {
            'title': title,
            'body': body,
            'data': data ?? {},
          },
          'priority': 'high',
        },
      );
    } catch (e) {
      print('Error sending notification: $e');
    }
  }

  /// Create event in Laravel API (for conflict checking and consistency)
  Future<void> createEvent(Map<String, dynamic> eventData) async {
    try {
      await _dio.post(
        '/events', // Assuming standard resource route
        data: eventData,
      );
    } catch (e) {
      print('Error creating event in API: $e');
      // Non-blocking error - we still want Firestore to work
      // throw Exception('Failed to sync event to API: $e'); 
    }
  }

  /// Delete event from Laravel API
  Future<void> deleteEvent(String eventId) async {
    try {
      await _dio.delete('/events/$eventId');
    } catch (e) {
      print('Error deleting event from API: $e');
      // Non-blocking, as Firestore deletion handles UI
    }
  }

  /// Upload certificate image to Laravel API storage
  Future<String> uploadCertificateImage(List<int> imageBytes, String fileName, String eventId, [Map<String, dynamic>? templateConfig]) async {
    try {
      // Create multipart form data
      final map = {
        'certificate': MultipartFile.fromBytes(
          imageBytes,
          filename: fileName,
        ),
        'eventId': eventId,
      };

      if (templateConfig != null) {
        map['templateConfig'] = jsonEncode(templateConfig);
      }

      FormData formData = FormData.fromMap(map);

      final response = await _dio.post(
        '/certificates/upload',
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      if ((response.statusCode == 200 || response.statusCode == 201) && response.data['success'] == true) {
        return response.data['data']['imageUrl'];
      } else {
        throw Exception(response.data['message'] ?? 'Failed to upload image');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 413) {
        throw Exception('Image too large. Please compress it first.');
      } else if (e.response?.statusCode == 401) {
        throw Exception('Authentication failed. Please login again.');
      } else {
        throw Exception('Upload failed: ${e.message}');
      }
    } catch (e) {
      throw Exception('Error uploading certificate image: $e');
    }
  }
}

/// Certificate API Response Model
class CertificateApiResponse {
  final String certificateId;
  final String pdfUrl;
  final String? pdfBase64;
  final DateTime generatedAt;

  CertificateApiResponse({
    required this.certificateId,
    required this.pdfUrl,
    this.pdfBase64,
    required this.generatedAt,
  });

  factory CertificateApiResponse.fromJson(Map<String, dynamic> json) {
    return CertificateApiResponse(
      certificateId: json['certificateId'],
      pdfUrl: json['pdfUrl'],
      pdfBase64: json['pdfBase64'],
      generatedAt: DateTime.parse(json['generatedAt']),
    );
  }

  /// Get PDF bytes from base64
  Uint8List? getPdfBytes() {
    if (pdfBase64 != null) {
      return base64Decode(pdfBase64!);
    }
    return null;
  }
}

/// Certificate Verification Result
class CertificateVerificationResult {
  final bool valid;
  final String certificateId;
  final String eventName;
  final String studentName;
  final DateTime issueDate;
  final DateTime verifiedAt;

  CertificateVerificationResult({
    required this.valid,
    required this.certificateId,
    required this.eventName,
    required this.studentName,
    required this.issueDate,
    required this.verifiedAt,
  });

  factory CertificateVerificationResult.fromJson(Map<String, dynamic> json) {
    return CertificateVerificationResult(
      valid: json['valid'],
      certificateId: json['certificateId'],
      eventName: json['eventName'],
      studentName: json['studentName'],
      issueDate: DateTime.parse(json['issueDate']),
      verifiedAt: DateTime.parse(json['verifiedAt']),
    );
  }
}

/// Student Analytics Model
class StudentAnalytics {
  final String studentId;
  final String studentName;
  final String rollNumber;
  final AnalyticsStatistics statistics;
  final List<EventHistory> eventHistory;

  StudentAnalytics({
    required this.studentId,
    required this.studentName,
    required this.rollNumber,
    required this.statistics,
    required this.eventHistory,
  });

  factory StudentAnalytics.fromJson(Map<String, dynamic> json) {
    return StudentAnalytics(
      studentId: json['studentId'],
      studentName: json['studentName'],
      rollNumber: json['rollNumber'],
      statistics: AnalyticsStatistics.fromJson(json['statistics']),
      eventHistory: (json['eventHistory'] as List)
          .map((e) => EventHistory.fromJson(e))
          .toList(),
    );
  }
}

class AnalyticsStatistics {
  final int totalEventsRegistered;
  final int totalEventsAttended;
  final double attendanceRate;
  final int certificatesEarned;

  AnalyticsStatistics({
    required this.totalEventsRegistered,
    required this.totalEventsAttended,
    required this.attendanceRate,
    required this.certificatesEarned,
  });

  factory AnalyticsStatistics.fromJson(Map<String, dynamic> json) {
    return AnalyticsStatistics(
      totalEventsRegistered: json['totalEventsRegistered'],
      totalEventsAttended: json['totalEventsAttended'],
      attendanceRate: (json['attendanceRate'] as num).toDouble(),
      certificatesEarned: json['certificatesEarned'],
    );
  }
}

class EventHistory {
  final String eventId;
  final String eventName;
  final DateTime date;
  final bool attended;
  final bool certificateIssued;

  EventHistory({
    required this.eventId,
    required this.eventName,
    required this.date,
    required this.attended,
    required this.certificateIssued,
  });

  factory EventHistory.fromJson(Map<String, dynamic> json) {
    return EventHistory(
      eventId: json['eventId'],
      eventName: json['eventName'],
      date: DateTime.parse(json['date']),
      attended: json['attended'],
      certificateIssued: json['certificateIssued'],
    );
  }
}

/// Conflict Check Result Model
class ConflictCheckResult {
  final bool hasConflict;
  final String? conflictType;
  final List<ConflictingEvent> conflictingEvents;
  final List<String> suggestions;

  ConflictCheckResult({
    required this.hasConflict,
    this.conflictType,
    required this.conflictingEvents,
    required this.suggestions,
  });

  factory ConflictCheckResult.fromJson(Map<String, dynamic> json) {
    return ConflictCheckResult(
      hasConflict: json['hasConflict'],
      conflictType: json['conflictType'],
      conflictingEvents: json['conflictingEvents'] != null
          ? (json['conflictingEvents'] as List)
              .map((e) => ConflictingEvent.fromJson(e))
              .toList()
          : [],
      suggestions: json['suggestions'] != null
          ? List<String>.from(json['suggestions'])
          : [],
    );
  }
}

class ConflictingEvent {
  final String eventId;
  final String name;
  final String venue;
  final String startTime;
  final String endTime;
  final int overlapMinutes;

  ConflictingEvent({
    required this.eventId,
    required this.name,
    required this.venue,
    required this.startTime,
    required this.endTime,
    required this.overlapMinutes,
  });

  factory ConflictingEvent.fromJson(Map<String, dynamic> json) {
    return ConflictingEvent(
      eventId: json['eventId'],
      name: json['name'],
      venue: json['venue'],
      startTime: json['startTime'],
      endTime: json['endTime'],
      overlapMinutes: json['overlapMinutes'],
    );
  }
}
