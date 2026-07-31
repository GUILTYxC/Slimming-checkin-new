import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/app_date.dart';
import '../../core/utils/formatters.dart';
import '../../data/database/app_database.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/empty_state.dart';
import '../settings/settings_controller.dart';

class PlansPage extends ConsumerWidget {
  const PlansPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plansAsync = ref.watch(plansProvider);
    final unit = ref.watch(settingsProvider.select((s) => s.weightUnit));

    return Scaffold(
      appBar: AppBar(
        title: const Text('我的计划'),
        actions: [
          IconButton(
            tooltip: '新建计划',
            onPressed: () => context.push('/plan/new'),
            icon: const Icon(Icons.add_rounded),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: plansAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('出错了：$e')),
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
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 100),
            itemCount: plans.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (context, i) => _PlanCard(plan: plans[i], unit: unit)
                .animate(delay: (50 * i).ms)
                .fadeIn(duration: 340.ms)
                .slideY(begin: 0.08, end: 0, curve: Curves.easeOutCubic),
          );
        },
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
      builder: (context) => AlertDialog(
        title: const Text('删除计划'),
        content: Text('确定删除「${plan.name}」吗？该计划的所有打卡记录都会被移除，此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(repositoryProvider).deletePlan(plan.id);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppCard(
      onTap: plan.isActive
          ? null
          : () => ref.read(repositoryProvider).setActivePlan(plan.id),
      border: plan.isActive
          ? Border.all(color: AppColors.primary, width: 1.6)
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (plan.isActive) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          '当前',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_horiz_rounded,
                    color: AppColors.textTertiary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                onSelected: (v) {
                  switch (v) {
                    case 'active':
                      ref.read(repositoryProvider).setActivePlan(plan.id);
                    case 'edit':
                      context.push('/plan/${plan.id}/edit');
                    case 'delete':
                      _confirmDelete(context, ref);
                  }
                },
                itemBuilder: (context) => [
                  if (!plan.isActive)
                    const PopupMenuItem(
                      value: 'active',
                      child: _MenuRow(Icons.check_circle_outline_rounded, '设为当前'),
                    ),
                  const PopupMenuItem(
                    value: 'edit',
                    child: _MenuRow(Icons.edit_outlined, '编辑'),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: _MenuRow(Icons.delete_outline_rounded, '删除',
                        color: AppColors.danger),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.calendar_today_rounded,
                  size: 14, color: AppColors.textTertiary),
              const SizedBox(width: 6),
              Text(
                '${AppDate.monthDay(plan.startDate)} - ${AppDate.monthDay(plan.endDate)}',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '共 ${AppDate.daysBetween(plan.startDate, plan.endDate) + 1} 天',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _weightChip('起始', plan.startWeight, AppColors.weight,
                  AppColors.weightSoft),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Icon(Icons.arrow_forward_rounded,
                    size: 18, color: AppColors.textTertiary),
              ),
              _weightChip('目标', plan.targetWeight, AppColors.primaryDark,
                  AppColors.primarySoft),
            ],
          ),
        ],
      ),
    );
  }

  Widget _weightChip(String label, double kg, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label ',
            style: TextStyle(fontSize: 12, color: color.withValues(alpha: 0.8)),
          ),
          Text(
            Formatters.weight(kg, unit),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow(this.icon, this.label, {this.color});
  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color ?? AppColors.textSecondary),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(color: color ?? AppColors.textPrimary)),
      ],
    );
  }
}
