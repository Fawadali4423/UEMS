import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:uems/app/theme.dart';
import 'package:uems/core/widgets/glassmorphism_card.dart';
import 'package:uems/core/widgets/offline_indicator.dart';
import 'package:uems/features/events/presentation/providers/event_provider.dart';
import 'package:uems/features/registration/presentation/providers/registration_provider.dart';
import 'package:uems/core/services/local_storage_service.dart';

/// Screen displaying QR pass for event
class QrPassScreen extends StatefulWidget {
  final String eventId;
  final String studentId;

  const QrPassScreen({
    super.key,
    required this.eventId,
    required this.studentId,
  });

  @override
  State<QrPassScreen> createState() => _QrPassScreenState();
}

class _QrPassScreenState extends State<QrPassScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<RegistrationProvider>(context, listen: false)
          .loadPass(widget.eventId, widget.studentId);
      Provider.of<EventProvider>(context, listen: false)
          .loadEvent(widget.eventId);
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
                      'Event Pass',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.grey[900],
                      ),
                    ),
                    const Spacer(),
                    Consumer<RegistrationProvider>(
                      builder: (context, regProvider, _) {
                        if (regProvider.isLoadedFromCache) {
                          final lastSync = LocalStorageService().getLastSync();
                          return OfflineIndicator(
                            isCached: true,
                            lastSync: lastSync,
                            showLastSync: true,
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ],
                ),
              ).animate().fadeIn().slideY(begin: -0.1, end: 0),

              // Content
              Expanded(
                child: Consumer2<RegistrationProvider, EventProvider>(
                  builder: (context, regProvider, eventProvider, _) {
                    if (regProvider.isLoading || eventProvider.isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final pass = regProvider.currentPass;
                    final event = eventProvider.selectedEvent;

                    if (pass == null) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline_rounded,
                              size: 64,
                              color: AppTheme.errorColor,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Pass not found',
                              style: TextStyle(
                                fontSize: 18,
                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          // QR Code Card
                          GlassmorphismCard(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              children: [
                                // Event Title
                                Text(
                                  event?.title ?? 'Event',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : Colors.grey[900],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 24),

                                // QR Code
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppTheme.primaryColor.withValues(alpha: 0.2),
                                        blurRadius: 20,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: QrImageView(
                                    data: pass.qrData,
                                    version: QrVersions.auto,
                                    size: 200,
                                    eyeStyle: const QrEyeStyle(
                                      eyeShape: QrEyeShape.square,
                                      color: AppTheme.primaryColor,
                                    ),
                                    dataModuleStyle: const QrDataModuleStyle(
                                      dataModuleShape: QrDataModuleShape.square,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ).animate().scale(
                                  begin: const Offset(0.8, 0.8),
                                  end: const Offset(1, 1),
                                  delay: 200.ms,
                                  duration: 400.ms,
                                  curve: Curves.elasticOut,
                                ),

                                const SizedBox(height: 24),

                                // Status
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: pass.isUsed
                                        ? AppTheme.successColor.withValues(alpha: 0.2)
                                        : AppTheme.warningColor.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        pass.isUsed
                                            ? Icons.check_circle_rounded
                                            : Icons.pending_rounded,
                                        size: 18,
                                        color: pass.isUsed
                                            ? AppTheme.successColor
                                            : AppTheme.warningColor,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        pass.isUsed ? 'Checked In' : 'Not Checked In',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: pass.isUsed
                                              ? AppTheme.successColor
                                              : AppTheme.warningColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1, end: 0),

                          const SizedBox(height: 20),

                          // Event Details Card
                          if (event != null)
                            GlassmorphismCard(
                              child: Column(
                                children: [
                                  _buildInfoRow(
                                    icon: Icons.calendar_today_rounded,
                                    label: 'Date',
                                    value: '${event.date.day}/${event.date.month}/${event.date.year}',
                                    isDark: isDark,
                                  ),
                                  const Divider(),
                                  _buildInfoRow(
                                    icon: Icons.access_time_rounded,
                                    label: 'Time',
                                    value: '${event.startTime} - ${event.endTime}',
                                    isDark: isDark,
                                  ),
                                  const Divider(),
                                  _buildInfoRow(
                                    icon: Icons.location_on_rounded,
                                    label: 'Venue',
                                    value: event.venue,
                                    isDark: isDark,
                                  ),
                                ],
                              ),
                            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0),

                          const SizedBox(height: 24),

                          // Instructions
                          GlassmorphismCard(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: AppTheme.accentColor.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.info_outline_rounded,
                                    color: AppTheme.accentColor,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text(
                                    'Show this QR code at the event entrance for check-in',
                                    style: TextStyle(
                                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1, end: 0),
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

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: AppTheme.primaryColor,
          ),
          const SizedBox(width: 12),
          Column(
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
        ],
      ),
    );
  }
}
