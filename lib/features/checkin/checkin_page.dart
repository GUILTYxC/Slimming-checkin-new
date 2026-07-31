import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/app_date.dart';
import '../../core/utils/formatters.dart';
import '../../data/database/app_database.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/empty_state.dart';
import '../settings/settings_controller.dart';

class CheckInPage extends ConsumerStatefulWidget {
  const CheckInPage({super.key, this.planId, this.date});

  final int? planId;
  final DateTime? date;

  @override
  ConsumerState<CheckInPage> createState() => _CheckInPageState();
}

class _CheckInPageState extends ConsumerState<CheckInPage> {
  final _weightCtrl = TextEditingController();
  final _caloriesCtrl = TextEditingController();

  late final DateTime _date = (widget.date ?? DateTime.now()).dateOnly;

  int? _planId;
  List<PlanTask> _tasks = const [];
  final Map<int, bool> _completed = {};

  bool _loading = true;
  bool _noPlan = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final repo = ref.read(repositoryProvider);
    var planId = widget.planId;
    planId ??= (await repo.watchActivePlan().first)?.id;

    if (planId == null) {
      setState(() {
        _noPlan = true;
        _loading = false;
      });
      return;
    }

    final tasks = await repo.getTasks(planId);
    final record = await repo.getRecord(planId, _date);
    final logs = await repo.getTaskLogs(planId, _date);
    final unit = ref.read(settingsProvider).weightUnit;

    _planId = planId;
    _tasks = tasks;
    for (final t in tasks) {
      _completed[t.id] = logs
          .any((l) => l.taskId == t.id && l.completed);
    }
    if (record?.weight != null) {
      _weightCtrl.text =
          Formatters.weight(record!.weight!, unit, withSuffix: false);
    }
    if (record != null && record.caloriesBurned > 0) {
      _caloriesCtrl.text = record.caloriesBurned.round().toString();
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    _caloriesCtrl.dispose();
    super.dispose();
  }

  int get _doneCount => _completed.values.where((v) => v).length;

  Future<void> _toggle(PlanTask task) async {
    final next = !(_completed[task.id] ?? false);
    setState(() => _completed[task.id] = next);
    await ref.read(repositoryProvider).setTaskCompletion(
          planId: _planId!,
          taskId: task.id,
          date: _date,
          completed: next,
        );
    if (next && _tasks.isNotEmpty && _doneCount == _tasks.length) {
      _celebrate();
    }
  }

  Future<void> _save() async {
    final repo = ref.read(repositoryProvider);
    final unit = ref.read(settingsProvider).weightUnit;

    final weightText = _weightCtrl.text.trim();
    double? weightKg;
    if (weightText.isNotEmpty) {
      final v = double.tryParse(weightText);
      if (v == null || v <= 0) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('请输入有效体重')));
        return;
      }
      weightKg = unit.toKg(v);
    }
    final calories = double.tryParse(_caloriesCtrl.text.trim()) ?? 0;

    setState(() => _saving = true);
    await repo.upsertRecord(
      planId: _planId!,
      date: _date,
      weight: weightKg,
      caloriesBurned: calories,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('打卡已保存 ✓')));
    Navigator.of(context).pop();
  }

  void _celebrate() {
    HapticFeedback.mediumImpact();
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.25),
      builder: (_) => const _CelebrationDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final unit = ref.watch(settingsProvider.select((s) => s.weightUnit));
    return Scaffold(
      appBar: AppBar(title: const Text('每日打卡')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _noPlan
              ? const EmptyState(
                  icon: Icons.flag_rounded,
                  title: '还没有计划',
                  message: '请先在「计划」中创建一个减肥计划，再来打卡。',
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
                  children: [
                    _DateBanner(date: _date),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _MetricField(
                            icon: Icons.monitor_weight_rounded,
                            accent: AppColors.weight,
                            accentSoft: AppColors.weightSoft,
                            label: '今日体重',
                            suffix: unit.suffix,
                            controller: _weightCtrl,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _MetricField(
                            icon: Icons.local_fire_department_rounded,
                            accent: AppColors.calorie,
                            accentSoft: AppColors.calorieSoft,
                            label: '消耗',
                            suffix: '千卡',
                            controller: _caloriesCtrl,
                            allowDecimal: false,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (_tasks.isNotEmpty) ...[
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              '今日任务',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          Text(
                            '$_doneCount/${_tasks.length}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      AppCard(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 4),
                        child: Column(
                          children: [
                            for (var i = 0; i < _tasks.length; i++) ...[
                              _TaskRow(
                                title: _tasks[i].title,
                                completed: _completed[_tasks[i].id] ?? false,
                                onTap: () => _toggle(_tasks[i]),
                              ),
                              if (i != _tasks.length - 1)
                                const Divider(height: 1, indent: 52),
                            ],
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 28),
                    FilledButton(
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                color: Colors.white,
                              ),
                            )
                          : const Text('保存打卡'),
                    ),
                  ],
                ),
    );
  }
}

class _DateBanner extends StatelessWidget {
  const _DateBanner({required this.date});
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: AppColors.primarySoft,
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.today_rounded,
                color: AppColors.primaryDark),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppDate.relativeLabel(date),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                AppDate.pretty(date),
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricField extends StatelessWidget {
  const _MetricField({
    required this.icon,
    required this.accent,
    required this.accentSoft,
    required this.label,
    required this.suffix,
    required this.controller,
    this.allowDecimal = true,
  });

  final IconData icon;
  final Color accent;
  final Color accentSoft;
  final String label;
  final String suffix;
  final TextEditingController controller;
  final bool allowDecimal;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: accentSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 19, color: accent),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.numberWithOptions(
                      decimal: allowDecimal),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(allowDecimal ? r'[0-9.]' : r'[0-9]'),
                    ),
                  ],
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                  decoration: const InputDecoration(
                    isCollapsed: true,
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    hintText: '0',
                  ),
                ),
              ),
              Text(
                suffix,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textTertiary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TaskRow extends StatelessWidget {
  const _TaskRow({
    required this.title,
    required this.completed,
    required this.onTap,
  });

  final String title;
  final bool completed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: completed ? AppColors.primary : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: completed ? AppColors.primary : AppColors.border,
                  width: 2,
                ),
              ),
              child: completed
                  ? const Icon(Icons.check_rounded,
                      size: 18, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 220),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: completed
                      ? AppColors.textTertiary
                      : AppColors.textPrimary,
                  decoration:
                      completed ? TextDecoration.lineThrough : null,
                  decorationColor: AppColors.textTertiary,
                ),
                child: Text(title),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CelebrationDialog extends StatefulWidget {
  const _CelebrationDialog();

  @override
  State<_CelebrationDialog> createState() => _CelebrationDialogState();
}

class _CelebrationDialogState extends State<_CelebrationDialog> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 1700), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x1F1A1D1F), blurRadius: 40, offset: Offset(0, 12)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🎉', style: TextStyle(fontSize: 56))
                  .animate()
                  .scale(
                    duration: 500.ms,
                    curve: Curves.elasticOut,
                    begin: const Offset(0.3, 0.3),
                    end: const Offset(1, 1),
                  ),
              const SizedBox(height: 14),
              const Text(
                '今日任务全部完成！',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ).animate(delay: 150.ms).fadeIn().slideY(begin: 0.4, end: 0),
              const SizedBox(height: 6),
              const Text(
                '坚持就是胜利，继续加油 💪',
                style: TextStyle(fontSize: 13.5, color: AppColors.textSecondary),
              ).animate(delay: 260.ms).fadeIn(),
            ],
          ),
        ),
      ),
    );
  }
}
