import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/app_date.dart';
import '../../core/utils/formatters.dart';
import '../../data/database/app_database.dart';
import '../../shared/widgets/app_bottom_sheet.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/empty_state.dart';
import '../settings/settings_controller.dart';

/// Opens the daily check-in form as a modal bottom sheet and shows a light
/// confirmation when the record was saved.
Future<void> showCheckInSheet(
  BuildContext context, {
  int? planId,
  DateTime? date,
}) async {
  final saved = await showAppSheet<bool>(
    context,
    child: CheckInSheet(planId: planId, date: date),
  );
  if (saved == true && context.mounted) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('打卡已保存 ✓')));
  }
}

/// Half-screen daily check-in form: weight / body-fat / calories plus the
/// plan's task checklist. Replaces the old full-screen check-in page.
class CheckInSheet extends ConsumerStatefulWidget {
  const CheckInSheet({super.key, this.planId, this.date});

  final int? planId;
  final DateTime? date;

  @override
  ConsumerState<CheckInSheet> createState() => _CheckInSheetState();
}

class _CheckInSheetState extends ConsumerState<CheckInSheet> {
  final _weightCtrl = TextEditingController();
  final _bodyFatCtrl = TextEditingController();
  final _caloriesCtrl = TextEditingController();

  late final DateTime _date = (widget.date ?? DateTime.now()).dateOnly;

  int? _planId;
  List<PlanTask> _tasks = const [];
  final Map<int, bool> _completed = {};

  bool _loading = true;
  bool _noPlan = false;
  bool _saving = false;
  bool _saved = false;

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
      _completed[t.id] = logs.any((l) => l.taskId == t.id && l.completed);
    }
    if (record?.weight != null) {
      _weightCtrl.text = Formatters.weight(
        record!.weight!,
        unit,
        withSuffix: false,
      );
    }
    if (record?.bodyFat != null) {
      _bodyFatCtrl.text = Formatters.bodyFat(
        record!.bodyFat!,
        withSuffix: false,
      );
    }
    if (record != null && record.caloriesBurned > 0) {
      _caloriesCtrl.text = record.caloriesBurned.round().toString();
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    _bodyFatCtrl.dispose();
    _caloriesCtrl.dispose();
    super.dispose();
  }

  int get _doneCount => _completed.values.where((v) => v).length;

  Future<void> _toggle(PlanTask task) async {
    final next = !(_completed[task.id] ?? false);
    HapticFeedback.selectionClick();
    setState(() => _completed[task.id] = next);
    await ref
        .read(repositoryProvider)
        .setTaskCompletion(
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('请输入有效体重')));
        return;
      }
      weightKg = unit.toKg(v);
    }
    final bodyFatText = _bodyFatCtrl.text.trim();
    double? bodyFat;
    if (bodyFatText.isNotEmpty) {
      final v = double.tryParse(bodyFatText);
      if (v == null || v <= 0 || v >= 100) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('请输入有效体脂率（0–100）')));
        return;
      }
      bodyFat = v;
    }
    final calories = double.tryParse(_caloriesCtrl.text.trim()) ?? 0;

    setState(() => _saving = true);
    await repo.upsertRecord(
      planId: _planId!,
      date: _date,
      weight: weightKg,
      bodyFat: bodyFat,
      caloriesBurned: calories,
    );
    if (!mounted) return;
    // Let the button morph into a checkmark before the sheet slides away.
    setState(() {
      _saving = false;
      _saved = true;
    });
    HapticFeedback.mediumImpact();
    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (mounted) Navigator.of(context).pop(true);
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

    if (_loading) {
      return const SizedBox(
        height: 320,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_noPlan) {
      return const SizedBox(
        height: 360,
        child: EmptyState(
          icon: Icons.flag_rounded,
          title: '还没有计划',
          message: '请先在「计划」中创建一个减肥计划，再来打卡。',
        ),
      );
    }

    return Column(
      children: [
        _SheetHeader(date: _date),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.page,
              AppSpacing.xs,
              AppSpacing.page,
              AppSpacing.lg,
            ),
            children: [
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
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _MetricField(
                      icon: Icons.percent_rounded,
                      accent: AppColors.bodyFat,
                      accentSoft: AppColors.bodyFatSoft,
                      label: '体脂率',
                      suffix: '%',
                      controller: _bodyFatCtrl,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _MetricField(
                icon: Icons.local_fire_department_rounded,
                accent: AppColors.calorie,
                accentSoft: AppColors.calorieSoft,
                label: '消耗',
                suffix: '千卡',
                controller: _caloriesCtrl,
                allowDecimal: false,
              ),
              if (_tasks.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xl),
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
                const SizedBox(height: AppSpacing.sm),
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: LinearProgressIndicator(
                    value:
                        _tasks.isEmpty
                            ? 0
                            : (_doneCount / _tasks.length).clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor: AppColors.surfaceMuted,
                    valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                AppCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 4,
                  ),
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
            ],
          ),
        ),
        // Pinned save bar.
        Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.divider)),
          ),
          padding: EdgeInsets.fromLTRB(
            AppSpacing.page,
            AppSpacing.md,
            AppSpacing.page,
            AppSpacing.md + MediaQuery.of(context).padding.bottom,
          ),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: (_saving || _saved) ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: _saved ? AppColors.success : AppColors.primary,
                disabledBackgroundColor:
                    _saved ? AppColors.success : AppColors.primaryContainer,
              ),
              child: AnimatedSwitcher(
                duration: AppMotion.fast,
                child:
                    _saving
                        ? const SizedBox(
                          key: ValueKey('saving'),
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Colors.white,
                          ),
                        )
                        : _saved
                        ? const Icon(
                          key: ValueKey('saved'),
                          Icons.check_rounded,
                          size: 26,
                        )
                        : const Text(key: ValueKey('idle'), '保存打卡'),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({required this.date});
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.page,
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.md,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: AppRadius.smallAll,
            ),
            child: const Icon(
              Icons.today_rounded,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppDate.relativeLabel(date) == '今天'
                      ? '今日打卡'
                      : '${AppDate.relativeLabel(date)}补记',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${AppDate.pretty(date)} · 周${AppDate.shortWeekday(date)}',
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: '关闭',
            onPressed: () => Navigator.of(context).pop(),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.surfaceMuted,
            ),
            icon: const Icon(
              Icons.close_rounded,
              color: AppColors.textSecondary,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricField extends StatefulWidget {
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
  State<_MetricField> createState() => _MetricFieldState();
}

class _MetricFieldState extends State<_MetricField> {
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final focused = _focus.hasFocus;
    return AnimatedContainer(
      duration: AppMotion.fast,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.cardAll,
        boxShadow: AppShadows.soft,
        border: Border.all(
          color: focused ? AppColors.primary : Colors.transparent,
          width: 1.6,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: widget.accentSoft,
                    borderRadius: AppRadius.chipAll,
                  ),
                  child: Icon(widget.icon, size: 19, color: widget.accent),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  widget.label,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Expanded(
                  child: TextField(
                    controller: widget.controller,
                    focusNode: _focus,
                    keyboardType: TextInputType.numberWithOptions(
                      decimal: widget.allowDecimal,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(widget.allowDecimal ? r'[0-9.]' : r'[0-9]'),
                      ),
                    ],
                    style: const TextStyle(
                      fontSize: 30,
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
                  widget.suffix,
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
      borderRadius: BorderRadius.circular(AppRadius.chip),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 14,
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: AppMotion.fast,
              curve: AppMotion.emphasized,
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
              child:
                  completed
                      ? const Icon(
                        Icons.check_rounded,
                        size: 18,
                        color: Colors.white,
                      ).animate().scale(
                        duration: AppMotion.normal,
                        curve: AppMotion.spring,
                      )
                      : null,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: AnimatedDefaultTextStyle(
                duration: AppMotion.fast,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color:
                      completed
                          ? AppColors.textTertiary
                          : AppColors.textPrimary,
                  decoration: completed ? TextDecoration.lineThrough : null,
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
            borderRadius: AppRadius.largeAll,
            boxShadow: const [
              BoxShadow(
                color: Color(0x1F1A1D1F),
                blurRadius: 40,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🎉', style: TextStyle(fontSize: 56)).animate().scale(
                duration: AppMotion.slow,
                curve: AppMotion.spring,
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
                style: TextStyle(
                  fontSize: 13.5,
                  color: AppColors.textSecondary,
                ),
              ).animate(delay: 260.ms).fadeIn(),
            ],
          ),
        ),
      ),
    );
  }
}
