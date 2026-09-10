import 'package:flutter_test/flutter_test.dart';
import 'package:slimming_checkin/data/database/app_database.dart';
import 'package:slimming_checkin/data/models/dashboard_stats.dart';

void main() {
  final today = DateTime(2026, 7, 21);

  Plan makePlan() => Plan(
    id: 1,
    name: 'Test',
    startDate: DateTime(2026, 7, 11),
    endDate: DateTime(2026, 7, 31),
    startWeight: 80,
    targetWeight: 70,
    isActive: true,
    createdAt: today,
  );

  test('computes weight, progress, streak and today figures', () {
    final plan = makePlan();
    final tasks = [
      const PlanTask(id: 1, planId: 1, title: 'A', sortOrder: 0),
      const PlanTask(id: 2, planId: 1, title: 'B', sortOrder: 1),
    ];
    final records = [
      DailyRecord(
        id: 1,
        planId: 1,
        date: DateTime(2026, 7, 19),
        weight: 78,
        bodyFat: 24.5,
        caloriesBurned: 300,
      ),
      DailyRecord(
        id: 2,
        planId: 1,
        date: DateTime(2026, 7, 20),
        weight: 77,
        caloriesBurned: 400,
      ),
      DailyRecord(
        id: 3,
        planId: 1,
        date: today,
        weight: 76,
        bodyFat: 23.8,
        caloriesBurned: 500,
      ),
    ];
    final logs = [
      TaskLog(id: 1, planId: 1, taskId: 1, date: today, completed: true),
      TaskLog(id: 2, planId: 1, taskId: 2, date: today, completed: false),
    ];

    final s = DashboardStats.compute(
      plan: plan,
      tasks: tasks,
      records: records,
      logs: logs,
      now: today,
    );

    expect(s.currentWeight, 76);
    expect(s.weightLostKg, closeTo(4, 1e-9));
    expect(s.remainingKg, closeTo(6, 1e-9));
    expect(s.progress, closeTo(0.4, 1e-9));
    expect(s.totalCalories, 1200);
    expect(s.todayCalories, 500);
    expect(s.todayTasksDone, 1);
    expect(s.todayTasksTotal, 2);
    expect(s.todayTaskRatio, closeTo(0.5, 1e-9));
    expect(s.checkedInToday, isTrue);
    expect(s.streak, 3);
    expect(s.totalDays, 21);
    expect(s.daysRemaining, 10);
    expect(s.last7Calories.length, 7);
    // Body-fat series only includes records that recorded it, in date order.
    expect(s.bodyFatSeries.length, 2);
    expect(s.bodyFatSeries.first.date, DateTime(2026, 7, 19));
    expect(s.bodyFatSeries.first.percent, 24.5);
    expect(s.bodyFatSeries.last.percent, 23.8);
  });

  test('no records falls back to start weight with zero progress', () {
    final s = DashboardStats.compute(
      plan: makePlan(),
      tasks: const [],
      records: const [],
      logs: const [],
      now: today,
    );
    expect(s.currentWeight, 80);
    expect(s.progress, 0);
    expect(s.streak, 0);
    expect(s.checkedInToday, isFalse);
    expect(s.bodyFatSeries, isEmpty);
  });

  test('progress is clamped to 1 once the goal is reached', () {
    final records = [
      DailyRecord(id: 1, planId: 1, date: today, weight: 68, caloriesBurned: 0),
    ];
    final s = DashboardStats.compute(
      plan: makePlan(),
      tasks: const [],
      records: records,
      logs: const [],
      now: today,
    );
    expect(s.goalReached, isTrue);
    expect(s.progress, 1.0);
  });

  test('goalReached is direction-aware for weight-gain plans', () {
    Plan gainPlan() => Plan(
      id: 1,
      name: 'Gain',
      startDate: DateTime(2026, 7, 11),
      endDate: DateTime(2026, 7, 31),
      startWeight: 60,
      targetWeight: 70,
      isActive: true,
      createdAt: today,
    );

    final mid = DashboardStats.compute(
      plan: gainPlan(),
      tasks: const [],
      records: [
        DailyRecord(id: 1, planId: 1, date: today, weight: 65, caloriesBurned: 0),
      ],
      logs: const [],
      now: today,
    );
    expect(mid.isLosingWeight, isFalse);
    expect(mid.goalReached, isFalse);
    expect(mid.progress, closeTo(0.5, 1e-9));

    final done = DashboardStats.compute(
      plan: gainPlan(),
      tasks: const [],
      records: [
        DailyRecord(id: 1, planId: 1, date: today, weight: 70, caloriesBurned: 0),
      ],
      logs: const [],
      now: today,
    );
    expect(done.goalReached, isTrue);
    expect(done.progress, 1.0);
  });

  test('computeStreak applies one-day grace and counts task-only days', () {
    final todayD = DateTime(2026, 7, 21);
    // Today open, yesterday + day-before are check-ins.
    expect(
      DashboardStats.computeStreak([
        DateTime(2026, 7, 20),
        DateTime(2026, 7, 19),
      ], todayD),
      2,
    );
    // Today counts too.
    expect(
      DashboardStats.computeStreak([
        DateTime(2026, 7, 21),
        DateTime(2026, 7, 20),
        DateTime(2026, 7, 19),
      ], todayD),
      3,
    );
    // Gap breaks the streak.
    expect(
      DashboardStats.computeStreak([
        DateTime(2026, 7, 20),
        DateTime(2026, 7, 18),
      ], todayD),
      1,
    );
    expect(DashboardStats.computeStreak(const [], todayD), 0);
  });
}
