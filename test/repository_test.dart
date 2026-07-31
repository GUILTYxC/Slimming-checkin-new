import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:slimming_checkin/data/database/app_database.dart';
import 'package:slimming_checkin/data/repositories/app_repository.dart';

void main() {
  late AppDatabase db;
  late AppRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = AppRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('creating a plan makes it active and stores its tasks', () async {
    final id = await repo.createPlan(
      name: 'P1',
      startDate: DateTime(2026, 7, 1),
      endDate: DateTime(2026, 7, 31),
      startWeight: 80,
      targetWeight: 70,
      taskTitles: ['喝水', '快走'],
    );

    final active = await repo.watchActivePlan().first;
    expect(active?.id, id);

    final tasks = await repo.getTasks(id);
    expect(tasks.map((t) => t.title), ['喝水', '快走']);
  });

  test('a daily record is unique per (plan, date) and upserts in place',
      () async {
    final id = await repo.createPlan(
      name: 'P',
      startDate: DateTime(2026, 7, 1),
      endDate: DateTime(2026, 7, 31),
      startWeight: 80,
      targetWeight: 70,
      taskTitles: ['a'],
    );
    final date = DateTime(2026, 7, 10);

    await repo.upsertRecord(planId: id, date: date, weight: 79, caloriesBurned: 200);
    await repo.upsertRecord(planId: id, date: date, weight: 78, caloriesBurned: 250);

    final rec = await repo.getRecord(id, date);
    expect(rec?.weight, 78);
    expect(rec?.caloriesBurned, 250);

    final all = await repo.watchRecords(id).first;
    expect(all.length, 1);
  });

  test('task completion toggles, and deleting the active plan falls back',
      () async {
    final id = await repo.createPlan(
      name: 'P',
      startDate: DateTime(2026, 7, 1),
      endDate: DateTime(2026, 7, 31),
      startWeight: 80,
      targetWeight: 70,
      taskTitles: ['a'],
    );
    final tasks = await repo.getTasks(id);
    final date = DateTime(2026, 7, 10);

    await repo.setTaskCompletion(
        planId: id, taskId: tasks.first.id, date: date, completed: true);
    expect((await repo.getTaskLogs(id, date)).single.completed, isTrue);

    await repo.setTaskCompletion(
        planId: id, taskId: tasks.first.id, date: date, completed: false);
    expect((await repo.getTaskLogs(id, date)).single.completed, isFalse);

    final id2 = await repo.createPlan(
      name: 'P2',
      startDate: DateTime(2026, 8, 1),
      endDate: DateTime(2026, 8, 31),
      startWeight: 75,
      targetWeight: 70,
      taskTitles: ['x'],
    );
    expect((await repo.watchActivePlan().first)?.id, id2);

    await repo.deletePlan(id2);
    expect((await repo.watchPlans().first).length, 1);
    expect((await repo.watchActivePlan().first)?.id, id);
  });

  test('deleting a plan cascades to its tasks and records', () async {
    final id = await repo.createPlan(
      name: 'P',
      startDate: DateTime(2026, 7, 1),
      endDate: DateTime(2026, 7, 31),
      startWeight: 80,
      targetWeight: 70,
      taskTitles: ['a', 'b'],
    );
    await repo.upsertRecord(
        planId: id, date: DateTime(2026, 7, 5), weight: 79, caloriesBurned: 100);

    await repo.deletePlan(id);

    expect(await repo.getTasks(id), isEmpty);
    expect(await repo.watchRecords(id).first, isEmpty);
  });
}
