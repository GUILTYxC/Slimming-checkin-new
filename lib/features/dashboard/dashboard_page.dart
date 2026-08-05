import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/dashboard_stats.dart';
import '../../shared/widgets/animated_count.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/charts.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/progress_ring.dart';
import '../../shared/widgets/section_header.dart';
import '../../shared/widgets/stat_tile.dart';
import '../settings/settings_controller.dart';

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
          error: (e, _) => Center(child: Text('出错了：$e')),
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
      icon: Icons.eco_rounded,
      title: '开始你的第一个计划',
      message: '设定起始与目标体重、周期以及每日打卡任务，\n轻盈打卡会帮你记录每一天的进步。',
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
    return LayoutBuilder(
      builder: (context, constraints) {
        // On roomy desktop windows use a fixed, window-filling bento layout;
        // fall back to a scrolling column on narrow / short (mobile) sizes.
        final desktop =
            constraints.maxWidth >= 680 && constraints.maxHeight >= 520;
        return desktop
            ? _BentoDashboard(stats: stats, unit: unit)
            : _ScrollingDashboard(stats: stats, unit: unit);
      },
    );
  }
}

class _ScrollingDashboard extends StatelessWidget {
  const _ScrollingDashboard({required this.stats, required this.unit});

  final DashboardStats stats;
  final WeightUnit unit;

  @override
  Widget build(BuildContext context) {
    final cards = <Widget>[
      _Header(planName: stats.plan.name),
      const SizedBox(height: 18),
      _ProgressCard(stats: stats, unit: unit),
      const SizedBox(height: 14),
      _StatGrid(stats: stats, unit: unit),
      const SizedBox(height: 14),
      _TaskCompletionCard(stats: stats),
      const SizedBox(height: 14),
      _TodayCard(stats: stats),
      const SizedBox(height: 14),
      _ChartCard(
        title: '体重趋势',
        child: WeightLineChart(
          points: stats.weightSeries,
          unit: unit,
          targetKg: stats.plan.targetWeight,
        ),
      ),
      const SizedBox(height: 14),
      _ChartCard(
        title: '体脂率趋势',
        child: BodyFatLineChart(points: stats.bodyFatSeries),
      ),
      const SizedBox(height: 14),
      _ChartCard(
        title: '近 7 天消耗',
        child: CalorieBarChart(points: stats.last7Calories),
      ),
      const SizedBox(height: 90),
    ];

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
      itemCount: cards.length,
      itemBuilder:
          (context, i) => cards[i]
              .animate(delay: (40 * i).ms)
              .fadeIn(duration: 360.ms)
              .slideY(begin: 0.08, end: 0, curve: Curves.easeOutCubic),
    );
  }
}

class _BentoDashboard extends StatelessWidget {
  const _BentoDashboard({required this.stats, required this.unit});

  final DashboardStats stats;
  final WeightUnit unit;

  @override
  Widget build(BuildContext context) {
    return Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Header(planName: stats.plan.name),
              const SizedBox(height: 16),
              SizedBox(
                height: 160,
                child: _StatGrid(
                  stats: stats,
                  unit: unit,
                  horizontal: true,
                  includeCompletion: true,
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Left: progress hero + today's check-in action.
                    SizedBox(
                      width: 300,
                      child: Column(
                        children: [
                          Expanded(
                            child: _ProgressCard(
                              stats: stats,
                              unit: unit,
                              fillHeight: true,
                            ),
                          ),
                          const SizedBox(height: 14),
                          _TodayCard(stats: stats),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Right: weight + body-fat trends side by side on top,
                    // the calorie chart filling the whole row below.
                    Expanded(
                      child: Column(
                        children: [
                          Expanded(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: _ChartCard(
                                    title: '体重趋势',
                                    fill: true,
                                    child: WeightLineChart(
                                      points: stats.weightSeries,
                                      unit: unit,
                                      targetKg: stats.plan.targetWeight,
                                      height: null,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: _ChartCard(
                                    title: '体脂率趋势',
                                    fill: true,
                                    child: BodyFatLineChart(
                                      points: stats.bodyFatSeries,
                                      height: null,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          Expanded(
                            child: _ChartCard(
                              title: '近 7 天消耗',
                              fill: true,
                              child: CalorieBarChart(
                                points: stats.last7Calories,
                                height: null,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 300.ms)
        .slideY(begin: 0.02, end: 0, curve: Curves.easeOutCubic);
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.planName});
  final String planName;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '你好 👋',
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                planName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: AppColors.primaryGradient),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.eco_rounded, color: Colors.white),
        ),
      ],
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({
    required this.stats,
    required this.unit,
    this.fillHeight = false,
  });

  final DashboardStats stats;
  final WeightUnit unit;
  final bool fillHeight;

  @override
  Widget build(BuildContext context) {
    Widget buildContent({double ringSize = 190, double numberSize = 36}) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ProgressRing(
            progress: stats.progress,
            size: ringSize,
            center: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '当前体重',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedCount(
                      value: unit.fromKg(stats.currentWeight),
                      formatter: (v) => v.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: numberSize,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 3),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: Text(
                        unit.suffix,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    stats.goalReached
                        ? '已达成目标 🎉'
                        : '已完成 ${Formatters.percent(stats.progress)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _endLabel('起始', stats.plan.startWeight, unit, AppColors.weight),
              if (stats.latestBodyFat != null) ...[
                Container(width: 1, height: 34, color: AppColors.divider),
                Column(
                  children: [
                    const Text(
                      '体脂率',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      Formatters.bodyFat(stats.latestBodyFat!),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.bodyFat,
                      ),
                    ),
                  ],
                ),
              ],
              Container(width: 1, height: 34, color: AppColors.divider),
              _endLabel(
                '目标',
                stats.plan.targetWeight,
                unit,
                AppColors.primaryDark,
              ),
            ],
          ),
        ],
      );
    }

    if (!fillHeight) {
      return AppCard(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        child: buildContent(),
      );
    }

    // Desktop: scale the hero content up with the available space so the
    // card stays prominent in large windows instead of looking empty.
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final shortSide = math.min(
            constraints.maxWidth,
            constraints.maxHeight,
          );
          final ringSize = shortSide.clamp(190.0, 260.0);
          final numberSize = 36.0 + (ringSize - 190) * 0.12;
          return Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: buildContent(ringSize: ringSize, numberSize: numberSize),
            ),
          );
        },
      ),
    );
  }

  Widget _endLabel(String label, double kg, WeightUnit unit, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12.5,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          Formatters.weight(kg, unit),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _StatGrid extends StatelessWidget {
  const _StatGrid({
    required this.stats,
    required this.unit,
    this.horizontal = false,
    this.includeCompletion = false,
  });

  final DashboardStats stats;
  final WeightUnit unit;
  final bool horizontal;
  final bool includeCompletion;

  @override
  Widget build(BuildContext context) {
    final lost = unit.fromKg(stats.weightLostKg);
    final remaining = unit.fromKg(stats.remainingKg);

    final tiles = [
      StatTile(
        icon: Icons.trending_down_rounded,
        accent: AppColors.success,
        accentSoft: const Color(0xFFE6F8EF),
        label: '已减重 (${unit.suffix})',
        valueWidget: AnimatedCount(
          value: lost,
          formatter: (v) => v.toStringAsFixed(1),
        ),
      ),
      StatTile(
        icon: Icons.flag_rounded,
        accent: AppColors.weight,
        accentSoft: AppColors.weightSoft,
        label: '距目标 (${unit.suffix})',
        valueWidget:
            stats.goalReached
                ? const Text('达成')
                : AnimatedCount(
                  value: remaining,
                  formatter: (v) => v.toStringAsFixed(1),
                ),
      ),
      StatTile(
        icon: Icons.event_available_rounded,
        accent: AppColors.warning,
        accentSoft: const Color(0xFFFFF3DD),
        label: '剩余天数',
        caption: '共 ${stats.totalDays} 天',
        valueWidget: AnimatedCount(
          value: stats.daysRemaining.toDouble(),
          formatter: (v) => v.round().toString(),
        ),
      ),
      StatTile(
        icon: Icons.local_fire_department_rounded,
        accent: AppColors.calorie,
        accentSoft: AppColors.calorieSoft,
        label: '连续打卡',
        caption: '天',
        valueWidget: AnimatedCount(
          value: stats.streak.toDouble(),
          formatter: (v) => v.round().toString(),
        ),
      ),
    ];

    if (includeCompletion) {
      tiles.add(
        StatTile(
          icon: Icons.checklist_rounded,
          accent: AppColors.primaryDark,
          accentSoft: AppColors.primarySoft,
          label: '任务完成度',
          caption: '累计 ${stats.totalTaskDone}/${stats.totalTaskExpected}',
          valueWidget: AnimatedCount(
            value: stats.taskCompletionRate * 100,
            formatter: (v) => '${v.round()}%',
          ),
        ),
      );
    }

    if (horizontal) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < tiles.length; i++) ...[
            if (i > 0) const SizedBox(width: 12),
            Expanded(child: tiles[i]),
          ],
        ],
      );
    }
    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        mainAxisExtent: 160,
      ),
      children: tiles,
    );
  }
}

class _TodayCard extends StatelessWidget {
  const _TodayCard({required this.stats});
  final DashboardStats stats;

  @override
  Widget build(BuildContext context) {
    final done = stats.checkedInToday;
    return AppCard(
      padding: EdgeInsets.zero,
      onTap:
          () => context.push(
            '/checkin',
            extra: CheckInArgs(planId: stats.plan.id, date: DateTime.now()),
          ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors:
                done
                    ? [const Color(0xFFEFFBF7), const Color(0xFFEAF3FF)]
                    : AppColors.primaryGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(18),
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
                      fontWeight: FontWeight.w800,
                      color: done ? AppColors.textPrimary : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    done
                        ? '消耗 ${Formatters.calories(stats.todayCalories)} 千卡 · 任务 ${stats.todayTasksDone}/${stats.todayTasksTotal}'
                        : '记录今日体重、消耗与任务完成情况',
                    style: TextStyle(
                      fontSize: 13,
                      color:
                          done
                              ? AppColors.textSecondary
                              : Colors.white.withValues(alpha: 0.92),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _TaskProgressBar(ratio: stats.todayTaskRatio, onLight: !done),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: done ? AppColors.primary : Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(
                done ? Icons.check_rounded : Icons.arrow_forward_rounded,
                color: done ? Colors.white : AppColors.primaryDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskProgressBar extends StatelessWidget {
  const _TaskProgressBar({required this.ratio, required this.onLight});
  final double ratio;
  final bool onLight;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: ratio.clamp(0.0, 1.0).toDouble()),
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeOutCubic,
        builder:
            (context, v, _) => LinearProgressIndicator(
              value: v,
              minHeight: 8,
              backgroundColor:
                  onLight
                      ? Colors.white.withValues(alpha: 0.35)
                      : AppColors.surfaceMuted,
              valueColor: AlwaysStoppedAnimation(
                onLight ? Colors.white : AppColors.primary,
              ),
            ),
      ),
    );
  }
}

class _TaskCompletionCard extends StatelessWidget {
  const _TaskCompletionCard({required this.stats});
  final DashboardStats stats;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.checklist_rounded,
                  color: AppColors.primaryDark,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '任务打卡完成度',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '累计完成 ${stats.totalTaskDone} / ${stats.totalTaskExpected} 次打卡',
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedCount(
                value: stats.taskCompletionRate * 100,
                formatter: (v) => '${v.round()}%',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: TweenAnimationBuilder<double>(
              tween: Tween(
                begin: 0,
                end: stats.taskCompletionRate.clamp(0.0, 1.0).toDouble(),
              ),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder:
                  (context, v, _) => LinearProgressIndicator(
                    value: v,
                    minHeight: 10,
                    backgroundColor: AppColors.surfaceMuted,
                    valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.title,
    required this.child,
    this.fill = false,
  });
  final String title;
  final Widget child;
  final bool fill;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: title),
          const SizedBox(height: 14),
          if (fill) Expanded(child: child) else child,
        ],
      ),
    );
  }
}
