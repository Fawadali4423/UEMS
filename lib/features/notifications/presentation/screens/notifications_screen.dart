import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:uems/app/routes.dart';
import 'package:uems/app/theme.dart';
import 'package:uems/core/widgets/glassmorphism_card.dart';
import 'package:uems/features/auth/presentation/providers/auth_provider.dart';
import 'package:uems/features/notifications/data/notification_service.dart';

/// Notifications screen showing all notifications
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService _notificationService = NotificationService();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authProvider = Provider.of<AuthProvider>(context);
    final userRole = authProvider.currentUser?.role ?? 'student';

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
                      'Notifications',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.grey[900],
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => _notificationService.markAllAsRead(userRole),
                      child: Text(
                        'Mark all read',
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn().slideY(begin: -0.1, end: 0),

              // Notifications List
              Expanded(
                child: StreamBuilder<List<NotificationModel>>(
                  stream: _notificationService.getNotifications(userRole),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.notifications_off_rounded,
                              size: 80,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Unable to load notifications',
                              style: TextStyle(
                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    final notifications = snapshot.data ?? [];

                    if (notifications.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.notifications_none_rounded,
                              size: 80,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No notifications yet',
                              style: TextStyle(
                                fontSize: 18,
                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'You\'ll be notified when new events are created',
                              style: TextStyle(
                                color: isDark ? Colors.grey[500] : Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: notifications.length,
                      itemBuilder: (context, index) {
                        final notification = notifications[index];
                        return _buildNotificationCard(notification, isDark, index);
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

  Widget _buildNotificationCard(NotificationModel notification, bool isDark, int index) {
    final isEvent = notification.type == 'event';
    
    return GlassmorphismCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      onTap: () {
        // Mark as read
        _notificationService.markAsRead(notification.id);
        
        // Navigate to event if it's an event notification
        if (isEvent && notification.eventId != null) {
          Navigator.pushNamed(
            context,
            AppRoutes.eventDetail,
            arguments: notification.eventId,
          );
        }
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: isEvent ? AppTheme.primaryGradient : null,
              color: isEvent ? null : AppTheme.accentColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              isEvent ? Icons.event_rounded : Icons.notifications_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        notification.title,
                        style: TextStyle(
                          fontWeight: notification.isRead 
                            ? FontWeight.w500 
                            : FontWeight.bold,
                          fontSize: 15,
                          color: isDark ? Colors.white : Colors.grey[900],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (!notification.isRead)
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  notification.body,
                  style: TextStyle(
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    fontSize: 13,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  _formatTime(notification.createdAt),
                  style: TextStyle(
                    color: isDark ? Colors.grey[500] : Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: (index * 50).ms).slideX(begin: 0.1, end: 0);
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}
