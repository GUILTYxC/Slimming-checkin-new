import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_glass.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/app_date.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/dashboard_stats.dart';
import '../../shared/widgets/animated_count.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/charts.dart';
import '../../shared/widgets/empty_state.dart';
import '../checkin/checkin_sheet.dart';
import '../settings/settings_controller.dart';

/// Overview screen.
///
/// The whole screen answers one question — "what do I do today, and how am
/// I doing?" — so it opens on the check-in call to action and gives the
/// current weight number the only hero treatment. Every metric appears
/// exactly once.
///
/// The layout is a single scrolling column on every form factor; on wide
/// windows it is simply centre-constrained instead of switching to a second
/// bespoke layout.
class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);
    final unit = ref.watch(settingsProvider.select((s) => s.weightUnit));

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: statsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error:
              (e, _) => EmptyState(
                icon: Icons.cloud_off_rounded,
                title: '数据加载失败',
                message: '没能读取本地数据，请重试。\n$e',
                action: FilledButton.icon(
                  onPressed: () => ref.invalidate(dashboardStatsProvider),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('重试'),
                ),
              ),
          data: (stats) {
            if (stats == null) return _empty(context);
            return _DashboardContent(stats: stats, unit: unit);
          },
        ),
      ),
    );
  }

  Widget _empty(BuildContext context) {
    return EmptyState(
      icon: Icons.flag_rounded,
      title: '开始你的第一个计划',
      message: '设定起始与目标体重、周期以及每日打卡任务，轻盈打卡会帮你记录每一天的进步。',
      action: FilledButton.icon(
        onPressed: () => context.push('/plan/new'),
        icon: const Icon(Icons.add_rounded),
        label: const Text('创建减肥计划'),
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({required this.stats, required this.unit});

  final DashboardStats stats;
  final WeightUnit unit;

  @override
  Widget build(BuildContext context) {
    final cards = <Widget>[
      _Header(stats: stats),
      _TodayCard(stats: stats),
      _WeightCard(stats: stats, unit: unit),
      _TrendCard(stats: stats, unit: unit),
    ];

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: ListView.separated(
          // Generous bottom padding so the last card can scroll clear of the
          // floating pill tab bar.
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.page,
            AppSpacing.sm,
            AppSpacing.page,
            120,
          ),
          itemCount: cards.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.lg),
          itemBuilder:
              (context, i) => cards[i]
                  .animate(delay: (40 * i).ms)
                  .fadeIn(duration: 320.ms)
                  .slideY(begin: 0.06, end: 0, curve: AppMotion.emphasized),
        ),
      ),
    );
  }
}

// ── Header ─────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.stats});
  final DashboardStats stats;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
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
                  '今天 · ${today.month}月${today.day}日 周${AppDate.shortWeekday(today)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.08,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  stats.plan.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                    height: 1.15,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          if (stats.streak > 0) _StreakPill(streak: stats.streak),
        ],
      ),
    );
  }
}

/// Streak is shown here and nowhere else on this screen.
class _StreakPill extends StatelessWidget {
  const _StreakPill({required this.streak});
  final int streak;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.62),
        borderRadius: AppRadius.pillAll,
        border: Border.all(color: AppGlass.strokeTop),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.local_fire_department_rounded,
            size: 16,
            color: AppColors.calorie,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            '连续 $streak 天',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.08,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared helpers ─────────────────────────────────────────────────────────

/// A tinted rounded-square icon well used by metric cards and section labels.
///
/// Keeps the visual language consistent with the design system: 12% tint of
/// the data colour, small corner radius, solid coloured icon.
class _IconWell extends StatelessWidget {
  const _IconWell({required this.icon, required this.tint});

  final IconData icon;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(icon, size: 14, color: tint),
    );
  }
}

// ── Today's check-in call to action ────────────────────────────────────────

/// The screen's primary action. Blue fill when there is still something to
/// do today, a calm outlined card once the day is recorded.
class _TodayCard extends StatelessWidget {
  const _TodayCard({required this.stats});
  final DashboardStats stats;

  @override
  Widget build(BuildContext context) {
    final done = stats.checkedInToday;
    return AppCard(
      padding: EdgeInsets.zero,
      radius: AppRadius.card,
      border:
          done ? Border.all(color: AppColors.hairline) : null,
      onTap:
          () => showCheckInSheet(
            context,
            planId: stats.plan.id,
            date: DateTime.now(),
          ),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            gradient: done ? null : AppGradients.cta,
            color: done ? AppColors.surface : null,
            borderRadius: AppRadius.cardAll,
          ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    done ? '今日已打卡' : '今天还没打卡',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.37,
                      color: done ? AppColors.textPrimary : Colors.white,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    done
                        ? '消耗 ${Formatters.calories(stats.todayCalories)} 千卡 · 任务 ${stats.todayTasksDone}/${stats.todayTasksTotal}'
                        : '记录体重、消耗与今日任务，约 30 秒',
                    style: TextStyle(
                      fontSize: 13,
                      letterSpacing: -0.08,
                      color:
                          done
                              ? AppColors.textSecondary
                              : Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            _TodayAction(done: done),
          ],
        ),
      ),
    );
  }
}

class _TodayAction extends StatelessWidget {
  const _TodayAction({required this.done});
  final bool done;

  @override
  Widget build(BuildContext context) {
    if (done) {
      return Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          color: AppColors.successSoft,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.check_rounded,
          color: AppColors.successText,
          size: 22,
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: AppRadius.pillAll,
      ),
      child: const Text(
        '去打卡',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

// ── Weight hero ────────────────────────────────────────────────────────────

/// The screen's single focal point: today's weight, how far along the goal
/// it is, and the remaining metrics as one quiet caption line.
class _WeightCard extends StatelessWidget {
  const _WeightCard({required this.stats, required this.unit});

  final DashboardStats stats;
  final WeightUnit unit;

  @override
  Widget build(BuildContext context) {
    final remaining = unit.fromKg(stats.remainingKg);
    final lost = unit.fromKg(stats.weightLostKg);
    final lostText = Formatters.weight(lost.abs(), unit);

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        _IconWell(
                          icon: Icons.monitor_weight_rounded,
                          tint: AppColors.weight,
                        ),
                        SizedBox(width: AppSpacing.sm),
                        Text(
                          '当前体重',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            letterSpacing: -0.08,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        AnimatedCount(
                          value: unit.fromKg(stats.currentWeight),
                          formatter: (v) => v.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 56,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.28,
                            height: 1.05,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          unit.suffix,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (stats.weightLostKg > 0.05)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.successSoft,
                    borderRadius: AppRadius.pillAll,
                  ),
                  child: Text(
                    '已减 $lostText',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.successText,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '已完成 ${Formatters.percent(stats.progress)}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.08,
                  color: AppColors.primary,
                ),
              ),
              Text(
                stats.goalReached
                    ? '已达成目标'
                    : '还差 ${Formatters.weight(remaining.abs(), unit)}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.08,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          _ProgressBar(value: stats.progress),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '起始 ${Formatters.weight(stats.plan.startWeight, unit)}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textTertiary,
                ),
              ),
              Text(
                '目标 ${Formatters.weight(stats.plan.targetWeight, unit)}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            '距目标 ${Formatters.weight(remaining.abs(), unit)} · '
            '剩余 ${stats.daysRemaining} 天 · '
            '累计完成度 ${Formatters.percent(stats.taskCompletionRate)}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              letterSpacing: -0.12,
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

/// 6px hairline progress bar used by the weight card.
class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.value});
  final double value;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.clamp(0.0, 1.0).toDouble()),
      duration: AppMotion.slow,
      curve: AppMotion.emphasized,
      builder: (context, v, _) {
        return Container(
          height: 6,
          decoration: BoxDecoration(
            color: AppGlass.fillInset,
            borderRadius: BorderRadius.circular(3),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: v,
            child: Container(
              decoration: BoxDecoration(
                gradient: AppGradients.progress,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── Trend ──────────────────────────────────────────────────────────────────

/// One card holding every trend chart; a segmented control switches between
/// weight, body-fat and calorie views with a soft cross-fade.
class _TrendCard extends StatefulWidget {
  const _TrendCard({required this.stats, required this.unit});

  final DashboardStats stats;
  final WeightUnit unit;

  @override
  State<_TrendCard> createState() => _TrendCardState();
}

class _TrendCardState extends State<_TrendCard> {
  String _tab = 'weight';

  @override
  Widget build(BuildContext context) {
    final stats = widget.stats;
    final chart = switch (_tab) {
      'bodyFat' => BodyFatLineChart(
        key: const ValueKey('bodyFat'),
        points: stats.bodyFatSeries,
        height: 150,
      ),
      'calories' => CalorieBarChart(
        key: const ValueKey('calories'),
        points: stats.last7Calories,
        height: 150,
      ),
      _ => WeightLineChart(
        key: const ValueKey('weight'),
        points: stats.weightSeries,
        unit: widget.unit,
        targetKg: stats.plan.targetWeight,
        height: 150,
      ),
    };

    final switcher = AnimatedSwitcher(
      duration: AppMotion.normal,
      switchInCurve: AppMotion.emphasized,
      transitionBuilder:
          (child, anim) => FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.03, 0),
                end: Offset.zero,
              ).animate(anim),
              child: child,
            ),
          ),
      child: chart,
    );

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Row(
                children: [
                  _IconWell(
                    icon: Icons.show_chart_rounded,
                    tint: AppColors.weight,
                  ),
                  SizedBox(width: AppSpacing.sm),
                  Text(
                    '趋势',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.37,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Text(
                _tab == 'calories' ? '近 7 天' : '全程',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // Parchment track with a white pill for the selected segment.
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: AppGlass.fillInset,
              borderRadius: BorderRadius.circular(9),
            ),
            child: SegmentedButton<String>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(
                  value: 'weight',
                  label: Text('体重'),
                  icon: Icon(Icons.monitor_weight_rounded, size: 16),
                ),
                ButtonSegment(
                  value: 'bodyFat',
                  label: Text('体脂'),
                  icon: Icon(Icons.percent_rounded, size: 16),
                ),
                ButtonSegment(
                  value: 'calories',
                  label: Text('消耗'),
                  icon: Icon(Icons.local_fire_department_rounded, size: 16),
                ),
              ],
              selected: {_tab},
              onSelectionChanged: (s) => setState(() => _tab = s.first),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          switcher,
        ],
      ),
    );
  }
}
