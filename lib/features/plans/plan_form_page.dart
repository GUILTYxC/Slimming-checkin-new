import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/app_date.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/task_input.dart';
import '../../shared/widgets/app_card.dart';
import '../settings/settings_controller.dart';
import '../../core/theme/app_palette.dart';

class PlanFormPage extends ConsumerStatefulWidget {
  const PlanFormPage({super.key, this.planId});

  final int? planId;

  bool get isEditing => planId != null;

  @override
  ConsumerState<PlanFormPage> createState() => _PlanFormPageState();
}

class _TaskField {
  _TaskField({
    this.id,
    String title = '',
    this.targetCount = 1,
    this.unit,
  }) : controller = TextEditingController(text: title);
  final int? id;
  final TextEditingController controller;
  int targetCount;
  String? unit;
}

class _PlanFormPageState extends ConsumerState<PlanFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _startWeightCtrl = TextEditingController();
  final _targetWeightCtrl = TextEditingController();

  DateTime _startDate = AppDate.today();
  DateTime _endDate = AppDate.addDays(AppDate.today(), 30);
  final List<_TaskField> _tasks = [];

  bool _loading = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) {
      _load();
    } else {
      _tasks.addAll([
        _TaskField(title: '喝够 8 杯水', targetCount: 8, unit: '杯'),
        _TaskField(title: '运动 30 分钟'),
      ]);
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final repo = ref.read(repositoryProvider);
    final plan = await repo.getPlan(widget.planId!);
    final tasks = await repo.getTasks(widget.planId!);
    final unit = ref.read(settingsProvider).weightUnit;
    if (plan != null) {
      _nameCtrl.text = plan.name;
      _startDate = plan.startDate;
      _endDate = plan.endDate;
      _startWeightCtrl.text = Formatters.weight(
        plan.startWeight,
        unit,
        withSuffix: false,
      );
      _targetWeightCtrl.text = Formatters.weight(
        plan.targetWeight,
        unit,
        withSuffix: false,
      );
      _tasks
        ..clear()
        ..addAll(
          tasks.map(
            (t) => _TaskField(
              id: t.id,
              title: t.title,
              targetCount: t.targetCount,
              unit: t.unit,
            ),
          ),
        );
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _startWeightCtrl.dispose();
    _targetWeightCtrl.dispose();
    for (final t in _tasks) {
      t.controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initial = isStart ? _startDate : _endDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
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
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startDate = picked.dateOnly;
        if (_endDate.isBefore(_startDate)) _endDate = _startDate;
      } else {
        _endDate = picked.dateOnly;
        if (_endDate.isBefore(_startDate)) _startDate = _endDate;
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final inputs =
        _tasks
            .where((t) => t.controller.text.trim().isNotEmpty)
            .map(
              (t) => TaskInput(
                id: t.id,
                title: t.controller.text.trim(),
                targetCount: t.targetCount,
                unit: t.unit,
              ),
            )
            .toList();
    if (inputs.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请至少添加一个每日打卡任务')));
      return;
    }

    setState(() => _saving = true);
    final repo = ref.read(repositoryProvider);
    final unit = ref.read(settingsProvider).weightUnit;
    final startKg = unit.toKg(double.parse(_startWeightCtrl.text.trim()));
    final targetKg = unit.toKg(double.parse(_targetWeightCtrl.text.trim()));

    if (widget.isEditing) {
      await repo.updatePlan(
        id: widget.planId!,
        name: _nameCtrl.text.trim(),
        startDate: _startDate,
        endDate: _endDate,
        startWeight: startKg,
        targetWeight: targetKg,
        tasks: inputs,
      );
    } else {
      await repo.createPlan(
        name: _nameCtrl.text.trim(),
        startDate: _startDate,
        endDate: _endDate,
        startWeight: startKg,
        targetWeight: targetKg,
        taskTitles: [for (final t in inputs) t.title],
        taskTargetCounts: [for (final t in inputs) t.targetCount],
        taskUnits: [for (final t in inputs) t.unit],
      );
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final unit = ref.watch(settingsProvider.select((s) => s.weightUnit));
    return Scaffold(
      appBar: AppBar(title: Text(widget.isEditing ? '编辑计划' : '新建计划')),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.page,
                    12,
                    AppSpacing.page,
                    24,
                  ),
                  children: [
                    AppCard(
                      // Form text sits under glass sheen otherwise and washes out.
                      sheen: false,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _SectionTitle(
                            icon: Icons.edit_note_rounded,
                            title: '基本信息',
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _nameCtrl,
                            textInputAction: TextInputAction.next,
                            maxLength: 60,
                            style: TextStyle(
                              color: context.palette.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: const InputDecoration(
                              hintText: '计划名称，例如：夏日轻盈计划',
                              counterText: '',
                            ),
                            validator:
                                (v) =>
                                    (v == null || v.trim().isEmpty)
                                        ? '请输入计划名称'
                                        : null,
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: _DateField(
                                  label: '开始',
                                  date: _startDate,
                                  onTap: () => _pickDate(isStart: true),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _DateField(
                                  label: '结束',
                                  date: _endDate,
                                  onTap: () => _pickDate(isStart: false),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    AppCard(
                      sheen: false,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SectionTitle(
                            icon: Icons.monitor_weight_rounded,
                            title: '体重目标 (${unit.suffix})',
                          ),
                          const SizedBox(height: 16),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _weightField(
                                  controller: _startWeightCtrl,
                                  label: '当前体重',
                                  hint: '例如 75',
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _weightField(
                                  controller: _targetWeightCtrl,
                                  label: '目标体重',
                                  hint: '例如 69',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    AppCard(
                      sheen: false,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Expanded(
                                child: _SectionTitle(
                                  icon: Icons.checklist_rounded,
                                  title: '每日打卡任务',
                                ),
                              ),
                              TextButton.icon(
                                onPressed:
                                    () => setState(
                                      () => _tasks.add(_TaskField()),
                                    ),
                                icon: const Icon(Icons.add_rounded, size: 18),
                                label: const Text('添加'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          ..._buildTaskFields(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _saving ? null : _save,
                      child:
                          _saving
                              ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                  color: Colors.white,
                                ),
                              )
                              : Text(widget.isEditing ? '保存修改' : '创建计划'),
                    ),
                  ],
                ),
              ),
    );
  }

  List<Widget> _buildTaskFields() {
    return [
      for (var i = 0; i < _tasks.length; i++)
        Padding(
          key: ObjectKey(_tasks[i]),
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Icon(
                Icons.check_circle_outline_rounded,
                color: context.palette.textTertiary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: _tasks[i].controller,
                  style: TextStyle(color: context.palette.textPrimary),
                  decoration: InputDecoration(
                    hintText: '任务 ${i + 1}',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Tooltip(
                message: '每日目标次数（1 = 勾选）',
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: context.palette.fillInset,
                    borderRadius: AppRadius.chipAll,
                  ),
                  child: DropdownButton<int>(
                    value: _tasks[i].targetCount.clamp(1, 20),
                    isDense: true,
                    style: TextStyle(
                      color: context.palette.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    dropdownColor: context.palette.surface,
                    underline: const SizedBox.shrink(),
                    items: [
                      for (final n in const [1, 2, 3, 4, 6, 8, 10, 12, 20])
                        DropdownMenuItem(value: n, child: Text('×$n')),
                    ],
                    onChanged:
                        (v) => setState(() => _tasks[i].targetCount = v ?? 1),
                  ),
                ),
              ),
              IconButton(
                onPressed:
                    _tasks.length <= 1
                        ? null
                        : () => setState(() => _tasks.removeAt(i)),
                icon: const Icon(Icons.remove_circle_outline_rounded),
                color: context.palette.textTertiary,
              ),
            ],
          ),
        ),
    ];
  }

  Widget _weightField({
    required TextEditingController controller,
    required String label,
    required String hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: context.palette.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
          style: TextStyle(
            color: context.palette.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(hintText: hint),
          validator: (v) {
            final value = double.tryParse((v ?? '').trim());
            if (value == null || value <= 0) return '请输入有效体重';
            return null;
          },
        ),
      ],
    );
  }
}

/// Card section title: small tinted icon chip next to a bold label.
class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: context.palette.primarySoft,
            borderRadius: AppRadius.chipAll,
          ),
          child: Icon(icon, size: 17, color: context.palette.primaryDark),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w800,
              color: context.palette.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.date,
    required this.onTap,
  });

  final String label;
  final DateTime date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      color: context.palette.fillInset,
      radius: 14,
      child: Row(
        children: [
          Icon(
            Icons.calendar_today_rounded,
            size: 18,
            color: context.palette.primaryDark,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: context.palette.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  // Compact so "2026年9月28日" never clips in a half-width tile.
                  '${date.month}月${date.day}日',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: context.palette.textPrimary,
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
