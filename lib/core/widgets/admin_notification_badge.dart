import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:uems/app/theme.dart';
import 'package:uems/app/routes.dart';

/// Notification badge widget showing pending proposals count
class AdminNotificationBadge extends StatelessWidget {
  final bool isDark;

  const AdminNotificationBadge({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('proposals')
          .where('status', isEqualTo: 'pending')
          .snapshots(),
      builder: (context, snapshot) {
        final count = snapshot.data?.docs.length ?? 0;
        return Badge(
          label: Text('$count'),
          isLabelVisible: count > 0,
          backgroundColor: AppTheme.errorColor,
          child: IconButton(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.requestedEvents),
            icon: Icon(
              Icons.notifications_rounded,
              color: isDark ? Colors.white : Colors.grey[800],
            ),
          ),
        );
      },
    );
  }
}
