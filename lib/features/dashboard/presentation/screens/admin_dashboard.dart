import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:uems/app/routes.dart';
import 'package:uems/app/theme.dart';
import 'package:uems/core/widgets/glassmorphism_card.dart';
import 'package:uems/features/admin/presentation/screens/payment_approval_screen.dart';
import 'package:uems/features/auth/presentation/providers/auth_provider.dart';
import 'package:uems/features/events/presentation/providers/event_provider.dart';
import 'package:uems/features/notifications/data/notification_service.dart';
import 'package:uems/core/widgets/dashboard/dashboard_header.dart';
import 'package:uems/core/widgets/dashboard/dashboard_section.dart';
import 'package:uems/core/widgets/dashboard/stats_carousel.dart';

/// Admin dashboard with system management features
class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<EventProvider>(context, listen: false).loadPendingEvents();
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
              _buildHomeTab(isDark, user?.name ?? 'Admin'),
              _buildApprovalTab(isDark),
              _buildUsersTab(isDark),
              _buildSettingsTab(isDark),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(isDark),
    );
  }

  Widget _buildHomeTab(bool isDark, String userName) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DashboardHeader(
            userName: userName,
            isDark: isDark,
          ),

          // Quick Stats
          _buildQuickStats(isDark),

          const SizedBox(height: 24),

          // Quick Actions
          DashboardSection(
            title: 'Quick Actions',
            isDark: isDark,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildActionCard(
                        icon: Icons.add_circle_rounded,
                        label: 'Create Event',
                        color: AppTheme.accentColor,
                        onTap: () => Navigator.pushNamed(context, AppRoutes.createEvent),
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildActionCard(
                        icon: Icons.event_available_rounded,
                        label: 'Approve Events',
                        color: AppTheme.successColor,
                        onTap: () => Navigator.pushNamed(context, AppRoutes.eventApproval),
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildActionCard(
                        icon: Icons.calendar_month_rounded,
                        label: 'Calendar',
                        color: AppTheme.primaryColor,
                        onTap: () => Navigator.pushNamed(context, AppRoutes.calendar),
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildActionCard(
                        icon: Icons.people_rounded,
                        label: 'Users',
                        color: AppTheme.secondaryColor,
                        onTap: () => setState(() => _currentIndex = 2),
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
              ],
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0),
          ),

          // Management Section
                DashboardSection(
                  title: 'Management',
                  isDark: isDark,
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _buildCompactActionCard(
                        icon: Icons.event_note_rounded,
                        label: 'All Events',
                        color: AppTheme.accentColor,
                        onTap: () => Navigator.pushNamed(context, AppRoutes.adminEventsList),
                        isDark: isDark,
                      ),
                       _buildCompactActionCard(
                        icon: Icons.insights_rounded,
                        label: 'Reports',
                        color: Colors.teal,
                        onTap: () => Navigator.pushNamed(context, AppRoutes.studentAttendance),
                        isDark: isDark,
                      ),
                      _buildCompactActionCard(
                        icon: Icons.campaign_rounded,
                        label: 'Broadcast',
                        color: AppTheme.warningColor,
                        onTap: () => _showBroadcastDialog(),
                        isDark: isDark,
                      ),
                      _buildCompactActionCard(
                        icon: Icons.qr_code_scanner_rounded,
                        label: 'Scan QR',
                        color: AppTheme.primaryColor,
                        onTap: () => Navigator.pushNamed(context, AppRoutes.adminQrScanner),
                        isDark: isDark,
                      ),
                      _buildCompactActionCard(
                        icon: Icons.verified_user_rounded,
                        label: 'Wallet',
                        color: const Color(0xFFE32536),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const PaymentApprovalScreen()),
                        ),
                        isDark: isDark,
                      ),
                      _buildCompactActionCard(
                        icon: Icons.admin_panel_settings_rounded,
                        label: 'Organizers',
                        color: Colors.deepPurple,
                        onTap: () => Navigator.pushNamed(context, AppRoutes.manageOrganizers),
                        isDark: isDark,
                      ),
                      _buildCompactActionCard(
                        icon: Icons.upload_file_rounded,
                        label: 'Certificates',
                        color: Colors.deepOrange,
                        onTap: () => Navigator.pushNamed(context, AppRoutes.uploadCertificates),
                        isDark: isDark,
                      ),
                      _buildCompactActionCard(
                        icon: Icons.how_to_vote_rounded,
                        label: 'Requests',
                        color: Colors.teal,
                        onTap: () => Navigator.pushNamed(context, AppRoutes.requestedEvents),
                        isDark: isDark,
                      ),
                      _buildCompactActionCard(
                        icon: Icons.check_circle_rounded,
                        label: 'History',
                        color: AppTheme.successColor,
                        onTap: () => Navigator.pushNamed(context, AppRoutes.approvedEvents),
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),

          // Pending Approvals
          DashboardSection(
            title: 'Pending Approvals',
            isDark: isDark,
            child: Consumer<EventProvider>(
                builder: (context, eventProvider, _) {
                  if (eventProvider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  final pendingEvents = eventProvider.pendingEvents;
                  if (pendingEvents.isEmpty) {
                    return GlassmorphismCard(
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.check_circle_rounded,
                              size: 48,
                              color: AppTheme.successColor,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'All caught up!',
                              style: TextStyle(
                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: pendingEvents.length > 3 ? 3 : pendingEvents.length,
                    itemBuilder: (context, index) {
                      final event = pendingEvents[index];
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

  Widget _buildQuickStats(bool isDark) {
    return SizedBox(
      height: 140, // Height constraint for the carousel
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('events').where('status', isEqualTo: 'approved').snapshots(),
        builder: (context, eventSnapshot) {
          final eventCount = eventSnapshot.data?.docs.length ?? 0;
          
          return Consumer<EventProvider>(
            builder: (context, eventProvider, _) {
              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'student').snapshots(),
                builder: (context, userSnapshot) {
                  final studentCount = userSnapshot.data?.docs.length ?? 0;
                  
                  return StatsCarousel(
                    isDark: isDark,
                    items: [
                      StatItem(
                        label: 'Total Events',
                        value: '$eventCount',
                        icon: Icons.event_rounded,
                        color: AppTheme.primaryColor,
                      ),
                      StatItem(
                        label: 'Pending',
                        value: '${eventProvider.pendingEvents.length}',
                        icon: Icons.pending_actions_rounded,
                        color: AppTheme.warningColor,
                      ),
                      StatItem(
                        label: 'Students',
                        value: '$studentCount',
                        icon: Icons.people_rounded,
                        color: AppTheme.successColor,
                      ),
                    ],
                  );
                }
              );
            },
          );
        }
      ),
    );
  }

  Widget _buildCompactActionCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: MediaQuery.of(context).size.width / 2 - 28, // Responsive width for 2-column grid
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2D2D44) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.grey[900],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GlassmorphismCard(
      padding: const EdgeInsets.all(16),
      onTap: onTap,
      child: Row(
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
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.grey[900],
              ),
            ),
          ),
          Icon(
            Icons.arrow_forward_ios_rounded,
            size: 16,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(dynamic event, bool isDark) {
    return GlassmorphismCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      onTap: () => Navigator.pushNamed(
        context,
        AppRoutes.eventDetail,
        arguments: event.id,
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.event_rounded,
              color: Colors.white,
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
                  event.venue,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppTheme.warningColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Pending',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.warningColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApprovalTab(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Event Approvals',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.grey[900],
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Consumer<EventProvider>(
              builder: (context, eventProvider, _) {
                if (eventProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                final pendingEvents = eventProvider.pendingEvents;
                if (pendingEvents.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.event_available_rounded,
                          size: 80,
                          color: AppTheme.successColor.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No pending events',
                          style: TextStyle(
                            fontSize: 18,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }
                
                return ListView.builder(
                  itemCount: pendingEvents.length,
                  itemBuilder: (context, index) {
                    final event = pendingEvents[index];
                    return _buildApprovalCard(event, isDark, eventProvider);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApprovalCard(dynamic event, bool isDark, EventProvider provider) {
    return GlassmorphismCard(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            event.title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.grey[900],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            event.description,
            style: TextStyle(
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 16,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
              const SizedBox(width: 4),
              Text(
                event.venue,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              const SizedBox(width: 16),
              Icon(
                Icons.calendar_today_outlined,
                size: 16,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
              const SizedBox(width: 4),
              Text(
                '${event.date.day}/${event.date.month}/${event.date.year}',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => provider.rejectEvent(event.id),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.errorColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.close_rounded),
                  label: const Text('Reject'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => provider.approveEvent(event.id),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.successColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Approve'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUsersTab(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Student Management',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.grey[900],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'View all registered students',
            style: TextStyle(
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 20),
          
          // Students list from Firestore
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('role', isEqualTo: 'student')
                  .snapshots(),
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
                          Icons.error_outline_rounded,
                          size: 60,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Unable to load students',
                          style: TextStyle(
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final students = snapshot.data?.docs ?? [];

                if (students.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline_rounded,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No students registered yet',
                          style: TextStyle(
                            fontSize: 16,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: students.length,
                  itemBuilder: (context, index) {
                    final data = students[index].data() as Map<String, dynamic>;
                    return _buildStudentCard(data, isDark, index);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentCard(Map<String, dynamic> student, bool isDark, int index) {
    final name = student['name'] ?? 'Unknown';
    final email = student['email'] ?? '';
    final department = student['department'] ?? 'Not specified';
    
    return GlassmorphismCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : 'S',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: isDark ? Colors.white : Colors.grey[900],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  department,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[500] : Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppTheme.successColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Student',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppTheme.successColor,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: (index * 50).ms).slideX(begin: 0.1, end: 0);
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
                _buildSettingItem(
                  icon: Icons.person_outline,
                  title: 'Profile',
                  onTap: () => Navigator.pushNamed(context, AppRoutes.profile),
                  isDark: isDark,
                ),
                const Divider(),
                _buildSettingItem(
                  icon: Icons.notifications_outlined,
                  title: 'Notifications',
                  onTap: () => Navigator.pushNamed(context, AppRoutes.notifications),
                  isDark: isDark,
                ),
                const Divider(),
                _buildSettingItem(
                  icon: Icons.logout_rounded,
                  title: 'Logout',
                  onTap: () async {
                    await authProvider.signOut();
                    if (mounted) {
                      Navigator.pushReplacementNamed(context, AppRoutes.login);
                    }
                  },
                  isDark: isDark,
                  isDestructive: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required bool isDark,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive 
          ? AppTheme.errorColor 
          : (isDark ? Colors.grey[400] : Colors.grey[700]),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive 
            ? AppTheme.errorColor 
            : (isDark ? Colors.white : Colors.grey[900]),
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios_rounded,
        size: 16,
        color: isDark ? Colors.grey[600] : Colors.grey[400],
      ),
      onTap: onTap,
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
            icon: Icon(Icons.event_available_rounded),
            label: 'Approvals',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_rounded),
            label: 'Users',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  void _showBroadcastDialog() {
    final titleController = TextEditingController();
    final messageController = TextEditingController();
    final notificationService = NotificationService();
    bool isSending = false;
    
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(Icons.campaign_rounded, color: AppTheme.primaryColor),
              const SizedBox(width: 10),
              const Text('Broadcast to Students'),
            ],
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  maxLines: 1,
                  decoration: InputDecoration(
                    labelText: 'Title',
                    hintText: 'Important Announcement',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: messageController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Message',
                    hintText: 'Your message...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSending ? null : () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isSending ? null : () async {
                if (titleController.text.isEmpty || messageController.text.isEmpty) {
                  return;
                }
                
                setDialogState(() => isSending = true);
                
                final success = await notificationService.sendBroadcastNotification(
                  title: titleController.text.trim(),
                  message: messageController.text.trim(),
                );
                
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success 
                        ? 'Broadcast sent to all students!' 
                        : 'Failed to send broadcast'),
                      backgroundColor: success 
                        ? AppTheme.successColor 
                        : AppTheme.errorColor,
                    ),
                  );
                }
              },
              child: isSending 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Send to All'),
            ),
          ],
        ),
      ),
    );
  }
}
