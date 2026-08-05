import 'dart:math' as math;

import '../../core/utils/app_date.dart';
import '../database/app_database.dart';

class WeightPoint {
  const WeightPoint(this.date, this.kg);
  final DateTime date;
  final double kg;
}

class CaloriePoint {
  const CaloriePoint(this.date, this.kcal);
  final DateTime date;
  final double kcal;
}

class BodyFatPoint {
  const BodyFatPoint(this.date, this.percent);
  final DateTime date;
  final double percent;
}

/// All derived numbers the dashboard shows, computed from raw rows so the logic
/// stays pure and unit-testable.
class DashboardStats {
  const DashboardStats({
    required this.plan,
    required this.currentWeight,
    required this.weightLostKg,
    required this.remainingKg,
    required this.progress,
    required this.totalDays,
    required this.daysElapsed,
    required this.daysRemaining,
    required this.streak,
    required this.totalCalories,
    required this.todayCalories,
    required this.todayTasksDone,
    required this.todayTasksTotal,
    required this.checkedInToday,
    required this.latestBodyFat,
    required this.totalTaskDone,
    required this.totalTaskExpected,
    required this.weightSeries,
    required this.bodyFatSeries,
    required this.last7Calories,
  });

  final Plan plan;
  final double currentWeight;
  final double weightLostKg;
  final double remainingKg;
  final double progress; // 0..1
  final int totalDays;
  final int daysElapsed;
  final int daysRemaining;
  final int streak;
  final double totalCalories;
  final double todayCalories;
  final int todayTasksDone;
  final int todayTasksTotal;
  final bool checkedInToday;

  /// Most recent recorded body-fat percentage, if any.
  final double? latestBodyFat;
  final int totalTaskDone;
  final int totalTaskExpected;
  final List<WeightPoint> weightSeries;
  final List<BodyFatPoint> bodyFatSeries;
  final List<CaloriePoint> last7Calories;

  bool get goalReached => currentWeight <= plan.targetWeight;

  double get todayTaskRatio =>
      todayTasksTotal == 0 ? 0 : todayTasksDone / todayTasksTotal;

  /// Plan-wide task check-in completion (0..1): completed check-ins over the
  /// number expected so far (tasks per day x elapsed days).
  double get taskCompletionRate =>
      totalTaskExpected == 0
          ? 0
          : (totalTaskDone / totalTaskExpected).clamp(0.0, 1.0).toDouble();

  static DashboardStats compute({
    required Plan plan,
    required List<PlanTask> tasks,
    required List<DailyRecord> records,
    required List<TaskLog> logs,
    DateTime? now,
  }) {
    final today = (now ?? DateTime.now()).dateOnly;

    // Latest recorded weight (records are chronological).
    final weighted =
        records.where((r) => r.weight != null).toList()
          ..sort((a, b) => a.date.compareTo(b.date));
    final currentWeight =
        weighted.isNotEmpty ? weighted.last.weight! : plan.startWeight;

    final weightLost = plan.startWeight - currentWeight;
    final remaining = currentWeight - plan.targetWeight;

    final span = plan.startWeight - plan.targetWeight;
    final progress =
        span.abs() < 0.0001
            ? 1.0
            : (weightLost / span).clamp(0.0, 1.0).toDouble();

    final totalDays = math.max(
      1,
      AppDate.daysBetween(plan.startDate, plan.endDate) + 1,
    );
    final daysElapsed =
        (AppDate.daysBetween(plan.startDate, today) + 1)
            .clamp(0, totalDays)
            .toInt();
    final daysRemaining = math.max(0, AppDate.daysBetween(today, plan.endDate));

    final totalCalories = records.fold<double>(
      0,
      (sum, r) => sum + r.caloriesBurned,
    );

    final todayRecord = records.where((r) => r.date.isSameDate(today));
    final todayCalories =
        todayRecord.isEmpty ? 0.0 : todayRecord.first.caloriesBurned;

    final todayLogs =
        logs.where((l) => l.date.isSameDate(today) && l.completed).length;
    final todayTasksTotal = tasks.length;

    // Plan-wide task completion so far: completed check-ins vs expected
    // (tasks per day x elapsed days).
    final totalTaskDone = logs.where((l) => l.completed).length;
    final totalTaskExpected = todayTasksTotal * daysElapsed;

    final checkedInToday = records.any((r) => r.date.isSameDate(today));

    // Latest recorded body-fat percentage (records are chronological).
    final fatRecords =
        records.where((r) => r.bodyFat != null).toList()
          ..sort((a, b) => a.date.compareTo(b.date));
    final latestBodyFat = fatRecords.isEmpty ? null : fatRecords.last.bodyFat;

    // Streak: consecutive check-in days ending today (or yesterday for grace).
    final checkInDays = <DateTime>{
      for (final r in records) r.date.dateOnly,
      for (final l in logs)
        if (l.completed) l.date.dateOnly,
    };
    var cursor = today;
    if (!checkInDays.contains(cursor)) {
      cursor = cursor.subtract(const Duration(days: 1));
    }
    var streak = 0;
    while (checkInDays.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }

    // Weight series anchored on the plan start weight.
    final series = <WeightPoint>[
      WeightPoint(plan.startDate, plan.startWeight),
      for (final r in weighted)
        if (!r.date.isSameDate(plan.startDate)) WeightPoint(r.date, r.weight!),
    ];

    // Body-fat series from records that recorded it (no start anchor).
    final fatSeries = <BodyFatPoint>[
      for (final r in fatRecords) BodyFatPoint(r.date, r.bodyFat!),
    ];

    // Last 7 days of calories (oldest -> newest).
    final byDate = {for (final r in records) r.date.dateOnly: r.caloriesBurned};
    final last7 = <CaloriePoint>[
      for (var i = 6; i >= 0; i--)
        () {
          final d = today.subtract(Duration(days: i));
          return CaloriePoint(d, byDate[d] ?? 0);
        }(),
    ];

    return DashboardStats(
      plan: plan,
      currentWeight: currentWeight,
      weightLostKg: weightLost,
      remainingKg: remaining,
      progress: progress,
      totalDays: totalDays,
      daysElapsed: daysElapsed,
      daysRemaining: daysRemaining,
      streak: streak,
      totalCalories: totalCalories,
      todayCalories: todayCalories,
      todayTasksDone: todayLogs,
      todayTasksTotal: todayTasksTotal,
      checkedInToday: checkedInToday,
      latestBodyFat: latestBodyFat,
      totalTaskDone: totalTaskDone,
      totalTaskExpected: totalTaskExpected,
      weightSeries: series,
      bodyFatSeries: fatSeries,
      last7Calories: last7,
    );
  }
}
