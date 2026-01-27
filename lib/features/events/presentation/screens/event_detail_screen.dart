import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:uems/app/routes.dart';
import 'package:uems/app/theme.dart';
import 'package:uems/core/utils/date_utils.dart' as date_utils;
import 'package:uems/core/widgets/animated_button.dart';
import 'package:uems/core/widgets/glassmorphism_card.dart';
import 'package:uems/features/auth/presentation/providers/auth_provider.dart';
import 'package:uems/features/events/presentation/providers/event_provider.dart';
import 'package:uems/features/payment/domain/models/payment_model.dart';
import 'package:uems/features/payment/presentation/providers/payment_provider.dart';
import 'package:uems/features/payment/presentation/screens/payment_screen.dart';
import 'package:uems/features/registration/presentation/providers/registration_provider.dart';

/// Screen showing event details with registration option
class EventDetailScreen extends StatefulWidget {
  final String eventId;

  const EventDetailScreen({super.key, required this.eventId});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<EventProvider>(context, listen: false).loadEvent(widget.eventId);
      _checkRegistration();
    });
  }

  Future<void> _checkRegistration() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final regProvider = Provider.of<RegistrationProvider>(context, listen: false);
    final paymentProvider = Provider.of<PaymentProvider>(context, listen: false);
    
    final currentUser = authProvider.currentUser;

    if (currentUser?.isStudent ?? false) {
      await Future.wait([
        regProvider.checkRegistration(
          widget.eventId,
          currentUser?.uid ?? '',
        ),
        paymentProvider.getPaymentForEvent(
          widget.eventId, 
          currentUser?.uid ?? '',
        ),
      ]);
      
      if (mounted) {
        setState(() {}); // Refresh UI after checks
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authProvider = Provider.of<AuthProvider>(context);
    final isStudent = authProvider.currentUser?.isStudent ?? false;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark ? AppTheme.darkGradient : null,
          color: isDark ? null : Colors.grey[100],
        ),
        child: SafeArea(
          child: Consumer<EventProvider>(
            builder: (context, eventProvider, _) {
              if (eventProvider.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              final event = eventProvider.selectedEvent;
              if (event == null) {
                return Center(
                  child: Text(
                    'Event not found',
                    style: TextStyle(
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                );
              }

              final isExpired = event.isPast;

              return Column(
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
                        const Spacer(),
                        if (isExpired) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'EXPIRED',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                          ),
                        ],
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(event.status).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            event.status.toUpperCase(),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _getStatusColor(event.status),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn().slideY(begin: -0.1, end: 0),

                  // Content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Event Image/Header
                          Container(
                            width: double.infinity,
                            height: 250, // Increased height for better visibility
                            decoration: BoxDecoration(
                              gradient: event.posterBase64 == null ? AppTheme.primaryGradient : null,
                              borderRadius: BorderRadius.circular(20),
                              image: event.posterBase64 != null
                                  ? DecorationImage(
                                      image: MemoryImage(
                                        base64Decode(event.posterBase64!),
                                      ),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: event.posterBase64 == null
                                ? const Icon(
                                    Icons.event_rounded,
                                    size: 60,
                                    color: Colors.white,
                                  )
                                : null,
                          ).animate().fadeIn().scale(begin: const Offset(0.95, 0.95)),

                          const SizedBox(height: 24),

                          // Title
                          Text(
                            event.title,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.grey[900],
                            ),
                          ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.05, end: 0),

                          const SizedBox(height: 8),

                          // Organizer
                          Row(
                            children: [
                              const Icon(
                                Icons.person_outline,
                                size: 18,
                                color: AppTheme.primaryColor,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'By ${event.organizerName}',
                                style: TextStyle(
                                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                                ),
                              ),
                            ],
                          ).animate().fadeIn(delay: 150.ms),

                          const SizedBox(height: 24),

                          // Info Cards
                          Row(
                            children: [
                              Expanded(
                                child: _buildInfoCard(
                                  icon: Icons.calendar_today_rounded,
                                  title: 'Date',
                                  value: date_utils.DateTimeUtils.formatDate(event.date),
                                  isDark: isDark,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildInfoCard(
                                  icon: Icons.access_time_rounded,
                                  title: 'Time',
                                  value: '${date_utils.DateTimeUtils.timeStringToDisplay(event.startTime)} - ${date_utils.DateTimeUtils.timeStringToDisplay(event.endTime)}',
                                  isDark: isDark,
                                ),
                              ),
                            ],
                          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0),

                          const SizedBox(height: 12),

                          Row(
                            children: [
                              Expanded(
                                child: _buildInfoCard(
                                  icon: Icons.location_on_rounded,
                                  title: 'Venue',
                                  value: event.venue,
                                  isDark: isDark,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildInfoCard(
                                  icon: Icons.people_rounded,
                                  title: 'Participants',
                                  value: '${event.participantCount}',
                                  isDark: isDark,
                                ),
                              ),
                            ],
                          ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.1, end: 0),

                          const SizedBox(height: 24),

                          // Description
                          Text(
                            'About',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.grey[900],
                            ),
                          ),
                          const SizedBox(height: 12),
                          GlassmorphismCard(
                            child: Text(
                              event.description,
                              style: TextStyle(
                                fontSize: 15,
                                height: 1.6,
                                color: isDark ? Colors.grey[300] : Colors.grey[700],
                              ),
                            ),
                          ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1, end: 0),

                          const SizedBox(height: 30),

                          // Action Button (for students)
                          if (isStudent && event.isApproved)
                            Consumer2<RegistrationProvider, PaymentProvider>(
                              builder: (context, regProvider, paymentProvider, _) {
                                // Check local state first, then provider state
                                // We might want to store the payment object locally if provider doesn't cache it well enough
                                // For now assuming provider has methods to get cached state or we rely on FutureBuilder which is not ideal in build
                                // Better: Use the state we fetched in _checkRegistration
                                
                                return FutureBuilder<PaymentModel?>(
                                  future: paymentProvider.getPaymentForEvent(widget.eventId, authProvider.currentUser?.uid ?? ''),
                                  builder: (context, snapshot) {
                                    final payment = snapshot.data;
                                    
                                    // 1. Approved / Registered -> Check Registration Provider as backup or Payment Provider
                                    // If payment approved, show QR
                                    if (payment?.status == PaymentStatus.completed) {
                                       return Column(
                                        children: [
                                          GlassmorphismCard(
                                            padding: const EdgeInsets.all(16),
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
                                                const Expanded(
                                                  child: Text(
                                                    'You are participating in this event!',
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          AnimatedButton(
                                            text: 'View QR Pass',
                                            icon: Icons.qr_code_rounded,
                                            onPressed: () => Navigator.pushNamed(
                                              context,
                                              AppRoutes.qrPass,
                                              arguments: {
                                                'eventId': widget.eventId,
                                                'studentId': authProvider.currentUser?.uid ?? '',
                                              },
                                            ),
                                          ),
                                        ],
                                      );
                                    }

                                    // 2. Pending Payment
                                    if (payment?.status == PaymentStatus.pending) {
                                      return Column(
                                        children: [
                                          GlassmorphismCard(
                                            padding: const EdgeInsets.all(16),
                                            child: Column(
                                              children: [
                                                Row(
                                                  children: [
                                                    Container(
                                                      width: 50,
                                                      height: 50,
                                                      decoration: BoxDecoration(
                                                        color: AppTheme.warningColor.withValues(alpha: 0.2),
                                                        borderRadius: BorderRadius.circular(12),
                                                      ),
                                                      child: const Icon(
                                                        Icons.hourglass_top_rounded,
                                                        color: AppTheme.warningColor,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 14),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          const Text(
                                                            'Payment Verification Pending',
                                                            style: TextStyle(
                                                              fontWeight: FontWeight.bold,
                                                            ),
                                                          ),
                                                          const SizedBox(height: 4),
                                                          Text(
                                                            'Admin is reviewing your payment.',
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
                                                if (payment?.manualTransactionId != null) ...[
                                                  const SizedBox(height: 12),
                                                  Container(
                                                     padding: const EdgeInsets.all(8),
                                                     width: double.infinity,
                                                     decoration: BoxDecoration(
                                                       color: isDark ? Colors.black26 : Colors.grey[200],
                                                       borderRadius: BorderRadius.circular(8),
                                                     ),
                                                     child: Text(
                                                       'Txn ID: ${payment?.manualTransactionId}',
                                                       style: TextStyle(
                                                         fontFamily: 'Courier',
                                                         fontSize: 12,
                                                         color: isDark ? Colors.grey[300] : Colors.grey[800],
                                                       ),
                                                     ),
                                                  ),
                                                ]
                                              ],
                                            ),
                                          ),
                                        ],
                                      );
                                    }

                                    // 3. Rejected Payment
                                    if (payment?.status == PaymentStatus.failed) {
                                        return Column(
                                        children: [
                                          GlassmorphismCard(
                                            padding: const EdgeInsets.all(16),
                                            child: Row(
                                              children: [
                                                Container(
                                                  width: 50,
                                                  height: 50,
                                                  decoration: BoxDecoration(
                                                    color: AppTheme.errorColor.withValues(alpha: 0.2),
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  child: const Icon(
                                                    Icons.error_outline_rounded,
                                                    color: AppTheme.errorColor,
                                                  ),
                                                ),
                                                const SizedBox(width: 14),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      const Text(
                                                        'Payment Rejected',
                                                        style: TextStyle(
                                                          fontWeight: FontWeight.bold,
                                                          color: AppTheme.errorColor,
                                                        ),
                                                      ),
                                                      if (payment?.adminComment != null) ...[
                                                        const SizedBox(height: 4),
                                                        Text(
                                                          payment!.adminComment!,
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            color: isDark ? Colors.grey[300] : Colors.grey[800],
                                                          ),
                                                        ),
                                                      ]
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          AnimatedButton(
                                            text: 'Retry Payment',
                                            icon: Icons.refresh_rounded,
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => PaymentScreen(
                                                    eventId: widget.eventId,
                                                    eventName: event.title,
                                                    amount: 500, // Hardcoded for now, or fetch from event
                                                    studentId: authProvider.currentUser?.uid ?? '',
                                                    onPaymentSuccess: (tid) {
                                                      _checkRegistration(); // Refresh status
                                                    },
                                                  ),
                                                ),
                                              ).then((_) => _checkRegistration());
                                            },
                                          ),
                                        ],
                                      );
                                    }

                                    // 4. No Payment -> Show Participate Button
                                    return AnimatedButton(
                                      text: 'Participate (PKR 500)',
                                      icon: Icons.confirmation_number_rounded,
                                      isLoading: regProvider.isLoading,
                                      onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => PaymentScreen(
                                                eventId: widget.eventId,
                                                eventName: event.title,
                                                amount: 500, // Should be from event model
                                                studentId: authProvider.currentUser?.uid ?? '',
                                                onPaymentSuccess: (tid) {
                                                  _checkRegistration(); // Refresh status
                                                },
                                              ),
                                            ),
                                          ).then((_) => _checkRegistration());
                                      },
                                    );
                                  }
                                );
                              },
                            ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.1, end: 0),

                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    required bool isDark,
  }) {
    return GlassmorphismCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.grey[900],
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'approved':
        return AppTheme.successColor;
      case 'rejected':
        return AppTheme.errorColor;
      case 'completed':
        return AppTheme.accentColor;
      default:
        return AppTheme.warningColor;
    }
  }
}
