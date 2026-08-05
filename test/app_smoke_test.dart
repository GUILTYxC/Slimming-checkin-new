import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slimming_checkin/app.dart';
import 'package:slimming_checkin/core/providers.dart';
import 'package:slimming_checkin/data/database/app_database.dart';
import 'package:slimming_checkin/data/repositories/app_repository.dart';

void main() {
  testWidgets('shows the empty dashboard when there is no plan yet', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final db = AppDatabase.forTesting(NativeDatabase.memory());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          databaseProvider.overrideWithValue(db),
        ],
        child: const SlimmingCheckInApp(),
      ),
    );

    // Allow the reactive streams to emit their first (empty) value.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('开始你的第一个计划'), findsOneWidget);

    await db.close();
  });

  testWidgets('dashboard renders the active plan with its stats and charts', (
    tester,
  ) async {
    // Tall viewport so the lazily-built ListView renders every card.
    tester.view.physicalSize = const Size(600, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final repo = AppRepository(db);
    final now = DateTime.now();
    await repo.createPlan(
      name: '夏日轻盈计划',
      startDate: now.subtract(const Duration(days: 5)),
      endDate: now.add(const Duration(days: 25)),
      startWeight: 80,
      targetWeight: 70,
      taskTitles: ['喝够 8 杯水'],
    );
    await repo.upsertRecord(
      planId: 1,
      date: now,
      weight: 78,
      bodyFat: 23.5,
      caloriesBurned: 300,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          databaseProvider.overrideWithValue(db),
        ],
        child: const SlimmingCheckInApp(),
      ),
    );
    // Let the streams emit and the entrance animations finish.
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('夏日轻盈计划'), findsOneWidget);
    expect(find.text('体重趋势'), findsOneWidget);
    expect(find.text('体脂率趋势'), findsOneWidget);
    expect(find.text('近 7 天消耗'), findsOneWidget);
    expect(find.text('任务打卡完成度'), findsOneWidget);

    await db.close();
  });

  testWidgets('desktop bento dashboard fills the window without overflow', (
    tester,
  ) async {
    // Desktop-sized window comfortably past the bento breakpoint.
    tester.view.physicalSize = const Size(1200, 760);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final repo = AppRepository(db);
    final now = DateTime.now();
    await repo.createPlan(
      name: '桌面计划',
      startDate: now.subtract(const Duration(days: 5)),
      endDate: now.add(const Duration(days: 25)),
      startWeight: 80,
      targetWeight: 70,
      taskTitles: ['喝够 8 杯水', '快走 30 分钟'],
    );
    await repo.upsertRecord(
      planId: 1,
      date: now,
      weight: 78,
      bodyFat: 23.5,
      caloriesBurned: 300,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          databaseProvider.overrideWithValue(db),
        ],
        child: const SlimmingCheckInApp(),
      ),
    );
    await tester.pump();
    // pumpAndSettle also surfaces any RenderFlex overflow as a test failure.
    await tester.pumpAndSettle();

    // Bento renders header, stats, today action and all charts at once.
    expect(find.text('桌面计划'), findsOneWidget);
    expect(find.text('体重趋势'), findsOneWidget);
    expect(find.text('体脂率趋势'), findsOneWidget);
    expect(find.text('近 7 天消耗'), findsOneWidget);
    expect(find.textContaining('已减重'), findsOneWidget);
    expect(find.text('任务完成度'), findsOneWidget);
    // The hero progress card surfaces the latest body-fat reading.
    expect(find.text('体脂率'), findsOneWidget);
    expect(find.text('23.5%'), findsOneWidget);

    await db.close();
  });
}
