import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/app_date.dart';
import '../../core/utils/formatters.dart';
import '../../data/database/app_database.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/empty_state.dart';
import '../checkin/checkin_sheet.dart';
import '../settings/settings_controller.dart';

class HistoryPage extends ConsumerWidget {
  const HistoryPage({super.key});

  Future<void> _backfill(BuildContext context, Plan plan) async {
    final today = AppDate.today();
    final last = plan.endDate.isBefore(today) ? plan.endDate : today;
    final picked = await showDatePicker(
      context: context,
      initialDate: last,
      firstDate: plan.startDate,
      lastDate: last,
      builder:
          (context, child) => Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(primary: AppColors.primary),
            ),
            child: child!,
          ),
    );
    if (picked != null && context.mounted) {
      await showCheckInSheet(context, planId: plan.id, date: picked.dateOnly);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planAsync = ref.watch(activePlanProvider);
    final unit = ref.watch(settingsProvider.select((s) => s.weightUnit));

    return Scaffold(
      appBar: AppBar(
        title: const Text('打卡历史'),
        actions: [
          planAsync.maybeWhen(
            data:
                (plan) =>
                    plan == null
                        ? const SizedBox.shrink()
                        : IconButton(
                          tooltip: '补记',
                          onPressed: () => _backfill(context, plan),
                          icon: const Icon(Icons.edit_calendar_rounded),
                        ),
            orElse: () => const SizedBox.shrink(),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: planAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('出错了：$e')),
        data: (plan) {
          if (plan == null) {
            return const EmptyState(
              icon: Icons.calendar_month_rounded,
              title: '暂无历史',
              message: '创建计划并开始打卡后，你的每日记录会显示在这里。',
            );
          }
          return _HistoryList(plan: plan, unit: unit);
        },
      ),
    );
  }
}

class _HistoryList extends ConsumerWidget {
  const _HistoryList({required this.plan, required this.unit});

  final Plan plan;
  final WeightUnit unit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final records =
        ref.watch(planRecordsProvider(plan.id)).valueOrNull ?? const [];
    final tasks = ref.watch(planTasksProvider(plan.id)).valueOrNull ?? const [];
    final logs =
        ref.watch(planAllTaskLogsProvider(plan.id)).valueOrNull ?? const [];

    if (records.isEmpty) {
      return EmptyState(
        icon: Icons.calendar_month_rounded,
        title: '还没有打卡记录',
        message: '点击右上角补记，或回到概览页开始今天的打卡。',
        action: FilledButton.icon(
          onPressed:
              () => showCheckInSheet(
                context,
                planId: plan.id,
                date: DateTime.now(),
              ),
          icon: const Icon(Icons.add_task_rounded),
          label: const Text('去打卡'),
        ),
      );
    }

    final sorted = [...records]..sort((a, b) => b.date.compareTo(a.date));
    final doneByDate = <DateTime, int>{};
    for (final l in logs) {
      if (l.completed) {
        final d = l.date;
        doneByDate[d] = (doneByDate[d] ?? 0) + 1;
      }
    }
    final totalCalories = records.fold<double>(
      0,
      (s, r) => s + r.caloriesBurned,
    );
    final streak = _streak(sorted.map((r) => r.date).toList());

    // Flatten the list into: summary card, then month header + tiles.
    final items = <Widget>[
      _SummaryBar(
        days: records.length,
        totalCalories: totalCalories,
        streak: streak,
      ),
    ];
    String? lastMonth;
    for (final r in sorted) {
      final month = DateFormat('yyyy年M月').format(r.date);
      if (month != lastMonth) {
        lastMonth = month;
        items.add(_MonthHeader(label: month));
      }
      items.add(
        _HistoryTile(
          record: r,
          unit: unit,
          doneTasks: doneByDate[r.date] ?? 0,
          totalTasks: tasks.length,
          onTap: () => showCheckInSheet(context, planId: plan.id, date: r.date),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.page,
        12,
        AppSpacing.page,
        100,
      ),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder:
          (context, index) => items[index]
              .animate(delay: (25 * index).clamp(0, 400).ms)
              .fadeIn(duration: 300.ms),
    );
  }

  /// Counts consecutive recorded days walking back from the latest record.
  static int _streak(List<DateTime> datesDesc) {
    if (datesDesc.isEmpty) return 0;
    var streak = 1;
    for (var i = 1; i < datesDesc.length; i++) {
      final gap = datesDesc[i - 1].difference(datesDesc[i]).inDays;
      if (gap == 1) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }
}

class _SummaryBar extends StatelessWidget {
  const _SummaryBar({
    required this.days,
    required this.totalCalories,
    required this.streak,
  });

  final int days;
  final double totalCalories;
  final int streak;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppColors.primaryGradient,
        ),
        borderRadius: AppRadius.cardAll,
        boxShadow: AppShadows.soft,
      ),
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.xl,
        horizontal: AppSpacing.md,
      ),
      child: Row(
        children: [
          Expanded(child: _stat('$days', '打卡天数')),
          _divider(),
          Expanded(
            child: _stat(Formatters.calories(totalCalories), '累计消耗 (千卡)'),
          ),
          _divider(),
          Expanded(child: _stat('$streak', '连续打卡')),
        ],
      ),
    );
  }

  Widget _divider() => Container(
    width: 1,
    height: 36,
    color: Colors.white.withValues(alpha: 0.4),
  );

  Widget _stat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ),
      ],
    );
  }
}

class _MonthHeader extends StatelessWidget {
  const _MonthHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm, left: 2),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w800,
          color: AppColors.textSecondary,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({
    required this.record,
    required this.unit,
    required this.doneTasks,
    required this.totalTasks,
    required this.onTap,
  });

  final DailyRecord record;
  final WeightUnit unit;
  final int doneTasks;
  final int totalTasks;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final allDone = totalTasks > 0 && doneTasks >= totalTasks;
    final isToday = record.date.isToday;
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: isToday ? AppColors.primarySoft : AppColors.surfaceMuted,
              borderRadius: AppRadius.smallAll,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  DateFormat('dd').format(record.date),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    height: 1,
                    color:
                        isToday ? AppColors.primaryDark : AppColors.textPrimary,
                  ),
                ),
                Text(
                  DateFormat('MMM').format(record.date),
                  style: TextStyle(
                    fontSize: 11,
                    color:
                        isToday
                            ? AppColors.primaryDark
                            : AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      AppDate.relativeLabel(record.date),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '周${AppDate.shortWeekday(record.date)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 10,
                  runSpacing: 6,
                  children: [
                    _pill(
                      Icons.monitor_weight_rounded,
                      record.weight != null
                          ? Formatters.weight(record.weight!, unit)
                          : '未记录',
                      AppColors.weight,
                    ),
                    if (record.bodyFat != null)
                      _pill(
                        Icons.percent_rounded,
                        Formatters.bodyFat(record.bodyFat!),
                        AppColors.bodyFat,
                      ),
                    _pill(
                      Icons.local_fire_department_rounded,
                      '${Formatters.calories(record.caloriesBurned)} 千卡',
                      AppColors.calorie,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (totalTasks > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: allDone ? AppColors.primarySoft : AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    allDone
                        ? Icons.check_circle_rounded
                        : Icons.check_circle_outline_rounded,
                    size: 15,
                    color:
                        allDone
                            ? AppColors.primaryDark
                            : AppColors.textTertiary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$doneTasks/$totalTasks',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color:
                          allDone
                              ? AppColors.primaryDark
                              : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _pill(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            fontSize: 12.5,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
