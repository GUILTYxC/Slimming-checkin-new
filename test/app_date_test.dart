import 'package:flutter_test/flutter_test.dart';
import 'package:slimming_checkin/core/utils/app_date.dart';

void main() {
  test('daysBetween counts calendar days, not 24h blocks', () {
    expect(AppDate.daysBetween(DateTime(2026, 7, 1), DateTime(2026, 7, 11)), 10);
    expect(AppDate.daysBetween(DateTime(2026, 7, 11), DateTime(2026, 7, 11)), 0);
    expect(AppDate.daysBetween(DateTime(2026, 7, 11), DateTime(2026, 7, 1)), -10);
    // Month/year boundary.
    expect(AppDate.daysBetween(DateTime(2026, 1, 30), DateTime(2026, 2, 2)), 3);
  });

  test('addDays is calendar-based', () {
    expect(
      AppDate.addDays(DateTime(2026, 7, 31), 1),
      DateTime(2026, 8, 1),
    );
    expect(
      AppDate.addDays(DateTime(2026, 3, 1), -1),
      DateTime(2026, 2, 28),
    );
    expect(
      AppDate.addDays(DateTime(2026, 7, 10, 15, 30), -1),
      DateTime(2026, 7, 9),
    );
  });
}
