import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uems/app/theme.dart';
import 'package:uems/core/widgets/glassmorphism_card.dart';

/// Widget showing countdown to next upcoming event
class EventCountdownWidget extends StatefulWidget {
  final DateTime nextEventDate;
  final String eventName;
  final bool isDark;

  const EventCountdownWidget({
    super.key,
    required this.nextEventDate,
    required this.eventName,
    required this.isDark,
  });

  @override
  State<EventCountdownWidget> createState() => _EventCountdownWidgetState();
}

class _EventCountdownWidgetState extends State<EventCountdownWidget> {
  Timer? _timer;
  String _countdown = '';

  @override
  void initState() {
    super.initState();
    _updateCountdown();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateCountdown();
    });
  }

  void _updateCountdown() {
    if (!mounted) return;
    
    final now = DateTime.now();
    final difference = widget.nextEventDate.difference(now);

    if (difference.isNegative) {
      setState(() => _countdown = 'Event has started!');
      _timer?.cancel();
    } else {
      final days = difference.inDays;
      final hours = difference.inHours % 24;
      final mins = difference.inMinutes % 60;
      final secs = difference.inSeconds % 60;
      
      setState(() => _countdown = '$days days, $hours hrs, $mins mins, $secs secs');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GlassmorphismCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.alarm_rounded, color: AppTheme.primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Next Event Countdown',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: widget.isDark ? Colors.white : Colors.grey[900],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.eventName,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: widget.isDark ? Colors.white : Colors.grey[900],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.timer_outlined, color: AppTheme.primaryColor, size: 18),
                const SizedBox(width: 8),
                Text(
                  _countdown,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
