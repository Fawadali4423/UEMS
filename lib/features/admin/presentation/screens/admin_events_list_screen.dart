import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:uems/app/routes.dart';
import 'package:uems/app/theme.dart';
import 'package:uems/core/utils/date_utils.dart' as date_utils;
import 'package:uems/core/widgets/glassmorphism_card.dart';
import 'package:uems/features/events/domain/models/event_model.dart';
import 'package:uems/features/events/presentation/providers/event_provider.dart';

/// Admin screen showing all events with registration info
class AdminEventsListScreen extends StatefulWidget {
  final bool isOrganizerView;
  
  const AdminEventsListScreen({super.key, this.isOrganizerView = false});

  @override
  State<AdminEventsListScreen> createState() => _AdminEventsListScreenState();
}

class _AdminEventsListScreenState extends State<AdminEventsListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<EventProvider>(context, listen: false).loadAllEvents();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
                    Expanded(
                      child: Text(
                        'All Events',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.grey[900],
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        Provider.of<EventProvider>(context, listen: false)
                            .loadAllEvents();
                      },
                      icon: Icon(
                        Icons.refresh_rounded,
                        color: isDark ? Colors.white : Colors.grey[800],
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn().slideY(begin: -0.1, end: 0),

              // Tab Bar
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2D2D44) : Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor:
                      isDark ? Colors.grey[400] : Colors.grey[600],
                  dividerHeight: 0,
                  tabs: const [
                    Tab(text: 'Upcoming'),
                    Tab(text: 'Past'),
                    Tab(text: 'All'),
                  ],
                ),
              ).animate().fadeIn(delay: 100.ms),

              const SizedBox(height: 16),

              // Events List
              Expanded(
                child: Consumer<EventProvider>(
                  builder: (context, eventProvider, _) {
                    if (eventProvider.isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    return TabBarView(
                      controller: _tabController,
                      children: [
                        _buildEventsList(
                          eventProvider.upcomingApprovedEvents,
                          isDark,
                          'No upcoming events',
                        ),
                        _buildEventsList(
                          eventProvider.pastEvents,
                          isDark,
                          'No past events',
                        ),
                        _buildEventsList(
                          eventProvider.allEvents,
                          isDark,
                          'No events found',
                        ),
                      ],
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

  Widget _buildEventsList(
      List<EventModel> events, bool isDark, String emptyMessage) {
    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy_rounded,
              size: 64,
              color: isDark ? Colors.grey[700] : Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.grey[500] : Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await Provider.of<EventProvider>(context, listen: false).loadAllEvents();
      },
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: events.length,
        itemBuilder: (context, index) {
          final event = events[index];
          return _buildEventCard(event, isDark, index);
        },
      ),
    );
  }

  Widget _buildEventCard(EventModel event, bool isDark, int index) {
    final isPast = event.isPast;
    
    return GlassmorphismCard(
      margin: const EdgeInsets.only(bottom: 12),
      onTap: () {
        Navigator.pushNamed(
          context,
          AppRoutes.eventRegistrations,
          arguments: event,
        );
      },
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Date Box
            Container(
              width: 55,
              height: 60,
              decoration: BoxDecoration(
                gradient: isPast
                    ? LinearGradient(
                        colors: [Colors.grey[600]!, Colors.grey[700]!],
                      )
                    : AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${event.date.day}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    date_utils.DateTimeUtils.getMonthAbbr(event.date.month),
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            // Event info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and Badges
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          event.title,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: isDark ? Colors.white : Colors.grey[900],
                          ),
                          maxLines: 2,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (isPast)
                            Container(
                              margin: const EdgeInsets.only(bottom: 4),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'EXPIRED',
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                            ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getStatusColor(event.status)
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              event.status.toUpperCase(),
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                color: _getStatusColor(event.status),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 14,
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
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      // Participants count
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.people_rounded,
                              size: 14,
                              color: AppTheme.primaryColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${event.participantCount ?? 0} registered',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Event type badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: event.isPaid
                              ? AppTheme.accentColor.withValues(alpha: 0.1)
                              : AppTheme.successColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          event.isPaid
                              ? 'PKR ${event.entryFee?.toStringAsFixed(0) ?? '0'}'
                              : 'Free',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: event.isPaid
                                ? AppTheme.accentColor
                                : AppTheme.successColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Edit Action (for approved/upcoming events)
            if (event.isApproved && !isPast)
              IconButton(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.createEvent,
                    arguments: {'event': event, 'isEdit': true},
                  );
                },
                icon: const Icon(Icons.edit_rounded, color: AppTheme.primaryColor),
              ),
            // Delete Action
            IconButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Event', style: TextStyle(color: AppTheme.errorColor)),
                    content: Text('Are you sure you want to delete "${event.title}"? This cannot be undone.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () async {
                          Navigator.pop(context); // Close dialog
                          final provider = Provider.of<EventProvider>(context, listen: false);
                          final success = await provider.deleteEvent(event.id);
                          if (success && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Event deleted successfully')),
                            );
                          }
                        },
                        child: const Text('Delete', style: TextStyle(color: AppTheme.errorColor)),
                      ),
                    ],
                  ),
                );
              },
              icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.errorColor),
            ),
            // Arrow
            Icon(
              Icons.chevron_right_rounded,
              color: isDark ? Colors.grey[600] : Colors.grey[400],
            ),
          ],
        ),
      ),
    ).animate(delay: Duration(milliseconds: 50 * index)).fadeIn().slideX(
          begin: 0.05,
          end: 0,
        );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
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
