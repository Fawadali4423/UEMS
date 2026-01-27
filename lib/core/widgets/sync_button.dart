import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:uems/app/theme.dart';
import 'package:uems/core/providers/sync_provider.dart';

/// Button to trigger manual sync with pending count indicator
class SyncButton extends StatelessWidget {
  final VoidCallback? onSyncComplete;
  final bool showLabel;

  const SyncButton({
    super.key,
    this.onSyncComplete,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<SyncProvider>(
      builder: (context, syncProvider, _) {
        final pendingCount = syncProvider.pendingSyncCount;
        final isSyncing = syncProvider.isSyncing;
        final isOnline = syncProvider.isOnline;

        return InkWell(
          onTap: (isOnline && !isSyncing && pendingCount > 0)
              ? () async {
                  await syncProvider.manualSync();
                  onSyncComplete?.call();
                }
              : null,
          borderRadius: BorderRadius.circular(30),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: showLabel ? 16 : 12,
              vertical: showLabel ? 12 : 12,
            ),
            decoration: BoxDecoration(
              gradient: (isOnline && pendingCount > 0)
                  ? AppTheme.primaryGradient
                  : null,
              color: (!isOnline || pendingCount == 0)
                  ? Colors.grey.withValues(alpha: 0.3)
                  : null,
              borderRadius: BorderRadius.circular(30),
              boxShadow: (isOnline && pendingCount > 0 && !isSyncing)
                  ? [
                      BoxShadow(
                        color: AppTheme.primaryColor.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isSyncing)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                else
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(
                        Icons.sync_rounded,
                        color: (isOnline && pendingCount > 0)
                            ? Colors.white
                            : Colors.grey,
                        size: 20,
                      ),
                      if (pendingCount > 0)
                        Positioned(
                          right: -8,
                          top: -8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppTheme.errorColor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 1.5,
                              ),
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 18,
                              minHeight: 18,
                            ),
                            child: Center(
                              child: Text(
                                pendingCount > 99 ? '99+' : '$pendingCount',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  height: 1,
                                ),
                              ),
                            ),
                          ).animate(
                            onPlay: (controller) => controller.repeat(),
                          ).scale(
                            duration: 1000.ms,
                            begin: const Offset(1, 1),
                            end: const Offset(1.1, 1.1),
                          ),
                        ),
                    ],
                  ),
                if (showLabel) ...[
                  const SizedBox(width: 8),
                  Text(
                    isSyncing
                        ? 'Syncing...'
                        : pendingCount > 0
                            ? 'Sync ($pendingCount)'
                            : 'Synced',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: (isOnline && pendingCount > 0)
                          ? Colors.white
                          : Colors.grey,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
