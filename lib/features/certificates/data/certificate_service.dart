import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:uems/core/constants/app_constants.dart';
import 'package:uems/features/certificates/domain/models/certificate_model.dart';
import 'package:intl/intl.dart';
import 'package:uems/core/services/local_storage_service.dart';
import 'package:uems/core/models/cached_certificate.dart';
import 'package:http/http.dart' as http;

/// Service for generating and managing certificates
class CertificateService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LocalStorageService _storageService = LocalStorageService();

  CollectionReference<Map<String, dynamic>> get _certificatesRef =>
      _firestore.collection(AppConstants.certificatesCollection);

  /// Save certificate metadata to Firestore
  Future<void> saveCertificateMetadata(CertificateModel certificate) async {
    await _certificatesRef.doc(certificate.id).set(certificate.toFirestore());
  }

  /// Generate PDF certificate
  Future<Uint8List> generateCertificatePdf({
    required String studentName,
    required String eventTitle,
    required DateTime eventDate,
    required String rollNumber,
    required String certificateId,
    String? organizerSignature,
    String? templateImageUrl,
    Map<String, dynamic>? templateConfig,
  }) async {
    final pdf = pw.Document();

    // Load fonts
    final font = await PdfGoogleFonts.poppinsRegular();
    final boldFont = await PdfGoogleFonts.poppinsBold();
    final italicFont = await PdfGoogleFonts.poppinsItalic();

    // Load template image if provided
    pw.MemoryImage? templateImage;
    if (templateImageUrl != null && templateImageUrl.isNotEmpty) {
      if (templateImageUrl.startsWith('http')) {
        try {
          final response = await http.get(Uri.parse(templateImageUrl));
          if (response.statusCode == 200) {
            templateImage = pw.MemoryImage(response.bodyBytes);
          }
        } catch (e) {
          print('Error loading template image from URL: $e');
        }
      } else {
        try {
          final bytes = base64Decode(templateImageUrl);
          templateImage = pw.MemoryImage(bytes);
        } catch (e) {
          print('Error decoding template image Base64: $e');
        }
      }
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: pw.EdgeInsets.zero,
        build: (pw.Context context) {
          final pageWidth = PdfPageFormat.a4.landscape.width;
          final pageHeight = PdfPageFormat.a4.landscape.height;

          if (templateImage != null) {
            return pw.Stack(
              children: [
                // Background Image
                pw.FullPage(
                  ignoreMargins: true,
                  child: pw.Image(templateImage, fit: pw.BoxFit.fill),
                ),
                
                // If Config Provided: Use Absolute Positioning from Config
                if (templateConfig != null) ...[
                   if (templateConfig.containsKey('studentName')) ...[
                     _buildPositionedText(
                       templateConfig['studentName'], 
                       studentName, 
                       boldFont, 
                       pageWidth, 
                       pageHeight
                     ),
                   ],
                   if (templateConfig.containsKey('rollNumber')) ...[
                     _buildPositionedText(
                       templateConfig['rollNumber'], 
                       rollNumber.isNotEmpty ? rollNumber : '', 
                       font, 
                       pageWidth, 
                       pageHeight
                     ),
                   ],
                ] else ...[
                  // Fallback: Default Hardcoded Layout if no config
                  pw.Positioned(
                    bottom: 150,
                    left: 40,
                    right: 40,
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                         pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(studentName, style: pw.TextStyle(font: boldFont, fontSize: 28)),
                            if (rollNumber.isNotEmpty) pw.Text(rollNumber, style: pw.TextStyle(font: font, fontSize: 16)),
                          ],
                        ),
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.end,
                          children: [
                            pw.Text(eventTitle, style: pw.TextStyle(font: boldFont, fontSize: 20)),
                            pw.Text(DateFormat('MMMM d, yyyy').format(eventDate), style: pw.TextStyle(font: font, fontSize: 16)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],

                // Certificate ID
                pw.Positioned(
                  bottom: 20,
                  right: 20,
                  child: pw.Text('Certificate ID: $certificateId', style: pw.TextStyle(font: font, fontSize: 10)),
                ),
              ],
            );
          } else {
            // Default Digital Design
            return pw.Container(
              width: double.infinity,
              height: double.infinity,
              decoration: pw.BoxDecoration(
                gradient: pw.LinearGradient(
                  colors: [
                    PdfColor.fromHex('#6366F1'),
                    PdfColor.fromHex('#8B5CF6'),
                  ],
                  begin: pw.Alignment.topLeft,
                  end: pw.Alignment.bottomRight,
                ),
              ),
              child: pw.Center(
                child: pw.Container(
                  margin: const pw.EdgeInsets.all(40),
                  padding: const pw.EdgeInsets.all(40),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.white,
                    borderRadius: pw.BorderRadius.circular(20),
                    boxShadow: [
                      pw.BoxShadow(
                        color: PdfColor.fromHex('#000000'),
                        blurRadius: 20,
                        offset: const PdfPoint(0, 10),
                      ),
                    ],
                  ),
                  child: pw.Column(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    children: [
                      pw.Text(
                        'CERTIFICATE',
                        style: pw.TextStyle(
                          font: boldFont,
                          fontSize: 48,
                          color: PdfColor.fromHex('#6366F1'),
                          letterSpacing: 8,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        'OF PARTICIPATION',
                        style: pw.TextStyle(
                          font: font,
                          fontSize: 24,
                          color: PdfColor.fromHex('#8B5CF6'),
                          letterSpacing: 4,
                        ),
                      ),
                      pw.SizedBox(height: 40),
                      pw.Container(
                        width: 100,
                        height: 3,
                        decoration: pw.BoxDecoration(
                          gradient: pw.LinearGradient(
                            colors: [
                              PdfColor.fromHex('#6366F1'),
                              PdfColor.fromHex('#8B5CF6'),
                            ],
                          ),
                        ),
                      ),
                      pw.SizedBox(height: 30),
                      pw.Text(
                        'This is to certify that',
                        style: pw.TextStyle(
                          font: italicFont,
                          fontSize: 16,
                          color: PdfColors.grey700,
                        ),
                      ),
                      pw.SizedBox(height: 20),
                      pw.Text(
                        studentName,
                        style: pw.TextStyle(
                          font: boldFont,
                          fontSize: 36,
                          color: PdfColors.grey900,
                        ),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                         rollNumber.isNotEmpty ? '($rollNumber)' : '',
                         style: pw.TextStyle(
                           font: font,
                           fontSize: 16,
                           color: PdfColors.grey700,
                         ),
                      ),
                      pw.SizedBox(height: 20),
                      pw.Text(
                        'has successfully participated in',
                        style: pw.TextStyle(
                          font: italicFont,
                          fontSize: 16,
                          color: PdfColors.grey700,
                        ),
                      ),
                      pw.SizedBox(height: 20),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 10,
                        ),
                        decoration: pw.BoxDecoration(
                          color: PdfColor.fromHex('#F3F4F6'),
                          borderRadius: pw.BorderRadius.circular(10),
                        ),
                        child: pw.Text(
                          eventTitle,
                          style: pw.TextStyle(
                            font: boldFont,
                            fontSize: 24,
                            color: PdfColor.fromHex('#6366F1'),
                          ),
                        ),
                      ),
                      pw.SizedBox(height: 20),
                      pw.Text(
                        'held on ${DateFormat('MMMM d, yyyy').format(eventDate)}',
                        style: pw.TextStyle(
                          font: font,
                          fontSize: 14,
                          color: PdfColors.grey600,
                        ),
                      ),
                      pw.SizedBox(height: 20),
                      pw.Text(
                        'Certificate ID: $certificateId',
                        style: pw.TextStyle(
                          font: font,
                          fontSize: 10,
                          color: PdfColors.grey500,
                        ),
                      ),
                      pw.SizedBox(height: 20),
                      pw.Container(
                        width: 100,
                        height: 3,
                        decoration: pw.BoxDecoration(
                          gradient: pw.LinearGradient(
                            colors: [
                              PdfColor.fromHex('#6366F1'),
                              PdfColor.fromHex('#8B5CF6'),
                            ],
                          ),
                        ),
                      ),
                      pw.SizedBox(height: 30),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.center,
                        children: [
                          pw.Container(
                            width: 50,
                            height: 50,
                            decoration: pw.BoxDecoration(
                              gradient: pw.LinearGradient(
                                colors: [
                                  PdfColor.fromHex('#6366F1'),
                                  PdfColor.fromHex('#8B5CF6'),
                                ],
                              ),
                              borderRadius: pw.BorderRadius.circular(12),
                            ),
                            child: pw.Center(
                              child: pw.Text(
                                'U',
                                style: pw.TextStyle(
                                  font: boldFont,
                                  fontSize: 28,
                                  color: PdfColors.white,
                                ),
                              ),
                            ),
                          ),
                          pw.SizedBox(width: 12),
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                'UEMS',
                                style: pw.TextStyle(
                                  font: boldFont,
                                  fontSize: 20,
                                  color: PdfColors.grey900,
                                ),
                              ),
                              pw.Text(
                                'University Event Management System',
                                style: pw.TextStyle(
                                  font: font,
                                  fontSize: 10,
                                  color: PdfColors.grey600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildPositionedText(
    Map<String, dynamic> config, 
    String text, 
    pw.Font font, 
    double pageWidth, 
    double pageHeight
  ) {
    final double x = (config['x'] ?? 0.5) * pageWidth;
    final double y = (config['y'] ?? 0.5) * pageHeight;
    final double fontSize = (config['fontSize'] ?? 16).toDouble();
    
    return pw.Positioned(
      left: x,
      top: y,
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: font,
          fontSize: fontSize,
          color: PdfColors.black,
        ),
      ),
    );
  }

  /// Generate and save certificate (with offline caching)
  Future<Uint8List> generateAndSaveCertificate({
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
    // Generate ID first
    final certificateId = CertificateModel.generateId(eventId, studentId);

    // Generate PDF
    final pdfBytes = await generateCertificatePdf(
      studentName: studentName,
      eventTitle: eventTitle,
      eventDate: eventDate,
      rollNumber: rollNumber,
      certificateId: certificateId,
      organizerSignature: organizerSignature,
      templateImageUrl: templateImageUrl,
      templateConfig: templateConfig,
    );

    // Save metadata to Firestore
    final certificate = CertificateModel(
      id: certificateId,
      eventId: eventId,
      eventTitle: eventTitle,
      studentId: studentId,
      studentName: studentName,
      eventDate: eventDate,
      generatedAt: DateTime.now(),
    );

    await saveCertificateMetadata(certificate);

    // Cache the certificate locally
    await _cacheCertificate(
      eventId: eventId,
      studentId: studentId,
      eventTitle: eventTitle,
      studentName: studentName,
      eventDate: eventDate,
      pdfBytes: pdfBytes,
    );

    return pdfBytes;
  }

  /// Check if certificate exists (metadata in Firestore)
  Future<bool> hasCertificate(String eventId, String studentId) async {
    final docId = CertificateModel.generateId(eventId, studentId);
    final doc = await _certificatesRef.doc(docId).get();
    return doc.exists;
  }

  /// Get all certificates for a student
  Future<List<CertificateModel>> getStudentCertificates(String studentId) async {
      final snapshot = await _certificatesRef
          .where('studentId', isEqualTo: studentId)
          .orderBy('generatedAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => CertificateModel.fromFirestore(doc))
          .toList();
  }

  /// Cache certificate to local storage
  Future<void> _cacheCertificate({
    required String eventId,
    required String studentId,
    required String eventTitle,
    required String studentName,
    required DateTime eventDate,
    required Uint8List pdfBytes,
  }) async {
    try {
      final cachedCert = CachedCertificate.fromPdfBytes(
        id: CertificateModel.generateId(eventId, studentId),
        eventId: eventId,
        studentId: studentId,
        eventTitle: eventTitle,
        studentName: studentName,
        eventDate: eventDate,
        pdfBytes: pdfBytes,
      );

      await _storageService.saveCertificate(cachedCert);
    } catch (e) {
      print('Error caching certificate: $e');
    }
  }

  ///Get cached certificate
  CachedCertificate? getCachedCertificate(String eventId, String studentId) {
    final certId = CertificateModel.generateId(eventId, studentId);
    return _storageService.getCertificate(certId);
  }

  /// Get all cached certificates
  List<CachedCertificate> getAllCachedCertificates() {
    return _storageService.getAllCertificates();
  }

  /// Print/share certificate
  Future<void> printCertificate(Uint8List pdfBytes, String fileName) async {
    await Printing.sharePdf(bytes: pdfBytes, filename: '$fileName.pdf');
  }
}
