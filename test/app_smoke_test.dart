import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slimming_checkin/app.dart';
import 'package:slimming_checkin/core/providers.dart';
import 'package:slimming_checkin/data/database/app_database.dart';
import 'package:slimming_checkin/data/repositories/app_repository.dart';
import 'package:slimming_checkin/shared/widgets/charts.dart';

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
    // Trends live behind a segmented switcher in one card now.
    expect(find.text('趋势'), findsOneWidget);
    expect(find.text('体重'), findsOneWidget);
    expect(find.text('体脂'), findsOneWidget);
    expect(find.text('消耗'), findsOneWidget);
    expect(find.byType(WeightLineChart), findsOneWidget);
    expect(find.text('任务打卡完成度'), findsOneWidget);

    // Switching the segment reveals the body-fat trend.
    await tester.tap(find.text('体脂'));
    await tester.pumpAndSettle();
    expect(find.byType(BodyFatLineChart), findsOneWidget);

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

    // Bento renders header, stats, today action and the trend card at once.
    expect(find.text('桌面计划'), findsOneWidget);
    expect(find.text('趋势'), findsOneWidget);
    expect(find.text('体重'), findsOneWidget);
    expect(find.text('体脂'), findsOneWidget);
    expect(find.text('消耗'), findsOneWidget);
    expect(find.textContaining('已减重'), findsOneWidget);
    expect(find.text('任务完成度'), findsOneWidget);
    // The hero progress card surfaces the latest body-fat reading.
    expect(find.text('体脂率'), findsOneWidget);
    expect(find.text('23.5%'), findsOneWidget);

    await db.close();
  });

  testWidgets('the centre check-in button opens the check-in sheet', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(600, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final repo = AppRepository(db);
    final now = DateTime.now();
    await repo.createPlan(
      name: '打卡计划',
      startDate: now.subtract(const Duration(days: 2)),
      endDate: now.add(const Duration(days: 28)),
      startWeight: 80,
      targetWeight: 70,
      taskTitles: ['喝够 8 杯水'],
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
    await tester.pumpAndSettle();

    // Tap the raised centre button in the bottom navigation bar. The sheet
    // loads its data through real async drift calls, so drive the frames in
    // a real-async zone until the form is ready.
    await tester.runAsync(() async {
      await tester.tap(find.byIcon(Icons.add_rounded));
      await tester.pump();
      await Future<void>.delayed(const Duration(milliseconds: 600));
      await tester.pump();
    });
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('今日打卡'), findsOneWidget);
    expect(find.text('今日体重'), findsOneWidget);
    expect(find.text('今日任务'), findsOneWidget);
    expect(find.text('保存打卡'), findsOneWidget);

    // Flush any remaining entrance-animation timers before teardown.
    await tester.pump(const Duration(seconds: 2));
    await db.close();
  });
}
