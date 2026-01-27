import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:uems/core/widgets/glassmorphism_card.dart';

class StatsCarousel extends StatelessWidget {
  final List<StatItem> items;
  final bool isDark;

  const StatsCarousel({
    super.key,
    required this.items,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    // For larger screens, maybe show grid, but for mobile, scrollable row is good
    return LayoutBuilder(
      builder: (context, constraints) {
        // If width is very small, use a vertically scrolling list or strict scrolling row
        // Using a horizontal list view for standard interaction
        return SizedBox(
          height: 130, // Fixed height for stats
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final item = items[index];
              return _buildStatCard(item, index);
            },
          ),
        );
      },
    );
  }

  Widget _buildStatCard(StatItem item, int index) {
    return Container(
      width: 140, // Fixed width for comfortable look
      margin: const EdgeInsets.symmetric(vertical: 4), // margin for shadow
      child: GlassmorphismCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: item.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                item.icon,
                color: item.color,
                size: 20,
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                 Text(
                  item.value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.grey[900],
                  ),
                ),
                Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: (100 * index).ms).slideX();
  }
}

class StatItem {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
}
