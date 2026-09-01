import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/theme/app_glass.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/app_date.dart';
import '../../core/utils/formatters.dart';
import '../../data/database/app_database.dart';
import '../../shared/widgets/app_bottom_sheet.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/empty_state.dart';
import '../settings/settings_controller.dart';
import '../../core/theme/app_palette.dart';

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
    ).showSnackBar(const SnackBar(content: Text('打卡已保存')));
  }
}

/// Half-screen daily check-in form: weight / body-fat / calories plus the
/// plan's task checklist.
///
/// Fields are stacked cards with the label above a large value, which keeps
/// each row tappable and leaves the numbers legible at a glance.
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
                      accent: context.palette.weight,
                      accentSoft: context.palette.weightSoft,
                      label: '今日体重',
                      suffix: unit.suffix,
                      controller: _weightCtrl,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _MetricField(
                      icon: Icons.percent_rounded,
                      accent: context.palette.bodyFat,
                      accentSoft: context.palette.bodyFatSoft,
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
                accent: context.palette.calorie,
                accentSoft: context.palette.calorieSoft,
                label: '消耗',
                suffix: '千卡',
                controller: _caloriesCtrl,
                allowDecimal: false,
              ),
              if (_tasks.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xxl),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      '今日任务',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.37,
                        color: context.palette.textPrimary,
                      ),
                    ),
                    Text(
                      '$_doneCount/${_tasks.length}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: context.palette.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value:
                        _tasks.isEmpty
                            ? 0
                            : (_doneCount / _tasks.length).clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor: context.palette.fillInset,
                    valueColor: AlwaysStoppedAnimation(context.palette.primary),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                AppCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
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
                          const Divider(height: 1, indent: 46),
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
          decoration: BoxDecoration(
            color: const Color(0x8CFFFFFF),
            border: Border(top: BorderSide(color: context.palette.strokeTop, width: 1)),
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
                backgroundColor: _saved ? context.palette.success : context.palette.primary,
                disabledBackgroundColor:
                    _saved ? context.palette.success : context.palette.primaryContainer,
                disabledForegroundColor: Colors.white,
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
    final isToday = AppDate.relativeLabel(date) == '今天';
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.page,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.md,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: context.palette.primarySoft,
              borderRadius: AppRadius.smallAll,
            ),
            child: Icon(Icons.today_rounded, color: context.palette.primary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isToday ? '今日打卡' : '${AppDate.relativeLabel(date)}补记',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                    color: context.palette.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${date.month}月${date.day}日 · 周${AppDate.shortWeekday(date)}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: context.palette.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: '关闭',
            onPressed: () => Navigator.of(context).pop(),
            style: IconButton.styleFrom(backgroundColor: context.palette.fillInset),
            icon: Icon(
              Icons.close_rounded,
              color: context.palette.textSecondary,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}

/// A metric input card: label row on top, large value below.
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
        color: Colors.white.withValues(alpha: 0.55),
        borderRadius: AppRadius.smallAll,
        border: Border.all(
          color: focused ? context.palette.primary : context.palette.strokeTop,
          width: 1.6,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: widget.accentSoft,
                    borderRadius: AppRadius.chipAll,
                  ),
                  child: Icon(widget.icon, size: 16, color: widget.accent),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.08,
                    color: context.palette.textSecondary,
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
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.3,
                      height: 1.15,
                      color: context.palette.textPrimary,
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
                const SizedBox(width: AppSpacing.xs),
                Text(
                  widget.suffix,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: context.palette.textTertiary,
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
      borderRadius: AppRadius.chipAll,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 13,
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: AppMotion.fast,
              curve: AppMotion.emphasized,
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: completed ? context.palette.primary : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: completed ? context.palette.primary : context.palette.border,
                  width: 1.6,
                ),
              ),
              child:
                  completed
                      ? const Icon(
                        Icons.check_rounded,
                        size: 15,
                        color: Colors.white,
                      )
                      : null,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: AnimatedDefaultTextStyle(
                duration: AppMotion.fast,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.24,
                  color:
                      completed
                          ? context.palette.textTertiary
                          : context.palette.textPrimary,
                  decoration:
                      completed ? TextDecoration.lineThrough : null,
                  decorationColor: context.palette.textTertiary,
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
      child: GlassSurface(
        thickness: GlassThickness.thick,
        radius: AppRadius.large,
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: context.palette.successSoft,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_rounded,
                  color: context.palette.successText,
                  size: 34,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                '今日任务全部完成',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                  color: context.palette.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '坚持就是胜利，继续加油',
                style: TextStyle(
                  fontSize: 13.5,
                  color: context.palette.textSecondary,
                ),
              ),
            ],
          ),
      ),
    );
  }
}
