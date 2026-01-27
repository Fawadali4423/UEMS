import 'package:flutter/material.dart';
import 'package:uems/features/auth/presentation/screens/login_screen.dart';
import 'package:uems/features/auth/presentation/screens/register_screen.dart';
import 'package:uems/features/auth/presentation/screens/splash_screen.dart';
import 'package:uems/features/dashboard/presentation/screens/admin_dashboard.dart';
import 'package:uems/features/organizer/presentation/screens/organizer_main_screen.dart';
import 'package:uems/features/dashboard/presentation/screens/student_dashboard.dart';
import 'package:uems/features/events/presentation/screens/create_event_screen.dart';
import 'package:uems/features/events/presentation/screens/event_detail_screen.dart';
import 'package:uems/features/events/presentation/screens/event_approval_screen.dart';
import 'package:uems/features/events/presentation/screens/event_registrations_screen.dart';
import 'package:uems/features/admin/presentation/screens/admin_events_list_screen.dart';
import 'package:uems/features/calendar/presentation/screens/calendar_screen.dart';
import 'package:uems/features/qr_pass/presentation/screens/qr_pass_screen.dart';
import 'package:uems/features/attendance/presentation/screens/qr_scanner_screen.dart';
import 'package:uems/features/admin/presentation/screens/admin_qr_scanner_screen.dart';
import 'package:uems/features/certificates/presentation/screens/certificate_screen.dart';
import 'package:uems/features/certificates/presentation/screens/my_certificates_screen.dart';
import 'package:uems/features/certificates/presentation/screens/verify_certificate_screen.dart';
import 'package:uems/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:uems/features/profile/presentation/screens/profile_screen.dart';
import 'package:uems/features/events/domain/models/event_model.dart';
import 'package:uems/features/proposals/presentation/screens/student_proposals_screen.dart';
import 'package:uems/features/proposals/presentation/screens/student_request_event_screen.dart';
import 'package:uems/features/admin/presentation/screens/manage_organizers_screen.dart';
import 'package:uems/features/admin/presentation/screens/student_attendance_screen.dart';
import 'package:uems/features/admin/presentation/screens/upload_certificates_screen.dart';
import 'package:uems/features/admin/presentation/screens/requested_events_screen.dart';
import 'package:uems/features/admin/presentation/screens/approved_events_screen.dart';
import 'package:uems/features/reminders/presentation/screens/upcoming_reminders_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  
  // Dashboards
  static const String adminDashboard = '/admin-dashboard';
  static const String organizerDashboard = '/organizer-dashboard';
  static const String studentDashboard = '/student-dashboard';
  
  // Events
  static const String createEvent = '/create-event';
  static const String eventDetail = '/event-detail';
  static const String eventApproval = '/event-approval';
  static const String requestedEvents = '/requested-events';
  static const String approvedEvents = '/approved-events';
  static const String eventRegistrations = '/event-registrations';
  static const String adminEventsList = '/admin-events-list';
  static const String calendar = '/calendar';
  
  // QR & Attendance
  static const String qrPass = '/qr-pass';
  static const String qrScanner = '/qr-scanner';
  static const String adminQrScanner = '/admin-qr-scanner';
  
  // Certificates
  static const String certificate = '/certificate';
  static const String myCertificates = '/my-certificates';
  static const String verifyCertificate = '/verify-certificate';
  
  // Other
  static const String notifications = '/notifications';
  static const String profile = '/profile';
  
  // Student Features
  static const String studentProposals = '/student-proposals';
  static const String requestEvent = '/request-event';
  static const String upcomingReminders = '/upcoming-reminders';
  
  // Admin Features
  static const String manageOrganizers = '/manage-organizers';
  static const String studentAttendance = '/student-attendance';
  static const String uploadCertificates = '/upload-certificates';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return _buildPageRoute(const SplashScreen(), settings);
      
      case login:
        return _buildPageRoute(const LoginScreen(), settings);
      
      case register:
        return _buildPageRoute(const RegisterScreen(), settings);
      
      case adminDashboard:
        return _buildPageRoute(const AdminDashboard(), settings);
      
      case organizerDashboard:
        return _buildPageRoute(const OrganizerMainScreen(), settings);
      
      case studentDashboard:
        return _buildPageRoute(const StudentDashboard(), settings);
      
      case createEvent:
        return _buildPageRoute(const CreateEventScreen(), settings);
      
      case eventDetail:
        final eventId = settings.arguments as String;
        return _buildPageRoute(EventDetailScreen(eventId: eventId), settings);
      
case eventApproval:
        return _buildPageRoute(const EventApprovalScreen(), settings);
      
      case requestedEvents:
        return _buildPageRoute(const RequestedEventsScreen(), settings);
      
      case approvedEvents:
        return _buildPageRoute(const ApprovedEventsScreen(), settings);
      
      case calendar:
        return _buildPageRoute(const CalendarScreen(), settings);
      
      case qrPass:
        final args = settings.arguments as Map<String, String>;
        return _buildPageRoute(
          QrPassScreen(eventId: args['eventId']!, studentId: args['studentId']!),
          settings,
        );
      
      case qrScanner:
        final eventId = settings.arguments as String;
        return _buildPageRoute(QrScannerScreen(eventId: eventId), settings);
      
      case adminQrScanner:
        return _buildPageRoute(const AdminQrScannerScreen(), settings);
      
      case adminEventsList:
        return _buildPageRoute(const AdminEventsListScreen(), settings);
      
      case eventRegistrations:
        final event = settings.arguments as EventModel;
        return _buildPageRoute(EventRegistrationsScreen(event: event), settings);
      
      case certificate:
        final args = settings.arguments as Map<String, String>;
        return _buildPageRoute(
          CertificateScreen(eventId: args['eventId']!, studentId: args['studentId']!),
          settings,
        );
      
      case myCertificates:
        return _buildPageRoute(const MyCertificatesScreen(), settings);

      case verifyCertificate:
        return _buildPageRoute(const VerifyCertificateScreen(), settings);
      
      case notifications:
        return _buildPageRoute(const NotificationsScreen(), settings);
      
      case profile:
        return _buildPageRoute(const ProfileScreen(), settings);
      
      case studentProposals:
        return _buildPageRoute(const StudentProposalsScreen(), settings);
      
      case requestEvent:
        return _buildPageRoute(const StudentRequestEventScreen(), settings);
      
      case upcomingReminders:
        return _buildPageRoute(const UpcomingRemindersScreen(), settings);
      
      case manageOrganizers:
        return _buildPageRoute(const ManageOrganizersScreen(), settings);
      
      case studentAttendance:
        return _buildPageRoute(const StudentAttendanceScreen(), settings);
      
      case uploadCertificates:
        return _buildPageRoute(const UploadCertificatesScreen(), settings);
      
      default:
        return _buildPageRoute(
          Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
          settings,
        );
    }
  }

  static PageRouteBuilder _buildPageRoute(Widget page, RouteSettings settings) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOutCubic;
        
        var tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );
        
        var offsetAnimation = animation.drive(tween);
        var fadeAnimation = animation.drive(
          Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: curve)),
        );
        
        return SlideTransition(
          position: offsetAnimation,
          child: FadeTransition(
            opacity: fadeAnimation,
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

  /// Get the appropriate dashboard route based on user role
  static String getDashboardRoute(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return adminDashboard;
      case 'student':
      default:
        return studentDashboard;
    }
  }
}
