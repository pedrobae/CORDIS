import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timezone/timezone.dart' as tz;

/// Utility class for handling timezone-aware datetime operations
/// Converts between regular DateTime, TZDateTime, and Firestore Timestamps
class TimezoneUtils {
  TimezoneUtils._();

  /// Get the timezone location by IANA name
  /// Returns UTC if timezone name is invalid
  static tz.Location getLocation(String timezoneName) {
    try {
      return tz.getLocation(timezoneName);
    } catch (e) {
      // Fallback to UTC if timezone is invalid
      return tz.UTC;
    }
  }

  /// Convert a UTC DateTime to a TZDateTime in the specified timezone
  static tz.TZDateTime toTZDateTime(DateTime dateTime, String timezoneName) {
    final location = getLocation(timezoneName);
    return tz.TZDateTime.from(dateTime, location);
  }

  /// Convert a TZDateTime to a UTC DateTime for storage
  static DateTime toUtcDateTime(tz.TZDateTime tzDateTime) {
    return tzDateTime.toUtc();
  }

  /// Convert Firestore Timestamp to TZDateTime
  static tz.TZDateTime timestampToTZDateTime(
    Timestamp timestamp,
    String timezoneName,
  ) {
    final utcDateTime = timestamp.toDate();
    return toTZDateTime(utcDateTime, timezoneName);
  }

  /// Convert TZDateTime to Firestore Timestamp
  static Timestamp tzDateTimeToTimestamp(tz.TZDateTime tzDateTime) {
    return Timestamp.fromDate(tzDateTime.toUtc());
  }

  /// Convert DateTime to Firestore Timestamp
  static Timestamp dateTimeToTimestamp(DateTime dateTime) {
    return Timestamp.fromDate(dateTime);
  }

  /// Format a timestamp with timezone awareness
  /// Returns a string like "Jan 15, 2024 at 3:45 PM EST"
  static String formatTimestampWithTimezone(
    Timestamp timestamp,
    String timezoneName, {
    bool includeTime = true,
    bool includeDayName = false,
  }) {
    final tzDateTime = timestampToTZDateTime(timestamp, timezoneName);

    if (!includeTime) {
      return '${tzDateTime.day.toString().padLeft(2, '0')}/${tzDateTime.month.toString().padLeft(2, '0')}/${tzDateTime.year}';
    }

    final hour = tzDateTime.hour.toString().padLeft(2, '0');
    final minute = tzDateTime.minute.toString().padLeft(2, '0');

    if (includeDayName) {
      final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      final dayName = days[tzDateTime.weekday - 1];
      return '$dayName ${tzDateTime.day}/${tzDateTime.month}/${tzDateTime.year} - $hour:$minute';
    }

    return '${tzDateTime.day}/${tzDateTime.month}/${tzDateTime.year} - $hour:$minute';
  }

  /// Get current time in a specific timezone
  static tz.TZDateTime now(String timezoneName) {
    return tz.TZDateTime.now(getLocation(timezoneName));
  }

  /// Check if a timezone string is valid
  static bool isValidTimezone(String timezoneName) {
    try {
      tz.getLocation(timezoneName);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get all available timezones
  /// This should be called after initializeTimeZones() in main.dart
  static List<String> getAllTimezones() {
    try {
      return tz.timeZoneDatabase.locations.keys.toList()..sort();
    } catch (e) {
      // Fallback if timezone database is not initialized
      return ['UTC'];
    }
  }
}
