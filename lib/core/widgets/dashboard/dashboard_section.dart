import 'package:flutter/material.dart';

class DashboardSection extends StatelessWidget {
  final String title;
  final Widget? action;
  final Widget child;
  final bool isDark;
  final EdgeInsetsGeometry padding;

  const DashboardSection({
    super.key,
    required this.title,
    this.action,
    required this.child,
    required this.isDark,
    this.padding = const EdgeInsets.only(bottom: 24),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.grey[900],
                  letterSpacing: -0.5,
                ),
              ),
              if (action != null) action!,
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
