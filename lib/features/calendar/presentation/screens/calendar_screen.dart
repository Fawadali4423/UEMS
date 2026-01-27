import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:uems/app/routes.dart';
import 'package:uems/app/theme.dart';
import 'package:uems/core/widgets/glassmorphism_card.dart';
import 'package:uems/features/events/domain/models/event_model.dart';
import 'package:uems/features/events/presentation/providers/event_provider.dart';

/// Calendar screen showing yearly event schedule
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<EventModel> _selectedEvents = [];

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadEventsForMonth(_focusedDay);
    });
  }

  Future<void> _loadEventsForMonth(DateTime month) async {
    final start = DateTime(month.year, month.month - 1, 1);
    final end = DateTime(month.year, month.month + 2, 0);
    
    await Provider.of<EventProvider>(context, listen: false)
        .loadEventsForCalendar(start, end);
    
    _updateSelectedDayEvents();
  }

  void _updateSelectedDayEvents() {
    if (_selectedDay == null) return;
    
    final eventProvider = Provider.of<EventProvider>(context, listen: false);
    setState(() {
      _selectedEvents = eventProvider.getEventsForDate(_selectedDay!);
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
                      'Event Calendar',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.grey[900],
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _focusedDay = DateTime.now();
                          _selectedDay = DateTime.now();
                        });
                        _loadEventsForMonth(DateTime.now());
                      },
                      icon: Icon(
                        Icons.today_rounded,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn().slideY(begin: -0.1, end: 0),

              // Calendar
              Consumer<EventProvider>(
                builder: (context, eventProvider, _) {
                  return GlassmorphismCard(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(12),
                    child: TableCalendar<EventModel>(
                      firstDay: DateTime.utc(2020, 1, 1),
                      lastDay: DateTime.utc(2030, 12, 31),
                      focusedDay: _focusedDay,
                      calendarFormat: _calendarFormat,
                      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                      eventLoader: (day) => eventProvider.getEventsForDate(day),
                      startingDayOfWeek: StartingDayOfWeek.monday,
                      calendarStyle: CalendarStyle(
                        outsideDaysVisible: false,
                        weekendTextStyle: TextStyle(
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                        defaultTextStyle: TextStyle(
                          color: isDark ? Colors.white : Colors.grey[900],
                        ),
                        todayDecoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                        ),
                        todayTextStyle: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.grey[900],
                        ),
                        selectedDecoration: const BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          shape: BoxShape.circle,
                        ),
                        selectedTextStyle: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        markerDecoration: BoxDecoration(
                          color: AppTheme.accentColor,
                          shape: BoxShape.circle,
                        ),
                        markersMaxCount: 3,
                        markerSize: 6,
                        markersAnchor: 0.7,
                      ),
                      headerStyle: HeaderStyle(
                        formatButtonVisible: true,
                        titleCentered: true,
                        formatButtonDecoration: BoxDecoration(
                          border: Border.all(color: AppTheme.primaryColor),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        formatButtonTextStyle: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontSize: 12,
                        ),
                        titleTextStyle: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.grey[900],
                        ),
                        leftChevronIcon: Icon(
                          Icons.chevron_left_rounded,
                          color: isDark ? Colors.white : Colors.grey[800],
                        ),
                        rightChevronIcon: Icon(
                          Icons.chevron_right_rounded,
                          color: isDark ? Colors.white : Colors.grey[800],
                        ),
                      ),
                      daysOfWeekStyle: DaysOfWeekStyle(
                        weekdayStyle: TextStyle(
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                          fontWeight: FontWeight.w600,
                        ),
                        weekendStyle: TextStyle(
                          color: isDark ? Colors.grey[500] : Colors.grey[500],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onDaySelected: (selectedDay, focusedDay) {
                        setState(() {
                          _selectedDay = selectedDay;
                          _focusedDay = focusedDay;
                        });
                        _updateSelectedDayEvents();
                      },
                      onFormatChanged: (format) {
                        setState(() {
                          _calendarFormat = format;
                        });
                      },
                      onPageChanged: (focusedDay) {
                        _focusedDay = focusedDay;
                        _loadEventsForMonth(focusedDay);
                      },
                    ),
                  );
                },
              ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.05, end: 0),

              const SizedBox(height: 16),

              // Selected Day Events
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedDay != null
                            ? 'Events on ${_selectedDay!.day}/${_selectedDay!.month}/${_selectedDay!.year}'
                            : 'Select a date',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.grey[900],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: _selectedEvents.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.event_busy_rounded,
                                      size: 48,
                                      color: isDark
                                          ? Colors.grey[600]
                                          : Colors.grey[400],
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'No events on this day',
                                      style: TextStyle(
                                        color: isDark
                                            ? Colors.grey[400]
                                            : Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                itemCount: _selectedEvents.length,
                                itemBuilder: (context, index) {
                                  final event = _selectedEvents[index];
                                  return _buildEventCard(event, isDark, index);
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEventCard(EventModel event, bool isDark, int index) {
    return GlassmorphismCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      onTap: () => Navigator.pushNamed(
        context,
        AppRoutes.eventDetail,
        arguments: event.id,
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 50,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(2),
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
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.grey[900],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 14,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${event.startTime} - ${event.endTime}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(width: 12),
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
              ],
            ),
          ),
          const Icon(
            Icons.arrow_forward_ios_rounded,
            size: 16,
            color: AppTheme.primaryColor,
          ),
        ],
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: 50 * index)).slideX(begin: 0.05, end: 0);
  }
}
