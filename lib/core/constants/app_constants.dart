/// Application-wide constants
class AppConstants {
  // App Info
  static const String appName = 'UEMS';
  static const String appFullName = 'University Event Management System';
  static const String appVersion = '1.0.0';
  
  // User Roles
  static const String roleAdmin = 'admin';
  static const String roleOrganizer = 'organizer';
  static const String roleStudent = 'student';
  
  static const List<String> allRoles = [roleAdmin, roleOrganizer, roleStudent];
  
  // Event Status
  static const String statusPending = 'pending';
  static const String statusApproved = 'approved';
  static const String statusRejected = 'rejected';
  static const String statusCompleted = 'completed';
  
  // Firestore Collections
  static const String usersCollection = 'users';
  static const String eventsCollection = 'events';
  static const String registrationsCollection = 'registrations';
  static const String passesCollection = 'passes';
  static const String certificatesCollection = 'certificates';
  static const String attendanceCollection = 'attendance';
  static const String paymentsCollection = 'payments';
  static const String notificationsCollection = 'notifications';
  static const String proposalsCollection = 'proposals';
  static const String votesCollection = 'votes';
  
  // Notification Types
  static const String notifEventApproved = 'event_approved';
  static const String notifEventRejected = 'event_rejected';
  static const String notifEventReminder = 'event_reminder';
  static const String notifQrPassIssued = 'qr_pass_issued';
  static const String notifCertificateReady = 'certificate_ready';
  static const String notifAdminBroadcast = 'admin_broadcast';
  
  // Animation Durations
  static const Duration animFast = Duration(milliseconds: 200);
  static const Duration animMedium = Duration(milliseconds: 400);
  static const Duration animSlow = Duration(milliseconds: 600);
  
  // Validation
  static const int minPasswordLength = 6;
  static const int maxTitleLength = 100;
  static const int maxDescriptionLength = 500;
}
