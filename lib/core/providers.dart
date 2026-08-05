import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/database/app_database.dart';
import '../data/models/dashboard_stats.dart';
import '../data/repositories/app_repository.dart';
import 'utils/app_date.dart';

/// Overridden in [main] once SharedPreferences has loaded.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden');
});

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final repositoryProvider = Provider<AppRepository>(
  (ref) => AppRepository(ref.watch(databaseProvider)),
);

// --- Reactive data streams ---------------------------------------------------

final plansProvider = StreamProvider<List<Plan>>(
  (ref) => ref.watch(repositoryProvider).watchPlans(),
);

final activePlanProvider = StreamProvider<Plan?>(
  (ref) => ref.watch(repositoryProvider).watchActivePlan(),
);

final planTasksProvider = StreamProvider.family<List<PlanTask>, int>(
  (ref, planId) => ref.watch(repositoryProvider).watchTasks(planId),
);

final planRecordsProvider = StreamProvider.family<List<DailyRecord>, int>(
  (ref, planId) => ref.watch(repositoryProvider).watchRecords(planId),
);

final planAllTaskLogsProvider = StreamProvider.family<List<TaskLog>, int>(
  (ref, planId) => ref.watch(repositoryProvider).watchAllTaskLogs(planId),
);

typedef DateScopedArgs = ({int planId, DateTime date});

final recordForDateProvider =
    StreamProvider.family<DailyRecord?, DateScopedArgs>(
      (ref, args) =>
          ref.watch(repositoryProvider).watchRecord(args.planId, args.date),
    );

final taskLogsForDateProvider =
    StreamProvider.family<List<TaskLog>, DateScopedArgs>(
      (ref, args) =>
          ref.watch(repositoryProvider).watchTaskLogs(args.planId, args.date),
    );

/// Aggregated dashboard numbers for the active plan. Emits `data(null)` when no
/// plan exists yet so the UI can show its empty state.
final dashboardStatsProvider = Provider<AsyncValue<DashboardStats?>>((ref) {
  final planAsync = ref.watch(activePlanProvider);

  return planAsync.when(
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
    data: (plan) {
      if (plan == null) return const AsyncValue<DashboardStats?>.data(null);
      final today = AppDate.today();
      final tasks = ref.watch(planTasksProvider(plan.id));
      final records = ref.watch(planRecordsProvider(plan.id));
      final logs = ref.watch(planAllTaskLogsProvider(plan.id));

      if (tasks.isLoading || records.isLoading || logs.isLoading) {
        return const AsyncValue<DashboardStats?>.loading();
      }
      final err = tasks.error ?? records.error ?? logs.error;
      if (err != null) {
        return AsyncValue<DashboardStats?>.error(err, StackTrace.current);
      }

      final stats = DashboardStats.compute(
        plan: plan,
        tasks: tasks.value ?? const [],
        records: records.value ?? const [],
        logs: logs.value ?? const [],
        now: today,
      );
      return AsyncValue<DashboardStats?>.data(stats);
    },
  );
});
