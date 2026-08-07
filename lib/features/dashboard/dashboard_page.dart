import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/app_date.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/dashboard_stats.dart';
import '../../shared/widgets/animated_count.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/charts.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/progress_ring.dart';
import '../../shared/widgets/stat_tile.dart';
import '../checkin/checkin_sheet.dart';
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
      _Header(stats: stats),
      const SizedBox(height: AppSpacing.lg),
      _TodayCard(stats: stats),
      const SizedBox(height: 14),
      _ProgressCard(stats: stats, unit: unit),
      const SizedBox(height: 14),
      _StatGrid(stats: stats, unit: unit),
      const SizedBox(height: 14),
      _TaskCompletionCard(stats: stats),
      const SizedBox(height: 14),
      _TrendCard(stats: stats, unit: unit),
      const SizedBox(height: 100),
    ];

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.page,
        12,
        AppSpacing.page,
        0,
      ),
      itemCount: cards.length,
      itemBuilder:
          (context, i) => cards[i]
              .animate(delay: (50 * i).ms)
              .fadeIn(duration: 360.ms)
              .slideY(begin: 0.08, end: 0, curve: AppMotion.emphasized),
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
              _Header(stats: stats),
              const SizedBox(height: AppSpacing.lg),
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
                    // Right: the segmented trend chart fills the space.
                    Expanded(
                      child: _TrendCard(stats: stats, unit: unit, fill: true),
                    ),
                  ],
                ),
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 300.ms)
        .slideY(begin: 0.02, end: 0, curve: AppMotion.emphasized);
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.stats});
  final DashboardStats stats;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '你好 👋  今天是 ${AppDate.pretty(today)} 周${AppDate.shortWeekday(today)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13.5,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                stats.plan.name,
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
        if (stats.streak > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.calorieSoft,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                      Icons.local_fire_department_rounded,
                      size: 17,
                      color: AppColors.calorie,
                    )
                    .animate(onPlay: (c) => c.repeat(reverse: true, count: 6))
                    .scaleXY(
                      begin: 1,
                      end: 1.15,
                      duration: 800.ms,
                      curve: Curves.easeInOut,
                    ),
                const SizedBox(width: 5),
                Text(
                  '连续 ${stats.streak} 天',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.calorie,
                  ),
                ),
              ],
            ),
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
            trackColor: Colors.white.withValues(alpha: 0.75),
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
                    color: Colors.white,
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

    // The hero card sits on a soft mint gradient so the ring feels lit.
    Widget hero({required Widget child}) {
      return Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.primarySoft, AppColors.surface],
          ),
          borderRadius: AppRadius.cardAll,
          boxShadow: AppShadows.soft,
        ),
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        child: child,
      );
    }

    if (!fillHeight) {
      return hero(child: buildContent());
    }

    // Desktop: scale the hero content up with the available space so the
    // card stays prominent in large windows instead of looking empty.
    return hero(
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
          () => showCheckInSheet(
            context,
            planId: stats.plan.id,
            date: DateTime.now(),
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
        padding: const EdgeInsets.all(AppSpacing.page),
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
        curve: AppMotion.emphasized,
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
                  borderRadius: AppRadius.chipAll,
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
              curve: AppMotion.emphasized,
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

/// One card holding every trend chart; a segmented control switches between
/// weight, body-fat and calorie views with a soft cross-fade.
class _TrendCard extends StatefulWidget {
  const _TrendCard({
    required this.stats,
    required this.unit,
    this.fill = false,
  });

  final DashboardStats stats;
  final WeightUnit unit;

  /// When true the card stretches to fill its parent (desktop bento layout).
  final bool fill;

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
        height: widget.fill ? null : 200,
      ),
      'calories' => CalorieBarChart(
        key: const ValueKey('calories'),
        points: stats.last7Calories,
        height: widget.fill ? null : 200,
      ),
      _ => WeightLineChart(
        key: const ValueKey('weight'),
        points: stats.weightSeries,
        unit: widget.unit,
        targetKg: stats.plan.targetWeight,
        height: widget.fill ? null : 200,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '趋势',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
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
          const SizedBox(height: 14),
          if (widget.fill) Expanded(child: switcher) else switcher,
        ],
      ),
    );
  }
}
