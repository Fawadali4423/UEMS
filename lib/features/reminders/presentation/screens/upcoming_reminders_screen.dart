import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:uems/app/theme.dart';
import 'package:uems/core/widgets/glassmorphism_card.dart';
import 'package:uems/features/events/presentation/providers/event_provider.dart';
import 'package:uems/features/events/domain/models/event_model.dart';

/// Screen showing upcoming event with countdown timer
class UpcomingRemindersScreen extends StatefulWidget {
  const UpcomingRemindersScreen({super.key});

  @override
  State<UpcomingRemindersScreen> createState() => _UpcomingRemindersScreenState();
}

class _UpcomingRemindersScreenState extends State<UpcomingRemindersScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<EventProvider>(context, listen: false).loadApprovedEvents();
    });
    
    // Update countdown every second
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
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
              _buildHeader(isDark),
              Expanded(
                child: Consumer<EventProvider>(
                  builder: (context, provider, _) {
                    if (provider.isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final upcomingEvents = provider.upcomingEvents;

                    if (upcomingEvents.isEmpty) {
                      return _buildEmptyState(isDark);
                    }

                    // Get next upcoming event
                    final nextEvent = upcomingEvents.first;

                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          _buildNextEventCard(nextEvent, isDark),
                          const SizedBox(height: 24),
                          _buildCountdown(nextEvent, isDark),
                          const SizedBox(height: 32),
                          if (upcomingEvents.length > 1) ...[
                            _buildUpcomingList(upcomingEvents.skip(1).toList(), isDark),
                          ],
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

  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(20),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Event Reminders',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.grey[900],
                  ),
                ),
                Text(
                  'Countdown to your next event',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.1, end: 0);
  }

  Widget _buildNextEventCard(EventModel event, bool isDark) {
    return GlassmorphismCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star_rounded, color: Colors.white, size: 16),
                    SizedBox(width: 4),
                    Text(
                      'NEXT EVENT',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            event.title,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.grey[900],
            ),
          ),
          const SizedBox(height: 12),
          _buildEventDetail(Icons.calendar_today_rounded, 
              _formatDate(event.date), isDark),
          const SizedBox(height: 8),
          _buildEventDetail(Icons.location_on_rounded, 
              event.venue, isDark),
          if (event.isPaid) ...[
            const SizedBox(height: 8),
            _buildEventDetail(Icons.payments_rounded, 
                'PKR ${event.entryFee?.toStringAsFixed(0)}', isDark),
          ],
        ],
      ),
    ).animate().fadeIn(delay: 100.ms).scale();
  }

  Widget _buildEventDetail(IconData icon, String text, bool isDark) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.primaryColor),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey[300] : Colors.grey[700],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCountdown(EventModel event, bool isDark) {
    final now = DateTime.now();
    final difference = event.date.difference(now);

    if (difference.isNegative) {
      return GlassmorphismCard(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            'Event has started!',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.grey[900],
            ),
          ),
        ),
      );
    }

    final days = difference.inDays;
    final hours = difference.inHours % 24;
    final minutes = difference.inMinutes % 60;
    final seconds = difference.inSeconds % 60;

    return GlassmorphismCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            'Starts In',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildTimeUnit(days.toString(), 'Days', isDark),
              _buildTimeSeparator(isDark),
              _buildTimeUnit(hours.toString().padLeft(2, '0'), 'Hours', isDark),
              _buildTimeSeparator(isDark),
              _buildTimeUnit(minutes.toString().padLeft(2, '0'), 'Mins', isDark),
              _buildTimeSeparator(isDark),
              _buildTimeUnit(seconds.toString().padLeft(2, '0'), 'Secs', isDark),
            ],
          ),
        ],
      ),
    ).animate(onPlay: (controller) => controller.repeat())
        .shimmer(duration: 2.seconds, color: AppTheme.primaryColor.withOpacity(0.3));
  }

  Widget _buildTimeUnit(String value, String label, bool isDark) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Center(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildTimeSeparator(bool isDark) {
    return Text(
      ':',
      style: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: isDark ? Colors.white : Colors.grey[900],
      ),
    );
  }

  Widget _buildUpcomingList(List<EventModel> events, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Upcoming Events',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.grey[900],
          ),
        ),
        const SizedBox(height: 12),
        ...events.take(5).map((event) => _buildUpcomingItem(event, isDark)),
      ],
    );
  }

  Widget _buildUpcomingItem(EventModel event, bool isDark) {
    return GlassmorphismCard(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                '${event.date.day}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.grey[900],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _formatDate(event.date),
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
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_available_rounded,
            size: 80,
            color: isDark ? Colors.grey[700] : Colors.grey[300],
          ),
          const SizedBox(height: 24),
          Text(
            'No Upcoming Events',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.grey[900],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Check back later for new events',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
