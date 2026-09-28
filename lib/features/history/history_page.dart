import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/providers.dart';
import '../../core/theme/app_glass.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/app_date.dart';
import '../../core/utils/formatters.dart';
import '../../data/database/app_database.dart';
import '../../data/models/dashboard_stats.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/fade_in_once.dart';
import '../checkin/checkin_sheet.dart';
import '../settings/settings_controller.dart';
import '../../core/theme/app_palette.dart';

/// Check-in history: a three-cell summary followed by records grouped by
/// month.
///
/// The summary uses hairline dividers inside a single card instead of three
/// competing coloured cards, and each record row keeps only the numbers that
/// matter.
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
      builder: (context, child) {
        final base = Theme.of(context);
        final scheme = ColorScheme.fromSeed(
          seedColor: context.palette.primary,
          brightness: base.brightness,
        );
        return Theme(
          data: base.copyWith(colorScheme: scheme),
          child: child!,
        );
      },
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
      body: SafeArea(
        bottom: false,
        child: planAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error:
              (e, _) => EmptyState(
                icon: Icons.cloud_off_rounded,
                title: '数据加载失败',
                message: '没能读取本地数据，请重试。\n$e',
                action: FilledButton.icon(
                  onPressed: () => ref.invalidate(activePlanProvider),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('重试'),
                ),
              ),
          data: (plan) {
            if (plan == null) {
              return const EmptyState(
                icon: Icons.calendar_month_rounded,
                title: '暂无历史',
                message: '创建计划并开始打卡后，你的每日记录会显示在这里。',
              );
            }
            return _HistoryList(plan: plan, unit: unit, onBackfill: () => _backfill(context, plan));
          },
        ),
      ),
    );
  }
}

class _HistoryList extends ConsumerStatefulWidget {
  const _HistoryList({
    required this.plan,
    required this.unit,
    required this.onBackfill,
  });

  final Plan plan;
  final WeightUnit unit;
  final VoidCallback onBackfill;

  @override
  ConsumerState<_HistoryList> createState() => _HistoryListState();
}

class _HistoryListState extends ConsumerState<_HistoryList> {
  String _filter = 'all'; // all | incomplete | week

  @override
  Widget build(BuildContext context) {
    final plan = widget.plan;
    final unit = widget.unit;
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

    var sorted = [...records]..sort((a, b) => b.date.compareTo(a.date));
    final doneByDate = <DateTime, int>{};
    for (final l in logs) {
      if (l.completed) {
        final d = l.date.dateOnly;
        doneByDate[d] = (doneByDate[d] ?? 0) + 1;
      }
    }

    final weekAgo = AppDate.addDays(AppDate.today(), -7);
    sorted = sorted.where((r) {
      if (_filter == 'week' && r.date.dateOnly.isBefore(weekAgo)) return false;
      if (_filter == 'incomplete') {
        final done = doneByDate[r.date.dateOnly] ?? 0;
        return tasks.isNotEmpty && done < tasks.length;
      }
      return true;
    }).toList();
    final totalCalories = records.fold<double>(
      0,
      (s, r) => s + r.caloriesBurned,
    );
    // Same rule as the overview dashboard: records ∪ completed logs, with a
    // one-day grace when today is still open.
    final streak = DashboardStats.computeStreak([
      for (final r in records) r.date.dateOnly,
      for (final l in logs)
        if (l.completed) l.date.dateOnly,
    ], AppDate.today());

    // Flatten the list into: title, summary card, then month header + rows.
    final items = <Widget>[
      _PageHeader(onBackfill: widget.onBackfill),
      _SummaryBar(
        days: records.length,
        totalCalories: totalCalories,
        streak: streak,
      ),
      _StreakMilestone(streak: streak),
      _FilterChips(
        value: _filter,
        onChanged: (v) => setState(() => _filter = v),
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
          doneTasks: doneByDate[r.date.dateOnly] ?? 0,
          totalTasks: tasks.length,
          onTap: () => showCheckInSheet(context, planId: plan.id, date: r.date),
          onLongPress: () => _quickActions(context, plan, r),
        ),
      );
    }

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.page,
            AppSpacing.sm,
            AppSpacing.page,
            120,
          ),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
          itemBuilder:
              (context, index) => FadeInOnce(
                delay: (25 * index).clamp(0, 400).ms,
                child: items[index],
              ),
        ),
      ),
    );
  }

  void _quickActions(BuildContext context, Plan plan, DailyRecord record) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.palette.surface,
      builder:
          (ctx) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.edit_note_rounded),
                  title: const Text('编辑当日打卡'),
                  onTap: () {
                    Navigator.pop(ctx);
                    showCheckInSheet(
                      context,
                      planId: plan.id,
                      date: record.date,
                    );
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.delete_outline_rounded,
                    color: context.palette.danger,
                  ),
                  title: Text(
                    '清除当日指标',
                    style: TextStyle(color: context.palette.danger),
                  ),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final repo = ref.read(repositoryProvider);
                    await repo.upsertRecord(
                      planId: plan.id,
                      date: record.date,
                      caloriesBurned: 0,
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('已清除当日指标')),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
    );
  }
}

/// Filter chips above the history rows.
class _FilterChips extends StatelessWidget {
  const _FilterChips({required this.value, required this.onChanged});
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget chip(String id, String label) {
      final selected = value == id;
      return GestureDetector(
        onTap: () => onChanged(id),
        child: AnimatedContainer(
          duration: AppMotion.fast,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color:
                selected ? context.palette.primary : context.palette.fillInset,
            borderRadius: AppRadius.pillAll,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : context.palette.textSecondary,
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        chip('all', '全部'),
        const SizedBox(width: AppSpacing.sm),
        chip('incomplete', '任务未齐'),
        const SizedBox(width: AppSpacing.sm),
        chip('week', '近 7 天'),
      ],
    );
  }
}

/// Screen title shared with the other four screens: same 28/700 size.
class _PageHeader extends StatelessWidget {
  const _PageHeader({required this.onBackfill});
  final VoidCallback onBackfill;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '打卡历史',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                    height: 1.15,
                    color: context.palette.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '每一次记录，都是向着目标的一步',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0,
                    color: context.palette.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: onBackfill,
            icon: const Icon(Icons.edit_calendar_rounded, size: 18),
            label: const Text('补记'),
          ),
        ],
      ),
    );
  }
}

/// Three stats in one card, separated by hairlines.
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
    return AppCard(
      padding: EdgeInsets.zero,
      clip: true,
      child: IntrinsicHeight(
        child: Row(
          children: [
            _Cell(
              value: '$days',
              label: '打卡天数',
              icon: Icons.calendar_today_rounded,
              tint: context.palette.primary,
            ),
            VerticalDivider(
              width: 1,
              thickness: 1,
              color: context.palette.textPrimary.withValues(alpha: 0.08),
            ),
            _Cell(
              value: Formatters.calories(totalCalories),
              label: '累计消耗 (千卡)',
              icon: Icons.local_fire_department_rounded,
              tint: context.palette.calorie,
            ),
            VerticalDivider(
              width: 1,
              thickness: 1,
              color: context.palette.textPrimary.withValues(alpha: 0.08),
            ),
            _Cell(
              value: '$streak',
              label: '连续打卡',
              icon: Icons.brightness_auto_rounded,
              tint: context.palette.bodyFat,
            ),
          ],
        ),
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({
    required this.value,
    required this.label,
    required this.icon,
    required this.tint,
  });
  final String value;
  final String label;
  final IconData icon;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.lg,
        ),
        child: Column(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: tint.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: tint),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                letterSpacing: 0,
                height: 1.15,
                color: context.palette.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: context.palette.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shows the next streak milestone so the achievement system is visible
/// without crowding the dashboard.
class _StreakMilestone extends StatelessWidget {
  const _StreakMilestone({required this.streak});
  final int streak;

  @override
  Widget build(BuildContext context) {
    const milestones = [3, 7, 21, 66];
    const names = ['启程', '一周', '习惯', '蜕变'];

    var nextIndex = milestones.indexWhere((m) => streak < m);
    nextIndex = nextIndex == -1 ? milestones.length - 1 : nextIndex;
    final next = milestones[nextIndex];
    final name = names[nextIndex];
    final prev = nextIndex > 0 ? milestones[nextIndex - 1] : 0;
    final progress = next == prev
        ? 1.0
        : ((streak - prev) / (next - prev)).clamp(0.0, 1.0);

    return AppCard(
      child: Row(
        children: [
          // A small glass bead: nested inside the card's pane, so it picks up
          // a second, stronger blur and reads as a solid object.
          GlassSurface(
            radius: 999,
            inset: true,
            width: 44,
            height: 44,
            alignment: Alignment.center,
            child: Icon(
              Icons.emoji_events_rounded,
              color: context.palette.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '连续打卡 $streak 天',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0,
                    color: context.palette.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  streak >= next
                      ? '恭喜！已解锁「$name」徽章'
                      : '距离「$name」徽章还差 ${next - streak} 天',
                  style: TextStyle(
                    fontSize: 12,
                    color: context.palette.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.palette.fillInset,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: progress,
                    child: Container(
                      decoration: BoxDecoration(
                        color: context.palette.primary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthHeader extends StatelessWidget {
  const _MonthHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        top: AppSpacing.sm,
        left: 2,
        bottom: 2,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
          color: context.palette.textSecondary,
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
    this.onLongPress,
  });

  final DailyRecord record;
  final WeightUnit unit;
  final int doneTasks;
  final int totalTasks;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final allDone = totalTasks > 0 && doneTasks >= totalTasks;
    final isToday = record.date.isToday;
    return AppCard(
      radius: AppRadius.small,
      padding: const EdgeInsets.all(AppSpacing.md),
      onTap: onTap,
      onLongPress: onLongPress,
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: isToday ? context.palette.primarySoft : context.palette.fillInset,
              borderRadius: AppRadius.smallAll,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  DateFormat('dd').format(record.date),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                    color:
                        isToday ? context.palette.primary : context.palette.textPrimary,
                  ),
                ),
                Text(
                  '${record.date.month}月',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color:
                        isToday ? context.palette.primary : context.palette.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppDate.relativeLabel(record.date),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0,
                    color: context.palette.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${record.weight != null ? Formatters.weight(record.weight!, unit) : '未记录'}'
                  '${record.bodyFat != null ? ' · 体脂 ${Formatters.bodyFat(record.bodyFat!)}' : ''}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: context.palette.textSecondary,
                  ),
                ),
                Text(
                  '消耗 ${Formatters.calories(record.caloriesBurned)} 千卡',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: context.palette.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          if (totalTasks > 0)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: allDone ? context.palette.successSoft : context.palette.fillInset,
                borderRadius: AppRadius.pillAll,
              ),
              child: Text(
                '$doneTasks/$totalTasks',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color:
                      allDone
                          ? context.palette.successText
                          : context.palette.textTertiary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
