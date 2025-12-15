// utils/date_calculations.dart
import 'package:intl/intl.dart';

class BookingPolicy {
  // Check if booking can be edited/deleted (must be at least 3 days before event)
  static bool canEditOrDelete(DateTime eventDate) {
    final now = DateTime.now();

    // Create event start date (midnight of event day)
    final eventStart = DateTime(eventDate.year, eventDate.month, eventDate.day);

    // Create today's date (midnight of today)
    final today = DateTime(now.year, now.month, now.day);

    // Calculate difference in days
    final difference = eventStart.difference(today);

    // DEBUG: Print the calculation
    print(
        'DEBUG: Event: $eventStart, Today: $today, Difference: ${difference.inDays} days');

    // Check if event is more than 3 days away
    // We want: event date > today + 3 days
    return difference.inDays > 3;
  }

  // Calculate days remaining
  static int daysRemaining(DateTime eventDate) {
    final now = DateTime.now();

    // Create event start date (midnight of event day)
    final eventStart = DateTime(eventDate.year, eventDate.month, eventDate.day);

    // Create today's date (midnight of today)
    final today = DateTime(now.year, now.month, now.day);

    // Calculate difference in days
    final difference = eventStart.difference(today);

    return difference.inDays >= 0 ? difference.inDays : 0;
  }

  // Check if booking is upcoming (for display purposes)
  static bool isUpcoming(DateTime eventDate) {
    final now = DateTime.now();
    final eventStart = DateTime(eventDate.year, eventDate.month, eventDate.day);
    final today = DateTime(now.year, now.month, now.day);
    return eventStart.isAfter(today);
  }

  // Get human-readable time until event
  static String timeUntilEvent(DateTime eventDate) {
    final days = daysRemaining(eventDate);

    if (days > 30) {
      return '${(days / 30).floor()} months';
    } else if (days > 0) {
      return '$days days';
    } else {
      return 'Today';
    }
  }

  // Format date for display
  static String formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  // Format date with time
  static String formatDateTime(DateTime date) {
    return DateFormat('dd/MM/yyyy hh:mm a').format(date);
  }
}
