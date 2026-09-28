import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

/// A weight-loss plan: a date range with a start and target weight.
class Plans extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 60)();
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime()();
  RealColumn get startWeight => real()();
  RealColumn get targetWeight => real()();
  BoolColumn get isActive => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// A recurring daily task template that belongs to a plan.
class PlanTasks extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get planId =>
      integer().references(Plans, #id, onDelete: KeyAction.cascade)();
  TextColumn get title => text().withLength(min: 1, max: 60)();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  /// Target repetitions/units per day. 1 = simple checkbox.
  IntColumn get targetCount => integer().withDefault(const Constant(1))();

  /// Optional unit label such as 杯 / 次 / 分钟.
  TextColumn get unit => text().nullable()();
}

/// A single day's record for a plan: weight + body fat + calories + note.
class DailyRecords extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get planId =>
      integer().references(Plans, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get date => dateTime()();
  RealColumn get weight => real().nullable()();

  /// Body-fat percentage value (e.g. 23.5 means 23.5%).
  RealColumn get bodyFat => real().nullable()();
  RealColumn get caloriesBurned => real().withDefault(const Constant(0))();
  TextColumn get note => text().nullable()();

  @override
  List<Set<Column>> get uniqueKeys => [
    {planId, date},
  ];
}

/// Completion state of a single task on a single day.
class TaskLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get planId =>
      integer().references(Plans, #id, onDelete: KeyAction.cascade)();
  IntColumn get taskId =>
      integer().references(PlanTasks, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get date => dateTime()();
  BoolColumn get completed => boolean().withDefault(const Constant(false))();

  /// Progress toward [PlanTasks.targetCount]. Binary tasks use 0/1.
  IntColumn get value => integer().withDefault(const Constant(0))();

  @override
  List<Set<Column>> get uniqueKeys => [
    {taskId, date},
  ];
}

@DriftDatabase(tables: [Plans, PlanTasks, DailyRecords, TaskLogs])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'slimming_checkin'));

  /// Used by tests with an in-memory executor.
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        // v2: daily_records gains the nullable body_fat column.
        await m.addColumn(dailyRecords, dailyRecords.bodyFat);
      }
      if (from < 3) {
        // v3: dosage on tasks + per-day value on logs.
        await m.addColumn(planTasks, planTasks.targetCount);
        await m.addColumn(planTasks, planTasks.unit);
        await m.addColumn(taskLogs, taskLogs.value);
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
