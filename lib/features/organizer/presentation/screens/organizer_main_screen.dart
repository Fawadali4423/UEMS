import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:uems/app/routes.dart';
import 'package:uems/app/theme.dart';
import 'package:uems/core/widgets/glassmorphism_card.dart';
import 'package:uems/features/auth/presentation/providers/auth_provider.dart';
import 'package:uems/features/auth/domain/models/user_model.dart';

/// Dynamic permission-based organizer dashboard
class OrganizerMainScreen extends StatefulWidget {
  const OrganizerMainScreen({super.key});

  @override
  State<OrganizerMainScreen> createState() => _OrganizerMainScreenState();
}

class _OrganizerMainScreenState extends State<OrganizerMainScreen> {
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
          child: StreamBuilder<UserModel?>(
            stream: _watchUser(context),
            builder: (context, snapshot) {
              final user = snapshot.data ?? Provider.of<AuthProvider>(context).currentUser;

              if (user == null) {
                return const Center(child: CircularProgressIndicator());
              }

              // Check if still organizer
              if (!user.isOrganizer) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  Navigator.pushReplacementNamed(context, AppRoutes.studentDashboard);
                });
                return const Center(child: CircularProgressIndicator());
              }

              // Single permission: go directly to that feature
              if (user.hasSinglePermission) {
                return _buildSinglePermissionView(user, isDark);
              }

              // Multiple permissions: show dashboard
              return _buildDashboard(user, isDark);
            },
          ),
        ),
      ),
    );
  }

  Stream<UserModel?> _watchUser(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    return authProvider.userStream;
  }

  Widget _buildSinglePermissionView(UserModel user, bool isDark) {
    final permission = user.singlePermission!;
    
    // Navigate directly to the feature screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navigateToPermissionScreen(permission);
    });

    return Column(
      children: [
        _buildHeader(user, isDark),
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    _getPermissionIcon(permission),
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Loading ${_getPermissionTitle(permission)}...',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.grey[900],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDashboard(UserModel user, bool isDark) {
    return Column(
      children: [
        _buildHeader(user, isDark),
        const SizedBox(height: 20),
        
        // Permission count badge
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.shield_outlined,
                  size: 16,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  '${user.permissionCount} Permission${user.permissionCount > 1 ? 's' : ''} Active',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ).animate().fadeIn().scale(),
        
        const SizedBox(height: 20),
        
        // Feature cards grid
        Expanded(
          child: _buildFeatureGrid(user, isDark),
        ),
      ],
    );
  }

  Widget _buildHeader(UserModel user, bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Organizer Dashboard',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.grey[900],
                  ),
                ),
                Text(
                  'Hello, ${user.name}',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.profile),
            icon: Icon(
              Icons.person_rounded,
              color: isDark ? Colors.white : Colors.grey[800],
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.1, end: 0);
  }

  Widget _buildFeatureGrid(UserModel user, bool isDark) {
    final features = _getAvailableFeatures(user);

    if (features.isEmpty) {
      return _buildEmptyState(isDark);
    }

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.1,
      ),
      itemCount: features.length,
      itemBuilder: (context, index) {
        return _buildFeatureCard(
          features[index],
          isDark,
          index,
        ).animate(delay: Duration(milliseconds: 100 * index))
         .fadeIn()
         .scale();
      },
    );
  }

  List<PermissionFeature> _getAvailableFeatures(UserModel user) {
    final features = <PermissionFeature>[];

    if (user.canCreateEvents) {
      features.add(PermissionFeature(
        permission: 'create_event',
        title: 'Create Event',
        subtitle: 'Organize new events',
        icon: Icons.add_circle_rounded,
        color: AppTheme.primaryColor,
        route: AppRoutes.createEvent,
      ));
    }

    if (user.canScanQR) {
      features.add(PermissionFeature(
        permission: 'scan_qr',
        title: 'Scan QR',
        subtitle: 'Mark attendance',
        icon: Icons.qr_code_scanner_rounded,
        color: Colors.green,
        route: AppRoutes.adminQrScanner,
      ));
    }

    if (user.canManageFinance) {
      features.add(PermissionFeature(
        permission: 'manage_finance',
        title: 'Finance',
        subtitle: 'Manage payments',
        icon: Icons.account_balance_wallet_rounded,
        color: Colors.orange,
        route: '/payment-approval',
      ));
    }

    if (user.canApproveEvents) {
      features.add(PermissionFeature(
        permission: 'approve_event',
        title: 'Approve Events',
        subtitle: 'Review submissions',
        icon: Icons.check_circle_rounded,
        color: Colors.blue,
        route: AppRoutes.eventApproval,
      ));
    }

    if (user.canManageCertificates) {
      features.add(PermissionFeature(
        permission: 'manage_certificates',
        title: 'Certificates',
        subtitle: 'Upload certificates',
        icon: Icons.card_membership_rounded,
        color: Colors.purple,
        route: AppRoutes.uploadCertificates,
      ));
    }

    return features;
  }

  Widget _buildFeatureCard(PermissionFeature feature, bool isDark, int index) {
    return GlassmorphismCard(
      onTap: () => Navigator.pushNamed(context, feature.route),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: feature.color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              feature.icon,
              color: feature.color,
              size: 28,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            feature.title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.grey[900],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            feature.subtitle,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
            textAlign: TextAlign.center,
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
            Icons.lock_outline_rounded,
            size: 80,
            color: isDark ? Colors.grey[700] : Colors.grey[300],
          ),
          const SizedBox(height: 24),
          Text(
            'No Permissions Assigned',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.grey[900],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Contact an administrator to assign\norganizer permissions',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _navigateToPermissionScreen(String permission) {
    String route;
    switch (permission) {
      case 'create_event':
        route = AppRoutes.createEvent;
        break;
      case 'scan_qr':
        route = AppRoutes.adminQrScanner;
        break;
      case 'manage_finance':
        route = '/payment-approval';
        break;
      case 'approve_event':
        route = AppRoutes.eventApproval;
        break;
      case 'manage_certificates':
        route = AppRoutes.uploadCertificates;
        break;
      default:
        return;
    }
    
    Navigator.pushReplacementNamed(context, route);
  }

  IconData _getPermissionIcon(String permission) {
    switch (permission) {
      case 'create_event':
        return Icons.add_circle_rounded;
      case 'scan_qr':
        return Icons.qr_code_scanner_rounded;
      case 'manage_finance':  
        return Icons.account_balance_wallet_rounded;
      case 'approve_event':
        return Icons.check_circle_rounded;
      case 'manage_certificates':
        return Icons.card_membership_rounded;
      default:
        return Icons.shield_rounded;
    }
  }

  String _getPermissionTitle(String permission) {
    switch (permission) {
      case 'create_event':
        return 'Create Event';
      case 'scan_qr':
        return 'QR Scanner';
      case 'manage_finance':
        return 'Finance Management';
      case 'approve_event':
        return 'Event Approval';
      case 'manage_certificates':
        return 'Certificate Management';
      default:
        return 'Feature';
    }
  }
}

/// Permission feature model
class PermissionFeature {
  final String permission;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String route;

  PermissionFeature({
    required this.permission,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.route,
  });
}
