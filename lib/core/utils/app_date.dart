import 'package:intl/intl.dart';

/// Date helpers used throughout the app. All persisted dates are normalised to
/// midnight (date-only) so a "day" compares cleanly regardless of time.
extension DateOnlyX on DateTime {
  DateTime get dateOnly => DateTime(year, month, day);

  bool isSameDate(DateTime other) =>
      year == other.year && month == other.month && day == other.day;

  bool get isToday => isSameDate(DateTime.now());
}

class AppDate {
  AppDate._();

  static DateTime today() => DateTime.now().dateOnly;

  /// Calendar-day difference, immune to DST (local midnight gaps of 23/25h).
  ///
  /// Positive when [to] is after [from].
  static int daysBetween(DateTime from, DateTime to) {
    final a = from.dateOnly;
    final b = to.dateOnly;
    return DateTime.utc(b.year, b.month, b.day)
            .difference(DateTime.utc(a.year, a.month, a.day))
            .inDays;
  }

  /// Calendar-day arithmetic on a date-only value (DST-safe).
  static DateTime addDays(DateTime date, int days) {
    final d = date.dateOnly;
    final utc = DateTime.utc(d.year, d.month, d.day).add(Duration(days: days));
    return DateTime(utc.year, utc.month, utc.day);
  }

  static String monthDay(DateTime d) => DateFormat('MM/dd').format(d);

  static String pretty(DateTime d) => DateFormat('yyyy年M月d日').format(d);

  static String shortWeekday(DateTime d) {
    const names = ['一', '二', '三', '四', '五', '六', '日'];
    return names[(d.weekday - 1) % 7];
  }

  static String relativeLabel(DateTime d) {
    final diff = daysBetween(d, today());
    if (diff == 0) return '今天';
    if (diff == 1) return '昨天';
    if (diff == -1) return '明天';
    return monthDay(d);
  }
}
