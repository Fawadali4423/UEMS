import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:uems/app/theme.dart';

/// Widget to display offline status and cached data indicator
class OfflineIndicator extends StatelessWidget {
  final bool isOffline;
  final bool isCached;
  final DateTime? lastSync;
  final bool showLastSync;

  const OfflineIndicator({
    super.key,
    this.isOffline = false,
    this.isCached = false,
    this.lastSync,
    this.showLastSync = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!isOffline && !isCached) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getBackgroundColor(isDark),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _getBorderColor(isDark),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getIcon(),
            size: 14,
            color: _getIconColor(),
          ),
          const SizedBox(width: 6),
          Text(
            _getText(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _getTextColor(isDark),
            ),
          ),
          if (showLastSync && lastSync != null) ...[
            const SizedBox(width: 4),
            Text(
              '• ${_formatLastSync(lastSync!)}',
              style: TextStyle(
                fontSize: 11,
                color: (isDark ? Colors.grey[400] : Colors.grey[600])!
                    .withValues(alpha: 0.8),
              ),
            ),
          ],
        ],
      ),
    ).animate().fadeIn().slideX(begin: -0.1, end: 0);
  }

  IconData _getIcon() {
    if (isOffline) return Icons.cloud_off_rounded;
    if (isCached) return Icons.offline_bolt_rounded;
    return Icons.info_outline_rounded;
  }

  Color _getIconColor() {
    if (isOffline) return AppTheme.errorColor;
    if (isCached) return AppTheme.warningColor;
    return AppTheme.primaryColor;
  }

  String _getText() {
    if (isOffline) return 'Offline';
    if (isCached) return 'Cached Data';
    return 'Info';
  }

  Color _getBackgroundColor(bool isDark) {
    if (isOffline) {
      return AppTheme.errorColor.withValues(alpha: isDark ? 0.15 : 0.1);
    }
    if (isCached) {
      return AppTheme.warningColor.withValues(alpha: isDark ? 0.15 : 0.1);
    }
    return AppTheme.primaryColor.withValues(alpha: isDark ? 0.15 : 0.1);
  }

  Color _getBorderColor(bool isDark) {
    if (isOffline) {
      return AppTheme.errorColor.withValues(alpha: isDark ? 0.3 : 0.2);
    }
    if (isCached) {
      return AppTheme.warningColor.withValues(alpha: isDark ? 0.3 : 0.2);
    }
    return AppTheme.primaryColor.withValues(alpha: isDark ? 0.3 : 0.2);
  }

  Color _getTextColor(bool isDark) {
    if (isOffline) return AppTheme.errorColor;
    if (isCached) return AppTheme.warningColor;
    return AppTheme.primaryColor;
  }

  String _formatLastSync(DateTime lastSync) {
    final now = DateTime.now();
    final difference = now.difference(lastSync);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inHours < 1) return '${difference.inMinutes}m ago';
    if (difference.inDays < 1) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    return '${(difference.inDays / 7).floor()}w ago';
  }
}
