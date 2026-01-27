import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:uems/app/theme.dart';
import 'package:uems/core/widgets/glassmorphism_card.dart';
import 'package:uems/features/auth/data/user_repository.dart';
import 'package:uems/features/auth/domain/models/user_model.dart';
import 'package:uems/features/attendance/data/attendance_repository.dart';
import 'package:uems/features/events/domain/models/event_model.dart';
import 'package:uems/features/events/presentation/providers/event_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Admin screen to view student attendance records
class StudentAttendanceScreen extends StatefulWidget {
  const StudentAttendanceScreen({super.key});

  @override
  State<StudentAttendanceScreen> createState() => _StudentAttendanceScreenState();
}

class _StudentAttendanceScreenState extends State<StudentAttendanceScreen> {
  final UserRepository _userRepository = UserRepository();
  final AttendanceRepository _attendanceRepository = AttendanceRepository();
  final TextEditingController _searchController = TextEditingController();
  
  UserModel? _selectedStudent;
  List<AttendanceItem> _allAttendanceItems = [];
  bool _isLoading = false;
  double _participationPercentage = 0.0;

  @override
  void dispose() {
    _searchController.dispose();
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
              _buildSearchBar(isDark),
              const SizedBox(height: 16),
              if (_selectedStudent != null) ...[
                _buildStudentInfo(isDark),
                const SizedBox(height: 16),
              ],
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _selectedStudent == null
                        ? _buildSearchPrompt(isDark)
                        : _buildAttendanceList(isDark),
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
                  'Attendance Reports',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.grey[900],
                  ),
                ),
                Text(
                  'Track student participation',
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

  Widget _buildSearchBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GlassmorphismCard(
        padding: EdgeInsets.zero,
        child: TextField(
          controller: _searchController,
          onSubmitted: _searchStudent,
          style: TextStyle(color: isDark ? Colors.white : Colors.grey[900]),
          decoration: InputDecoration(
            hintText: 'Search by roll number or name',
            prefixIcon: Icon(Icons.search_rounded, color: AppTheme.primaryColor),
            suffixIcon: IconButton(
              icon: Icon(Icons.clear_rounded, color: isDark ? Colors.grey[400] : Colors.grey[600]),
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _selectedStudent = null;
                  _allAttendanceItems.clear();
                });
              },
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.all(16),
            hintStyle: TextStyle(color: isDark ? Colors.grey[600] : Colors.grey[400]),
          ),
        ),
      ),
    );
  }

  Widget _buildStudentInfo(bool isDark) {
    final student = _selectedStudent!;
    final totalEvents = _allAttendanceItems.length; // Total past events
    final attendedEvents = _allAttendanceItems.where((i) => i.isPresent).length;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GlassmorphismCard(
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Center(
                    child: Text(
                      student.name.isNotEmpty ? student.name.substring(0, 1).toUpperCase() : 'S',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student.name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.grey[900],
                        ),
                      ),
                      Text(
                        student.rollNumber ?? student.email,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                      if (student.department != null)
                        Text(
                          student.department!,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),
                // Participation Percentage Circle
                Column(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 50,
                          height: 50,
                          child: CircularProgressIndicator(
                            value: totalEvents > 0 ? attendedEvents / totalEvents : 0,
                            backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                            color: _getPercentageColor(_participationPercentage),
                            strokeWidth: 6,
                          ),
                        ),
                        Text(
                          '${_participationPercentage.toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.grey[900],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Participation',
                      style: TextStyle(
                        fontSize: 10,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient.scale(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem('Attended', attendedEvents.toString(), Icons.check_circle_rounded, AppTheme.successColor, isDark),
                  _buildStatItem('Missed', (totalEvents - attendedEvents).toString(), Icons.cancel_rounded, AppTheme.errorColor, isDark),
                  _buildStatItem('Total Events', totalEvents.toString(), Icons.event_rounded, AppTheme.primaryColor, isDark),
                ],
              ),
            ),
          ],
        ),
      ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1, end: 0),
    );
  }

  Color _getPercentageColor(double percentage) {
    if (percentage >= 75) return AppTheme.successColor;
    if (percentage >= 50) return AppTheme.warningColor;
    return AppTheme.errorColor;
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color, bool isDark) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.grey[900],
          ),
        ),
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

  Widget _buildSearchPrompt(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_search_rounded,
            size: 80,
            color: isDark ? Colors.grey[700] : Colors.grey[300],
          ).animate(onPlay: (controller) => controller.repeat(reverse: true))
              .scale(duration: 2.seconds, begin: const Offset(0.9, 0.9)),
          const SizedBox(height: 24),
          Text(
            'Search for a Student',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.grey[900],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter roll number or name to view attendance report',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceList(bool isDark) {
    if (_allAttendanceItems.isEmpty) {
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
              'No Past Events',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.grey[900],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'There are no past approved events to track.',
              style: TextStyle(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _allAttendanceItems.length,
      itemBuilder: (context, index) {
        final item = _allAttendanceItems[index];
        return _buildAttendanceCard(item, isDark, index);
      },
    );
  }

  Widget _buildAttendanceCard(AttendanceItem item, bool isDark, int index) {
    return GlassmorphismCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: item.isPresent 
                  ? AppTheme.successGradient 
                  : LinearGradient(colors: [AppTheme.errorColor.withOpacity(0.7), AppTheme.errorColor]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              item.isPresent ? Icons.check_circle_rounded : Icons.cancel_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.event.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.grey[900],
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 12,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${item.event.date.day}/${item.event.date.month}/${item.event.date.year}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: item.isPresent
                  ? AppTheme.successColor.withOpacity(0.2)
                  : AppTheme.errorColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              item.isPresent ? 'PRESENT' : 'ABSENT',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: item.isPresent ? AppTheme.successColor : AppTheme.errorColor,
              ),
            ),
          ),
        ],
      ),
    ).animate(delay: Duration(milliseconds: 50 * index))
        .fadeIn()
        .slideX(begin: 0.05, end: 0);
  }

  Future<void> _searchStudent(String query) async {
    if (query.trim().isEmpty) return;

    setState(() => _isLoading = true);

    try {
      // Search by roll number first
      var student = await _userRepository.getUserByRollNumber(query.trim());
      
      if (student == null) {
        // Try searching by name
        final users = await _userRepository.searchUsers(query.trim());
        if (users.isNotEmpty) {
          student = users.first;
        }
      }

      if (student != null) {
        if (mounted) {
           setState(() => _selectedStudent = student);
           await _loadAttendance(student.uid);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Student not found'),
              backgroundColor: AppTheme.errorColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
           setState(() {
            _selectedStudent = null;
            _allAttendanceItems.clear();
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }

    setState(() => _isLoading = false);
  }

  Future<void> _loadAttendance(String studentId) async {
    try {
      // 1. Get all past approved events
      // We use Provider to get the instance, but we need to ensure it's loaded.
      final eventProvider = Provider.of<EventProvider>(context, listen: false);
      await eventProvider.loadAllEvents(); // Ensure we have latest data
      
      final pastApprovedEvents = eventProvider.allEvents
          .where((e) => e.isApproved && e.isPast)
          .toList()
          ..sort((a, b) => b.date.compareTo(a.date)); // Recent first

      // 2. Get student's attendance records
      // We get the list of event IDs the student attended
      final attendedEventIds = await _attendanceRepository.getStudentAttendedEvents(studentId);

      // 3. Merge and Create Attendance Items
      final items = <AttendanceItem>[];
      int attendedCount = 0;

      for (final event in pastApprovedEvents) {
        final isPresent = attendedEventIds.contains(event.id);
        if (isPresent) attendedCount++;
        
        items.add(AttendanceItem(
          event: event,
          isPresent: isPresent,
        ));
      }

      // 4. Update State
      if (mounted) {
        setState(() {
          _allAttendanceItems = items;
          _participationPercentage = pastApprovedEvents.isEmpty 
              ? 0.0 
              : (attendedCount / pastApprovedEvents.length) * 100;
        });
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading attendance report: $e')),
        );
      }
    }
  }
}

class AttendanceItem {
  final EventModel event;
  final bool isPresent;

  AttendanceItem({required this.event, required this.isPresent});
}
