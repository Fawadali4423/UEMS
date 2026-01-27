import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:uems/app/routes.dart';
import 'package:uems/app/theme.dart';

class DashboardHeader extends StatelessWidget {
  final String userName;
  final String? subtitle;
  final bool isDark;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onProfileTap;

  const DashboardHeader({
    super.key,
    required this.userName,
    this.subtitle,
    required this.isDark,
    this.onNotificationTap,
    this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subtitle ?? 'Welcome back,',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  userName,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.grey[900],
                    letterSpacing: -0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Row(
            children: [
              _buildIconButton(
                context,
                icon: Icons.notifications_none_rounded,
                onTap: onNotificationTap ?? 
                    () => Navigator.pushNamed(context, AppRoutes.notifications),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: onProfileTap ?? 
                    () => Navigator.pushNamed(context, AppRoutes.profile),
                child: Container(
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.person_outline_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
        ],
      ).animate().fadeIn().slideY(begin: -0.2, end: 0, curve: Curves.easeOutBack),
    );
  }

  Widget _buildIconButton(BuildContext context, {
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 45,
          height: 45,
          decoration: BoxDecoration(
            color: isDark 
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark 
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.grey.withValues(alpha: 0.2),
            ),
          ),
          child: Icon(
            icon,
            color: isDark ? Colors.white : Colors.grey[800],
            size: 24,
          ),
        ),
      ),
    );
  }
}
