import 'package:intl/intl.dart';

/// Date and time formatting utilities
class DateTimeUtils {
  /// Format date as "Dec 29, 2025"
  static String formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }
  
  /// Format date as "December 29, 2025"
  static String formatDateFull(DateTime date) {
    return DateFormat('MMMM dd, yyyy').format(date);
  }
  
  /// Format date as "29/12/2025"
  static String formatDateShort(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }
  
  /// Format time as "2:30 PM"
  static String formatTime(DateTime time) {
    return DateFormat('h:mm a').format(time);
  }
  
  /// Format time as "14:30"
  static String formatTime24(DateTime time) {
    return DateFormat('HH:mm').format(time);
  }
  
  /// Format date and time as "Dec 29, 2025 at 2:30 PM"
  static String formatDateTime(DateTime dateTime) {
    return DateFormat('MMM dd, yyyy \'at\' h:mm a').format(dateTime);
  }
  
  /// Format as relative time (e.g., "2 hours ago", "in 3 days")
  static String formatRelative(DateTime dateTime) {
    final now = DateTime.now();
    final difference = dateTime.difference(now);
    
    if (difference.isNegative) {
      // Past
      final absDiff = difference.abs();
      if (absDiff.inMinutes < 1) {
        return 'Just now';
      } else if (absDiff.inMinutes < 60) {
        return '${absDiff.inMinutes} min ago';
      } else if (absDiff.inHours < 24) {
        return '${absDiff.inHours} hours ago';
      } else if (absDiff.inDays < 7) {
        return '${absDiff.inDays} days ago';
      } else {
        return formatDate(dateTime);
      }
    } else {
      // Future
      if (difference.inMinutes < 60) {
        return 'In ${difference.inMinutes} min';
      } else if (difference.inHours < 24) {
        return 'In ${difference.inHours} hours';
      } else if (difference.inDays < 7) {
        return 'In ${difference.inDays} days';
      } else {
        return formatDate(dateTime);
      }
    }
  }
  
  /// Check if date is today
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && 
           date.month == now.month && 
           date.day == now.day;
  }
  
  /// Check if date is in the past
  static bool isPast(DateTime date) {
    return date.isBefore(DateTime.now());
  }
  
  /// Check if date is in the future
  static bool isFuture(DateTime date) {
    return date.isAfter(DateTime.now());
  }
  
  /// Get start of day
  static DateTime startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
  
  /// Get end of day
  static DateTime endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59);
  }
  
  /// Parse time string (HH:mm) to DateTime
  static DateTime parseTimeString(String timeString, DateTime date) {
    final parts = timeString.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    return DateTime(date.year, date.month, date.day, hour, minute);
  }
  
  /// Format time string for display
  static String timeStringToDisplay(String timeString) {
    final parts = timeString.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    final date = DateTime(2025, 1, 1, hour, minute);
    return formatTime(date);
  }

  /// Get month abbreviation
  static String getMonthAbbr(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }
  /// Format check-in time
  static String formatCheckInTime(DateTime date) {
    return formatTime(date);
  }
}
