import 'package:drift/drift.dart';

import '../../core/utils/app_date.dart';
import '../database/app_database.dart';
import '../models/task_input.dart';

/// Single access point for all persistence. Wraps the Drift [AppDatabase] with
/// intention-revealing methods and reactive streams the UI can watch.
class AppRepository {
  AppRepository(this._db);

  final AppDatabase _db;

  // ---------------------------------------------------------------------------
  // Plans
  // ---------------------------------------------------------------------------
  Stream<List<Plan>> watchPlans() =>
      (_db.select(_db.plans)
        ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).watch();

  Stream<Plan?> watchActivePlan() => (_db.select(_db.plans)..where(
    (t) => t.isActive.equals(true),
  )).watch().map((rows) => rows.isEmpty ? null : rows.first);

  Future<Plan?> getPlan(int id) =>
      (_db.select(_db.plans)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<int> createPlan({
    required String name,
    required DateTime startDate,
    required DateTime endDate,
    required double startWeight,
    required double targetWeight,
    required List<String> taskTitles,
  }) {
    return _db.transaction(() async {
      // A newly created plan becomes the active one.
      await _db
          .update(_db.plans)
          .write(const PlansCompanion(isActive: Value(false)));
      final id = await _db
          .into(_db.plans)
          .insert(
            PlansCompanion.insert(
              name: name,
              startDate: startDate.dateOnly,
              endDate: endDate.dateOnly,
              startWeight: startWeight,
              targetWeight: targetWeight,
              isActive: const Value(true),
            ),
          );
      for (var i = 0; i < taskTitles.length; i++) {
        await _db
            .into(_db.planTasks)
            .insert(
              PlanTasksCompanion.insert(
                planId: id,
                title: taskTitles[i],
                sortOrder: Value(i),
              ),
            );
      }
      return id;
    });
  }

  Future<void> updatePlan({
    required int id,
    required String name,
    required DateTime startDate,
    required DateTime endDate,
    required double startWeight,
    required double targetWeight,
    required List<TaskInput> tasks,
  }) {
    return _db.transaction(() async {
      await (_db.update(_db.plans)..where((t) => t.id.equals(id))).write(
        PlansCompanion(
          name: Value(name),
          startDate: Value(startDate.dateOnly),
          endDate: Value(endDate.dateOnly),
          startWeight: Value(startWeight),
          targetWeight: Value(targetWeight),
        ),
      );

      final existing =
          await (_db.select(_db.planTasks)
            ..where((t) => t.planId.equals(id))).get();
      final keepIds =
          tasks.where((t) => t.id != null).map((t) => t.id!).toSet();
      for (final row in existing) {
        if (!keepIds.contains(row.id)) {
          // Remove the task and any logs that referenced it.
          await (_db.delete(_db.taskLogs)
            ..where((t) => t.taskId.equals(row.id))).go();
          await (_db.delete(_db.planTasks)
            ..where((t) => t.id.equals(row.id))).go();
        }
      }
      for (var i = 0; i < tasks.length; i++) {
        final task = tasks[i];
        if (task.id == null) {
          await _db
              .into(_db.planTasks)
              .insert(
                PlanTasksCompanion.insert(
                  planId: id,
                  title: task.title,
                  sortOrder: Value(i),
                ),
              );
        } else {
          await (_db.update(_db.planTasks)
            ..where((t) => t.id.equals(task.id!))).write(
            PlanTasksCompanion(title: Value(task.title), sortOrder: Value(i)),
          );
        }
      }
    });
  }

  Future<void> setActivePlan(int id) {
    return _db.transaction(() async {
      await _db
          .update(_db.plans)
          .write(const PlansCompanion(isActive: Value(false)));
      await (_db.update(_db.plans)..where(
        (t) => t.id.equals(id),
      )).write(const PlansCompanion(isActive: Value(true)));
    });
  }

  Future<void> deletePlan(int id) {
    return _db.transaction(() async {
      final plan =
          await (_db.select(_db.plans)
            ..where((t) => t.id.equals(id))).getSingleOrNull();
      // Explicit cascade (does not rely on SQLite FK enforcement).
      await (_db.delete(_db.taskLogs)..where((t) => t.planId.equals(id))).go();
      await (_db.delete(_db.dailyRecords)
        ..where((t) => t.planId.equals(id))).go();
      await (_db.delete(_db.planTasks)..where((t) => t.planId.equals(id))).go();
      await (_db.delete(_db.plans)..where((t) => t.id.equals(id))).go();
      if (plan?.isActive == true) {
        final next =
            await (_db.select(_db.plans)
                  ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
                  ..limit(1))
                .getSingleOrNull();
        if (next != null) {
          await (_db.update(_db.plans)..where(
            (t) => t.id.equals(next.id),
          )).write(const PlansCompanion(isActive: Value(true)));
        }
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Tasks
  // ---------------------------------------------------------------------------
  Stream<List<PlanTask>> watchTasks(int planId) =>
      (_db.select(_db.planTasks)
            ..where((t) => t.planId.equals(planId))
            ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
          .watch();

  Future<List<PlanTask>> getTasks(int planId) =>
      (_db.select(_db.planTasks)
            ..where((t) => t.planId.equals(planId))
            ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
          .get();

  // ---------------------------------------------------------------------------
  // Daily records
  // ---------------------------------------------------------------------------
  Stream<DailyRecord?> watchRecord(int planId, DateTime date) {
    final d = date.dateOnly;
    return (_db.select(_db.dailyRecords)..where(
      (t) => t.planId.equals(planId) & t.date.equals(d),
    )).watch().map((rows) => rows.isEmpty ? null : rows.first);
  }

  Future<DailyRecord?> getRecord(int planId, DateTime date) {
    final d = date.dateOnly;
    return (_db.select(_db.dailyRecords)..where(
      (t) => t.planId.equals(planId) & t.date.equals(d),
    )).getSingleOrNull();
  }

  Stream<List<DailyRecord>> watchRecords(int planId) =>
      (_db.select(_db.dailyRecords)
            ..where((t) => t.planId.equals(planId))
            ..orderBy([(t) => OrderingTerm.asc(t.date)]))
          .watch();

  Future<void> upsertRecord({
    required int planId,
    required DateTime date,
    double? weight,
    double? bodyFat,
    required double caloriesBurned,
    String? note,
  }) async {
    final d = date.dateOnly;
    final existing = await getRecord(planId, d);
    if (existing == null) {
      await _db
          .into(_db.dailyRecords)
          .insert(
            DailyRecordsCompanion.insert(
              planId: planId,
              date: d,
              weight: Value(weight),
              bodyFat: Value(bodyFat),
              caloriesBurned: Value(caloriesBurned),
              note: Value(note),
            ),
          );
    } else {
      await (_db.update(_db.dailyRecords)
        ..where((t) => t.id.equals(existing.id))).write(
        DailyRecordsCompanion(
          weight: Value(weight),
          bodyFat: Value(bodyFat),
          caloriesBurned: Value(caloriesBurned),
          note: Value(note),
        ),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Task logs
  // ---------------------------------------------------------------------------
  Stream<List<TaskLog>> watchTaskLogs(int planId, DateTime date) {
    final d = date.dateOnly;
    return (_db.select(_db.taskLogs)
      ..where((t) => t.planId.equals(planId) & t.date.equals(d))).watch();
  }

  Stream<List<TaskLog>> watchAllTaskLogs(int planId) =>
      (_db.select(_db.taskLogs)..where((t) => t.planId.equals(planId))).watch();

  Future<List<TaskLog>> getTaskLogs(int planId, DateTime date) {
    final d = date.dateOnly;
    return (_db.select(_db.taskLogs)
      ..where((t) => t.planId.equals(planId) & t.date.equals(d))).get();
  }

  Future<void> setTaskCompletion({
    required int planId,
    required int taskId,
    required DateTime date,
    required bool completed,
  }) async {
    final d = date.dateOnly;
    final existing =
        await (_db.select(_db.taskLogs)..where(
          (t) => t.taskId.equals(taskId) & t.date.equals(d),
        )).getSingleOrNull();
    if (existing == null) {
      await _db
          .into(_db.taskLogs)
          .insert(
            TaskLogsCompanion.insert(
              planId: planId,
              taskId: taskId,
              date: d,
              completed: Value(completed),
            ),
          );
    } else {
      await (_db.update(_db.taskLogs)..where(
        (t) => t.id.equals(existing.id),
      )).write(TaskLogsCompanion(completed: Value(completed)));
    }
  }

  // ---------------------------------------------------------------------------
  // Maintenance
  // ---------------------------------------------------------------------------
  Future<void> clearAll() async {
    await _db.transaction(() async {
      await _db.delete(_db.taskLogs).go();
      await _db.delete(_db.dailyRecords).go();
      await _db.delete(_db.planTasks).go();
      await _db.delete(_db.plans).go();
    });
  }

  Future<Map<String, dynamic>> exportAll() async {
    final plans = await _db.select(_db.plans).get();
    final tasks = await _db.select(_db.planTasks).get();
    final records = await _db.select(_db.dailyRecords).get();
    final logs = await _db.select(_db.taskLogs).get();
    return {
      'exportedAt': DateTime.now().toIso8601String(),
      'plans':
          plans
              .map(
                (p) => {
                  'id': p.id,
                  'name': p.name,
                  'startDate': p.startDate.toIso8601String(),
                  'endDate': p.endDate.toIso8601String(),
                  'startWeight': p.startWeight,
                  'targetWeight': p.targetWeight,
                  'isActive': p.isActive,
                  'createdAt': p.createdAt.toIso8601String(),
                },
              )
              .toList(),
      'tasks':
          tasks
              .map(
                (t) => {
                  'id': t.id,
                  'planId': t.planId,
                  'title': t.title,
                  'sortOrder': t.sortOrder,
                },
              )
              .toList(),
      'records':
          records
              .map(
                (r) => {
                  'id': r.id,
                  'planId': r.planId,
                  'date': r.date.toIso8601String(),
                  'weight': r.weight,
                  'bodyFat': r.bodyFat,
                  'caloriesBurned': r.caloriesBurned,
                  'note': r.note,
                },
              )
              .toList(),
      'taskLogs':
          logs
              .map(
                (l) => {
                  'id': l.id,
                  'planId': l.planId,
                  'taskId': l.taskId,
                  'date': l.date.toIso8601String(),
                  'completed': l.completed,
                },
              )
              .toList(),
    };
  }
}
