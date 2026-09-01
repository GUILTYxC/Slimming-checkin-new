import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_glass.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/formatters.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/section_header.dart';
import 'settings_controller.dart';

/// Settings: three grouped cards of uniform rows.
///
/// Every row shares one shape (34pt icon well, 15/600 title, trailing
/// control) so the screen reads as a list rather than a set of bespoke
/// widgets. Destructive actions are the only place red appears.
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final controller = ref.read(settingsProvider.notifier);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.page,
                AppSpacing.sm,
                AppSpacing.page,
                120,
              ),
              children: [
                const _PageHeader(),
                const SizedBox(height: AppSpacing.xl),
                const SectionHeader(title: '偏好'),
                const SizedBox(height: AppSpacing.md),
                AppCard(
                  padding: const EdgeInsets.all(6),
                  child: Column(
                    children: [
                      _Row(
                        icon: Icons.straighten_rounded,
                        tint: AppColors.primary,
                        tintSoft: AppColors.primarySoft,
                        title: '体重单位',
                        trailing: _UnitToggle(
                          value: settings.weightUnit,
                          onChanged: controller.setWeightUnit,
                        ),
                      ),
                      const Divider(height: 1, indent: 46),
                      _Row(
                        icon: Icons.dark_mode_rounded,
                        tint: AppColors.textSecondary,
                        tintSoft: AppGlass.fillInset,
                        title: '跟随系统外观',
                        trailing: Switch(
                          value: settings.themeMode == ThemeMode.system,
                          onChanged:
                              (v) => controller.setThemeMode(
                                v ? ThemeMode.system : ThemeMode.light,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                const SectionHeader(title: '数据'),
                const SizedBox(height: AppSpacing.md),
                AppCard(
                  padding: const EdgeInsets.all(6),
                  child: Column(
                    children: [
                      _Row(
                        icon: Icons.ios_share_rounded,
                        tint: AppColors.primary,
                        tintSoft: AppColors.primarySoft,
                        title: '导出数据',
                        subtitle: '生成 JSON 并复制到剪贴板',
                        onTap: () => _export(context, ref),
                      ),
                      const Divider(height: 1, indent: 46),
                      _Row(
                        icon: Icons.delete_outline_rounded,
                        tint: AppColors.danger,
                        tintSoft: AppColors.dangerSoft,
                        title: '清空所有数据',
                        subtitle: '删除全部计划与打卡记录',
                        titleColor: AppColors.danger,
                        onTap: () => _clear(context, ref),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                const SectionHeader(title: '关于'),
                const SizedBox(height: AppSpacing.md),
                AppCard(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: AppRadius.smallAll,
                        ),
                        child: const Icon(Icons.eco_rounded, color: Colors.white),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '轻盈打卡',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.24,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              '版本 1.4.0 · 数据仅保存在本机',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                color: AppColors.textTertiary,
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
          ),
        ),
      ),
    );
  }

  Future<void> _export(BuildContext context, WidgetRef ref) async {
    final data = await ref.read(repositoryProvider).exportAll();
    final json = const JsonEncoder.withIndent('  ').convert(data);
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder:
          (context) => GlassDialog(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '导出数据',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 320),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      json,
                      style: const TextStyle(fontSize: 12, height: 1.4),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('关闭'),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    FilledButton.icon(
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: json));
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('已复制到剪贴板')),
                          );
                        }
                      },
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      label: const Text('复制'),
                    ),
                  ],
                ),
              ],
            ),
          ),
    );
  }

  Future<void> _clear(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder:
          (context) => GlassDialog(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '清空所有数据',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                const Text(
                  '将删除全部计划、打卡记录与任务，此操作不可撤销。确定继续吗？',
                  style: TextStyle(
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
                      child: const Text('清空'),
                    ),
                  ],
                ),
              ],
            ),
          ),
    );
    if (ok == true) {
      await ref.read(repositoryProvider).clearAll();
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('数据已清空')));
      }
    }
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Text(
        '设置',
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
          height: 1.15,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}

/// kg / 斤 segmented toggle sitting on a muted track.
class _UnitToggle extends StatelessWidget {
  const _UnitToggle({required this.value, required this.onChanged});

  final WeightUnit value;
  final ValueChanged<WeightUnit> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final u in WeightUnit.values)
            GestureDetector(
              onTap: () => onChanged(u),
              child: AnimatedContainer(
                duration: AppMotion.fast,
                curve: AppMotion.emphasized,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: value == u ? AppColors.surface : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  u.suffix,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color:
                        value == u
                            ? AppColors.primary
                            : AppColors.textTertiary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// The one row shape used by every settings entry.
class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.tint,
    required this.tintSoft,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.titleColor,
  });

  final IconData icon;
  final Color tint;
  final Color tintSoft;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? titleColor;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.smallAll,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: tintSoft,
                borderRadius: AppRadius.chipAll,
              ),
              child: Icon(icon, size: 18, color: tint),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.24,
                      color: titleColor ?? AppColors.textPrimary,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null)
              trailing!
            else if (onTap != null)
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: (titleColor ?? AppColors.textTertiary).withValues(
                  alpha: 0.7,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
