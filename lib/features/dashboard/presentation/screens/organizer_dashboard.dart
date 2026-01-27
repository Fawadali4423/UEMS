import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:uems/app/routes.dart';
import 'package:uems/app/theme.dart';
import 'package:uems/core/widgets/glassmorphism_card.dart';
import 'package:uems/features/auth/presentation/providers/auth_provider.dart';
import 'package:uems/features/events/presentation/providers/event_provider.dart';
import 'package:uems/core/widgets/dashboard/dashboard_header.dart';
import 'package:uems/core/widgets/dashboard/dashboard_section.dart';

/// Organizer dashboard with event management features
class OrganizerDashboard extends StatefulWidget {
  const OrganizerDashboard({super.key});

  @override
  State<OrganizerDashboard> createState() => _OrganizerDashboardState();
}

class _OrganizerDashboardState extends State<OrganizerDashboard> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      Provider.of<EventProvider>(context, listen: false)
          .loadOrganizerEvents(authProvider.currentUser?.uid ?? '');
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
              _buildHomeTab(isDark, user?.name ?? 'Organizer'),
              _buildMyEventsTab(isDark),
              _buildScanTab(isDark),
              _buildSettingsTab(isDark),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(isDark),
      floatingActionButton: _currentIndex == 1
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.pushNamed(context, AppRoutes.createEvent),
              backgroundColor: AppTheme.primaryColor,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Create Event'),
            )
          : null,
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
            subtitle: 'Welcome back,',
            isDark: isDark,
          ),

          // Quick Actions
          DashboardSection(
            title: 'Quick Actions',
            isDark: isDark,
            child: GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.1, // Slightly taller for better text fit
              children: [
                _buildQuickActionCard(
                  icon: Icons.add_circle_rounded,
                  title: 'Create Event',
                  subtitle: 'Start a new event',
                  color: AppTheme.primaryColor,
                  onTap: () => Navigator.pushNamed(context, AppRoutes.createEvent),
                  isDark: isDark,
                ),
                _buildQuickActionCard(
                  icon: Icons.qr_code_scanner_rounded,
                  title: 'Scan QR',
                  subtitle: 'Mark attendance',
                  color: AppTheme.secondaryColor,
                  onTap: () => setState(() => _currentIndex = 2),
                  isDark: isDark,
                ),
                _buildQuickActionCard(
                  icon: Icons.calendar_month_rounded,
                  title: 'Calendar',
                  subtitle: 'View schedule',
                  color: AppTheme.accentColor,
                  onTap: () => Navigator.pushNamed(context, AppRoutes.calendar),
                  isDark: isDark,
                ),
                _buildQuickActionCard(
                  icon: Icons.card_membership_rounded,
                  title: 'Certificates',
                  subtitle: 'Issue certificates',
                  color: AppTheme.successColor,
                  onTap: () {},
                  isDark: isDark,
                ),
              ],
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0),
          ),

          // My Events
          DashboardSection(
            title: 'My Events',
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
  
                final events = eventProvider.organizerEvents;
                if (events.isEmpty) {
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
                            'No events yet',
                            style: TextStyle(
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () => Navigator.pushNamed(context, AppRoutes.createEvent),
                            child: const Text('Create your first event'),
                          ),
                        ],
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
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GlassmorphismCard(
      padding: const EdgeInsets.all(16),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
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
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.grey[900],
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(dynamic event, bool isDark) {
    Color statusColor;
    switch (event.status) {
      case 'approved':
        statusColor = AppTheme.successColor;
        break;
      case 'rejected':
        statusColor = AppTheme.errorColor;
        break;
      default:
        statusColor = AppTheme.warningColor;
    }

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
                  '${event.date.day}/${event.date.month}/${event.date.year}',
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
              color: statusColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              event.status.toString().toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyEventsTab(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'My Events',
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

                final events = eventProvider.organizerEvents;
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
                          'No events yet',
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

  Widget _buildScanTab(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Scan QR Pass',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.grey[900],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Select an event to scan attendance:',
            style: TextStyle(
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Consumer<EventProvider>(
              builder: (context, eventProvider, _) {
                final events = eventProvider.organizerEvents
                    .where((e) => e.status == 'approved')
                    .toList();

                if (events.isEmpty) {
                  return Center(
                    child: Text(
                      'No approved events to scan',
                      style: TextStyle(
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: events.length,
                  itemBuilder: (context, index) {
                    final event = events[index];
                    return GlassmorphismCard(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      onTap: () => Navigator.pushNamed(
                        context,
                        AppRoutes.qrScanner,
                        arguments: event.id,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.qr_code_scanner_rounded,
                              color: AppTheme.primaryColor,
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
                                ),
                                Text(
                                  'Tap to scan',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.primaryColor,
                                  ),
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
                    );
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
            label: 'My Events',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.qr_code_scanner_rounded),
            label: 'Scan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
