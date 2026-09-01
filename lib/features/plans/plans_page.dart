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
import '../../data/database/app_database.dart';
import '../../shared/widgets/app_bottom_sheet.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/empty_state.dart';
import '../settings/settings_controller.dart';

/// Plan list. The active plan is marked with an accent outline rather than a
/// gradient ring, and every plan shows the same start → target weight chips
/// so cards stay comparable.
class PlansPage extends ConsumerWidget {
  const PlansPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plansAsync = ref.watch(plansProvider);
    final unit = ref.watch(settingsProvider.select((s) => s.weightUnit));

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: plansAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error:
              (e, _) => EmptyState(
                icon: Icons.cloud_off_rounded,
                title: '数据加载失败',
                message: '没能读取本地数据，请重试。\n$e',
                action: FilledButton.icon(
                  onPressed: () => ref.invalidate(plansProvider),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('重试'),
                ),
              ),
          data: (plans) {
            if (plans.isEmpty) {
              return EmptyState(
                icon: Icons.flag_rounded,
                title: '还没有计划',
                message: '创建一个减肥计划，设定目标与每日任务后即可开始打卡。',
                action: FilledButton.icon(
                  onPressed: () => context.push('/plan/new'),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('创建计划'),
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
                  itemCount: plans.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.lg),
                  itemBuilder: (context, i) {
                    if (i == 0) return const _PageHeader();
                    return _PlanCard(plan: plans[i - 1], unit: unit)
                        .animate(delay: (40 * i).ms)
                        .fadeIn(duration: 320.ms)
                        .slideY(begin: 0.06, end: 0, curve: AppMotion.emphasized);
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Expanded(
            child: Text(
              '我的计划',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.4,
                height: 1.15,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          FilledButton.icon(
            onPressed: () => context.push('/plan/new'),
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 36),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              textStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('新建计划'),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends ConsumerWidget {
  const _PlanCard({required this.plan, required this.unit});

  final Plan plan;
  final WeightUnit unit;

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder:
          (context) => GlassDialog(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '删除计划',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  '确定删除「${plan.name}」吗？该计划的所有打卡记录都会被移除，此操作不可撤销。',
                  style: const TextStyle(
                    fontSize: 14.5,
                    height: 1.5,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('取消'),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.danger,
                      ),
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('删除'),
                    ),
                  ],
                ),
              ],
            ),
          ),
    );
    if (ok == true) {
      await ref.read(repositoryProvider).deletePlan(plan.id);
    }
  }

  Future<void> _activate(BuildContext context, WidgetRef ref) async {
    await ref.read(repositoryProvider).setActivePlan(plan.id);
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('已切换到「${plan.name}」')));
    }
  }

  void _showActions(BuildContext context, WidgetRef ref) {
    showAppSheet<void>(
      context,
      heightFactor: 0.42,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!plan.isActive)
                _ActionRow(
                  icon: Icons.check_circle_outline_rounded,
                  label: '设为当前计划',
                  onTap: () {
                    Navigator.pop(context);
                    _activate(context, ref);
                  },
                ),
              _ActionRow(
                icon: Icons.edit_outlined,
                label: '编辑',
                onTap: () {
                  Navigator.pop(context);
                  context.push('/plan/${plan.id}/edit');
                },
              ),
              _ActionRow(
                icon: Icons.delete_outline_rounded,
                label: '删除',
                color: AppColors.danger,
                onTap: () {
                  Navigator.pop(context);
                  _confirmDelete(context, ref);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalDays = AppDate.daysBetween(plan.startDate, plan.endDate) + 1;
    final passed = (AppDate.daysBetween(plan.startDate, AppDate.today()) + 1)
        .clamp(0, totalDays);
    final ratio = totalDays == 0 ? 0.0 : passed / totalDays;

    return AppCard(
      onTap: plan.isActive ? null : () => _activate(context, ref),
      border: plan.isActive ? Border.all(color: AppColors.primary, width: 1.5) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        plan.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.3,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (plan.isActive) ...[
                      const SizedBox(width: AppSpacing.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          borderRadius: AppRadius.pillAll,
                        ),
                        child: const Text(
                          '当前',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                tooltip: '更多操作',
                visualDensity: VisualDensity.compact,
                onPressed: () => _showActions(context, ref),
                icon: const Icon(
                  Icons.more_horiz_rounded,
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${AppDate.monthDay(plan.startDate)} - ${AppDate.monthDay(plan.endDate)}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  letterSpacing: -0.08,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                '已进行 $passed/$totalDays 天',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  letterSpacing: -0.08,
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _PlanProgress(ratio: ratio, active: plan.isActive),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              _weightChip(
                '起始',
                plan.startWeight,
                AppColors.primary,
                AppColors.primarySoft,
                Icons.play_arrow_rounded,
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  size: 16,
                  color: AppColors.textTertiary,
                ),
              ),
              _weightChip(
                '目标',
                plan.targetWeight,
                AppColors.successText,
                AppColors.successSoft,
                Icons.flag_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _weightChip(
    String label,
    double kg,
    Color color,
    Color bg,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: bg, borderRadius: AppRadius.pillAll),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: AppSpacing.xs),
          RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color.withValues(alpha: 0.75),
              ),
              children: [
                TextSpan(text: '$label '),
                TextSpan(
                  text: Formatters.weight(kg, unit),
                  style: TextStyle(color: color, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 6px progress bar. Accent fill for the active plan, neutral otherwise.
class _PlanProgress extends StatelessWidget {
  const _PlanProgress({required this.ratio, required this.active});
  final double ratio;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: ratio.clamp(0.0, 1.0).toDouble()),
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
                gradient: active ? AppGradients.progress : null,
                color: active ? null : AppColors.textTertiary,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final effective = color ?? AppColors.textPrimary;
    return ListTile(
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.smallAll),
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: (color ?? AppColors.primary).withValues(alpha: 0.10),
          borderRadius: AppRadius.chipAll,
        ),
        child: Icon(icon, size: 20, color: color ?? AppColors.primary),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.24,
          color: effective,
        ),
      ),
    );
  }
}
