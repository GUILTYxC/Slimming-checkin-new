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
  _TaskField({this.id, String title = ''})
    : controller = TextEditingController(text: title);
  final int? id;
  final TextEditingController controller;
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
        _TaskField(title: '喝够 8 杯水'),
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
        ..addAll(tasks.map((t) => _TaskField(id: t.id, title: t.title)));
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
    final titles =
        _tasks
            .map((t) => t.controller.text.trim())
            .where((t) => t.isNotEmpty)
            .toList();
    if (titles.isEmpty) {
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
      final inputs =
          _tasks
              .where((t) => t.controller.text.trim().isNotEmpty)
              .map((t) => TaskInput(id: t.id, title: t.controller.text.trim()))
              .toList();
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
        taskTitles: titles,
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
                            decoration: const InputDecoration(
                              hintText: '计划名称，例如：夏日轻盈计划',
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SectionTitle(
                            icon: Icons.monitor_weight_rounded,
                            title: '体重目标 (${unit.suffix})',
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _weightField(
                                  controller: _startWeightCtrl,
                                  hint: '当前体重',
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _weightField(
                                  controller: _targetWeightCtrl,
                                  hint: '目标体重',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    AppCard(
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
                Icons.drag_indicator_rounded,
                color: context.palette.textTertiary,
                size: 20,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: TextFormField(
                  controller: _tasks[i].controller,
                  decoration: InputDecoration(
                    hintText: '任务 ${i + 1}',
                    isDense: true,
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
    required String hint,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
      decoration: InputDecoration(hintText: hint),
      validator: (v) {
        final value = double.tryParse((v ?? '').trim());
        if (value == null || value <= 0) return '请输入有效体重';
        return null;
      },
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
          Column(
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
                AppDate.pretty(date),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
