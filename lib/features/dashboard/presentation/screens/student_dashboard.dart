import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:uems/app/routes.dart';
import 'package:uems/app/theme.dart';
import 'package:uems/core/widgets/glassmorphism_card.dart';
import 'package:uems/features/auth/presentation/providers/auth_provider.dart';
import 'package:uems/features/events/presentation/providers/event_provider.dart';
import 'package:uems/features/registration/presentation/providers/registration_provider.dart';
import 'package:uems/features/payment/presentation/screens/payment_screen.dart';
import 'package:uems/core/widgets/dashboard/dashboard_header.dart';
import 'package:uems/core/widgets/dashboard/dashboard_section.dart';
import 'package:uems/core/widgets/event_countdown_widget.dart';

/// Student dashboard with event discovery and registration
class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      Provider.of<EventProvider>(context, listen: false).startRealtimeEvents();
      Provider.of<RegistrationProvider>(context, listen: false)
          .loadStudentRegistrations(authProvider.currentUser?.uid ?? '');
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark ? AppTheme.darkGradient : null,
          color: isDark ? null : Colors.grey[100],
        ),
        child: SafeArea(
          child: IndexedStack(
            index: _currentIndex,
            children: [
              _buildHomeTab(isDark, user?.name ?? 'Student'),
              _buildEventsTab(isDark),
              _buildMyPassesTab(isDark),
              _buildSettingsTab(isDark),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(isDark),
    );
  }

  Widget _buildHomeTab(bool isDark, String userName) {
    return RefreshIndicator(
      onRefresh: () async {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        Provider.of<EventProvider>(context, listen: false).startRealtimeEvents();
        Provider.of<RegistrationProvider>(context, listen: false)
            .loadStudentRegistrations(authProvider.currentUser?.uid ?? '');
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DashboardHeader(
            userName: userName,
            subtitle: 'Welcome,',
            isDark: isDark,
          ),

          // Quick Actions
          DashboardSection(
            title: 'Quick Actions',
            isDark: isDark,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildQuickActionCard(
                        icon: Icons.calendar_month_rounded,
                        title: 'Calendar',
                        color: AppTheme.primaryColor,
                        onTap: () => Navigator.pushNamed(context, AppRoutes.calendar),
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildQuickActionCard(
                        icon: Icons.qr_code_rounded,
                        title: 'My Passes',
                        color: AppTheme.secondaryColor,
                        onTap: () => setState(() => _currentIndex = 2),
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildQuickActionCard(
                        icon: Icons.card_membership_rounded,
                        title: 'Certificates',
                        color: AppTheme.successColor,
                        onTap: () => Navigator.pushNamed(context, AppRoutes.myCertificates),
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildQuickActionCard(
                        icon: Icons.how_to_vote_rounded,
                        title: 'Proposals',
                        color: AppTheme.accentColor,
                        onTap: () => Navigator.pushNamed(context, AppRoutes.studentProposals),
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildQuickActionCard(
                        icon: Icons.add_circle_outline_rounded,
                        title: 'Request',
                        color: AppTheme.warningColor,
                        onTap: () => Navigator.pushNamed(context, AppRoutes.requestEvent),
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildQuickActionCard(
                        icon: Icons.alarm_rounded,
                        title: 'Reminders',
                        color: Colors.purple,
                        onTap: () => Navigator.pushNamed(context, AppRoutes.upcomingReminders),
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
              ],
            ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1, end: 0),
          ),

          // Event Countdown
          Consumer<EventProvider>(
            builder: (context, eventProvider, _) {
              final upcomingEvents = eventProvider.upcomingEvents;
              if (upcomingEvents.isEmpty) return const SizedBox.shrink();
              
              final nextEvent = upcomingEvents.first;
              return Column(
                children: [
                  const SizedBox(height: 16),
                  EventCountdownWidget(
                    nextEventDate: nextEvent.date,
                    eventName: nextEvent.title,
                    isDark: isDark,
                  ),
                ],
              );
            },
          ),

          // Organizer Features (conditional)
          Consumer<AuthProvider>(
            builder: (context, authProvider, _) {
              final user = authProvider.currentUser;
              if (user == null || !user.isOrganizer || user.permissions.isEmpty) {
                return const SizedBox.shrink();
              }

              return DashboardSection(
                title: 'Organizer Features',
                isDark: isDark,
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.2)),
                      ),
                      child: Text(
                        '${user.permissionCount} permission${user.permissionCount > 1 ? 's' : ''} active',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.1, end: 0),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        if (user.canCreateEvents)
                          _buildOrganizerFeatureCard(
                            icon: Icons.add_circle_rounded,
                            title: 'Create Event',
                            color: AppTheme.primaryColor,
                            onTap: () => Navigator.pushNamed(context, AppRoutes.createEvent),
                            isDark: isDark,
                          ),
                        if (user.canScanQR)
                          _buildOrganizerFeatureCard(
                            icon: Icons.qr_code_scanner_rounded,
                            title: 'Scan QR',
                            color: Colors.green,
                            onTap: () => Navigator.pushNamed(context, AppRoutes.adminQrScanner),
                            isDark: isDark,
                          ),
                        if (user.canManageFinance)
                          _buildOrganizerFeatureCard(
                            icon: Icons.account_balance_wallet_rounded,
                            title: 'Finance',
                            color: Colors.orange,
                            onTap: () => Navigator.pushNamed(context, '/payment-approval'),
                            isDark: isDark,
                          ),
                        if (user.canApproveEvents)
                          _buildOrganizerFeatureCard(
                            icon: Icons.check_circle_rounded,
                            title: 'Approve Events',
                            color: Colors.blue,
                            onTap: () => Navigator.pushNamed(context, AppRoutes.eventApproval),
                            isDark: isDark,
                          ),
                        if (user.canManageCertificates)
                          _buildOrganizerFeatureCard(
                            icon: Icons.card_membership_rounded,
                            title: 'Certificates',
                            color: Colors.purple,
                            onTap: () => Navigator.pushNamed(context, AppRoutes.uploadCertificates),
                            isDark: isDark,
                          ),
                      ],
                    ).animate().fadeIn(delay: 400.ms).scale(),
                  ],
                ),
              );
            },
          ),

          // Registered Events
          DashboardSection(
            title: 'My Registered Events',
            isDark: isDark,
            action: TextButton(
              onPressed: () => setState(() => _currentIndex = 2),
              child: const Text('View All'),
            ),
            child: Consumer<RegistrationProvider>(
              builder: (context, regProvider, _) {
                if (regProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
  
                final registeredEvents = regProvider.registeredEvents;
                if (registeredEvents.isEmpty) {
                  return GlassmorphismCard(
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.event_outlined,
                            size: 48,
                            color: isDark ? Colors.grey[600] : Colors.grey[400],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No registered events',
                            style: TextStyle(
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () => setState(() => _currentIndex = 1),
                            child: const Text('Browse events'),
                          ),
                        ],
                      ),
                    ),
                  );
                }
  
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: registeredEvents.length > 3 ? 3 : registeredEvents.length,
                  itemBuilder: (context, index) {
                    final event = registeredEvents[index];
                    return _buildRegisteredEventCard(event, isDark);
                  },
                );
              },
            ),
          ),

          // Upcoming Events
          DashboardSection(
            title: 'Upcoming Events',
            isDark: isDark,
            action: TextButton(
              onPressed: () => setState(() => _currentIndex = 1),
              child: const Text('View All'),
            ),
            child: Consumer<EventProvider>(
              builder: (context, eventProvider, _) {
                if (eventProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
  
                final events = eventProvider.upcomingEvents;
                if (events.isEmpty) {
                  return GlassmorphismCard(
                    child: Center(
                      child: Text(
                        'No upcoming events',
                        style: TextStyle(
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ),
                  );
                }
  
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: events.length > 3 ? 3 : events.length,
                  itemBuilder: (context, index) {
                    final event = events[index];
                    return _buildEventCard(event, isDark);
                  },
                );
              },
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GlassmorphismCard(
      padding: const EdgeInsets.all(12),
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.grey[900],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(dynamic event, bool isDark) {
    // Dynamic typing is risky but kept for compatibility. Casting to EventModel is better.
    // Assuming event is EventModel or has similar fields.
    
    return GlassmorphismCard(
      margin: const EdgeInsets.only(bottom: 16), // Increased margin
      padding: const EdgeInsets.all(0), // Padding inside card handled by children
      onTap: () => Navigator.pushNamed(
        context,
        AppRoutes.eventDetail,
        arguments: event.id,
      ),
      child: Column(
        children: [
          // 1. Image & Date Overlay
          Stack(
            children: [
              Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)), // Top corners only
                  color: isDark ? Colors.grey[800] : Colors.grey[200],
                  image: event.posterUrl != null
                      ? DecorationImage(
                          image: NetworkImage(event.posterUrl!),
                          fit: BoxFit.cover,
                        )
                      : (event.posterBase64 != null
                          ? DecorationImage(
                              image: MemoryImage(base64Decode(event.posterBase64!)),
                              fit: BoxFit.cover,
                            )
                          : null),
                ),
                child: (event.posterUrl == null && event.posterBase64 == null)
                    ? Center(
                        child: Icon(
                          Icons.event_rounded,
                          size: 48,
                          color: isDark ? Colors.grey[700] : Colors.grey[400],
                        ),
                      )
                    : null,
              ),
              // Date Badge on Top Left
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9), // Always white for contrast
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${event.date.day}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                          height: 1.0,
                        ),
                      ),
                      Text(
                        _getMonthAbbr(event.date.month),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Price Badge on Top Right
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: event.isPaid ? AppTheme.primaryColor : AppTheme.successColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    event.isPaid ? 'PKR ${event.entryFee?.toStringAsFixed(0)}' : 'Free',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          // 2. Details Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.grey[900],
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                
                // Info Row (Time & Venue)
                Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 16,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      event.startTime,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.location_on_outlined,
                      size: 16,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        event.venue,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Action Buttons
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pushNamed(
                      context,
                      AppRoutes.eventDetail,
                      arguments: event.id,
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(
                        color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'View Details',
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.grey[900],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleParticipate(dynamic event) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final regProvider = Provider.of<RegistrationProvider>(context, listen: false);
    
    if (authProvider.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to participate')),
      );
      return;
    }

    // Check if event is paid
    if (event.isPaid == true) {
      // Show payment confirmation dialog
      final shouldProceed = await _showPaymentConfirmation(event);
      if (!shouldProceed) return;
      
      // Navigate to payment screen
      if (!mounted) return;
      final paymentSuccess = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentScreen(
            eventId: event.id,
            eventName: event.title,
            amount: event.entryFee ?? 0.0,
            studentId: authProvider.currentUser!.uid,
            onPaymentSuccess: (transactionId) async {
              // Register after successful payment
              await _completeRegistration(event, transactionId: transactionId);
            },
          ),
        ),
      );
      
      if (paymentSuccess == true) {
        // Refresh registrations
        await regProvider.loadStudentRegistrations(authProvider.currentUser!.uid);
        if (mounted) {
          _showQRPass(event, authProvider.currentUser);
        }
      }
      return;
    }

    // Free event - register directly
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    await _completeRegistration(event);
  }

  Future<bool> _showPaymentConfirmation(dynamic event) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Paid Event'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.payments_rounded, size: 48, color: AppTheme.primaryColor),
            const SizedBox(height: 16),
            Text(
              event.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Entry Fee: PKR ${event.entryFee?.toStringAsFixed(0) ?? '0'}',
              style: TextStyle(
                fontSize: 18,
                color: AppTheme.successColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'You will be redirected to complete the payment.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Proceed to Payment'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _completeRegistration(dynamic event, {String? transactionId}) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final regProvider = Provider.of<RegistrationProvider>(context, listen: false);

    try {
      final registrationId = await regProvider.registerForEvent(
        eventId: event.id,
        eventName: event.title,
        eventDate: event.date,
        studentId: authProvider.currentUser!.uid,
        rollNumber: authProvider.currentUser!.rollNumber ?? '',
        studentName: authProvider.currentUser!.name,
        studentEmail: authProvider.currentUser!.email,
        isPaidEvent: event.isPaid == true,
        entryFee: event.entryFee,
        paymentId: transactionId,
      );

      if (!mounted) return;
      
      // Close loading dialog if showing (for free events)
      if (transactionId == null) {
        Navigator.pop(context);
      }

      if (registrationId != null) {
        // Refresh registrations
        await regProvider.loadStudentRegistrations(authProvider.currentUser!.uid);
        
        if (!mounted) return;
        // Show QR pass
        _showQRPass(event, authProvider.currentUser);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Successfully registered! Your QR pass is ready.'),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(regProvider.error ?? 'Registration failed'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        if (transactionId == null) {
          Navigator.pop(context);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  void _showQRPass(dynamic event, dynamic user) {
    if (user == null) return;
    
    // Check for expiry
    if (event.isPast) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('This event has expired. QR Pass is no longer valid.'),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Generate QR data
    final qrData = 'UEMS_PASS|${event.id}|${user.uid}|${user.name}|${user.email}';
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
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
            const SizedBox(height: 20),
            Text(
              'Event QR Pass',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).brightness == Brightness.dark 
                    ? Colors.white 
                    : Colors.grey[900],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              event.title,
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark 
                    ? Colors.grey[400] 
                    : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 30),
            // QR Code
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: QrImageView(
                data: qrData,
                version: QrVersions.auto,
                size: 200,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            // User info
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.person_outline, size: 18),
                      const SizedBox(width: 8),
                      Text(user.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.email_outlined, size: 18),
                      const SizedBox(width: 8),
                      Text(user.email, style: const TextStyle(fontSize: 13)),
                    ],
                  ),
                ],
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Show this QR code at the event entrance',
                style: TextStyle(color: Colors.grey[500]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegisteredEventCard(dynamic event, bool isDark) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    return GlassmorphismCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      onTap: () => _showQRPass(event, authProvider.currentUser),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppTheme.successColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: AppTheme.successColor,
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
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.grey[900],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${event.date.day}/${event.date.month}/${event.date.year}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                if (event.isPast) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'EXPIRED',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          ElevatedButton(
            onPressed: event.isPast 
                ? null 
                : () => _showQRPass(event, authProvider.currentUser),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              disabledBackgroundColor: Colors.grey[300],
              padding: const EdgeInsets.symmetric(horizontal: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              event.isPast ? 'Expired' : 'QR Pass',
              style: TextStyle(
                color: event.isPast ? Colors.grey[600] : Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventsTab(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Upcoming Events',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.grey[900],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Only future events are shown',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey[500] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Consumer<EventProvider>(
              builder: (context, eventProvider, _) {
                if (eventProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Use upcomingEvents to filter out past events
                final events = eventProvider.upcomingEvents;
                if (events.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.event_outlined,
                          size: 80,
                          color: isDark ? Colors.grey[600] : Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No upcoming events',
                          style: TextStyle(
                            fontSize: 18,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Check back later for new events!',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.grey[500] : Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: events.length,
                  itemBuilder: (context, index) {
                    final event = events[index];
                    return _buildEventCard(event, isDark);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyPassesTab(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'My QR Passes',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.grey[900],
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Consumer<RegistrationProvider>(
              builder: (context, regProvider, _) {
                if (regProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                final events = regProvider.registeredEvents;
                if (events.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.qr_code_rounded,
                          size: 80,
                          color: isDark ? Colors.grey[600] : Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No passes yet',
                          style: TextStyle(
                            fontSize: 18,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Register for events to get QR passes',
                          style: TextStyle(
                            color: isDark ? Colors.grey[500] : Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: events.length,
                  itemBuilder: (context, index) {
                    final event = events[index];
                    return _buildRegisteredEventCard(event, isDark);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTab(bool isDark) {
    final authProvider = Provider.of<AuthProvider>(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Settings',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.grey[900],
            ),
          ),
          const SizedBox(height: 20),
          GlassmorphismCard(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(
                    Icons.person_outline,
                    color: isDark ? Colors.grey[400] : Colors.grey[700],
                  ),
                  title: Text(
                    'Profile',
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.grey[900],
                    ),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                  onTap: () => Navigator.pushNamed(context, AppRoutes.profile),
                ),
                const Divider(),
                ListTile(
                  leading: Icon(
                    Icons.card_membership_rounded,
                    color: isDark ? Colors.grey[400] : Colors.grey[700],
                  ),
                  title: Text(
                    'My Certificates',
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.grey[900],
                    ),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                  onTap: () => Navigator.pushNamed(context, AppRoutes.myCertificates),
                ),
                const Divider(),
                ListTile(
                  leading: Icon(
                    Icons.notifications_outlined,
                    color: isDark ? Colors.grey[400] : Colors.grey[700],
                  ),
                  title: Text(
                    'Notifications',
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.grey[900],
                    ),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                  onTap: () => Navigator.pushNamed(context, AppRoutes.notifications),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(
                    Icons.logout_rounded,
                    color: AppTheme.errorColor,
                  ),
                  title: const Text(
                    'Logout',
                    style: TextStyle(color: AppTheme.errorColor),
                  ),
                  onTap: () async {
                    await authProvider.signOut();
                    if (mounted) {
                      Navigator.pushReplacementNamed(context, AppRoutes.login);
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: isDark ? Colors.grey[600] : Colors.grey[400],
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event_rounded),
            label: 'Events',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.qr_code_rounded),
            label: 'My Passes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  Widget _buildOrganizerFeatureCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GlassmorphismCard(
      onTap: onTap,
      child: Container(
        width: 100,
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.grey[900],
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  String _getMonthAbbr(int month) {
    const months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 
                    'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
    return months[month - 1];
  }
}
