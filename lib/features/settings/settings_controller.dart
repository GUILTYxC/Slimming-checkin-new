import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/providers.dart';
import '../../core/utils/formatters.dart';

class AppSettings {
  const AppSettings({
    this.weightUnit = WeightUnit.kg,
    this.themeMode = ThemeMode.light,
    this.reminderEnabled = false,
    this.reminderHour = 20,
    this.reminderMinute = 0,
  });

  final WeightUnit weightUnit;
  final ThemeMode themeMode;
  final bool reminderEnabled;
  final int reminderHour;
  final int reminderMinute;

  AppSettings copyWith({
    WeightUnit? weightUnit,
    ThemeMode? themeMode,
    bool? reminderEnabled,
    int? reminderHour,
    int? reminderMinute,
  }) => AppSettings(
    weightUnit: weightUnit ?? this.weightUnit,
    themeMode: themeMode ?? this.themeMode,
    reminderEnabled: reminderEnabled ?? this.reminderEnabled,
    reminderHour: reminderHour ?? this.reminderHour,
    reminderMinute: reminderMinute ?? this.reminderMinute,
  );
}

class SettingsController extends Notifier<AppSettings> {
  static const _unitKey = 'settings.weightUnit';
  static const _themeKey = 'settings.themeMode';
  static const _reminderKey = 'settings.reminderEnabled';
  static const _reminderHourKey = 'settings.reminderHour';
  static const _reminderMinuteKey = 'settings.reminderMinute';

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  AppSettings build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final unit =
        prefs.getString(_unitKey) == WeightUnit.lb.name
            ? WeightUnit.lb
            : WeightUnit.kg;
    final stored = prefs.getString(_themeKey);
    final ThemeMode theme;
    if (stored == ThemeMode.dark.name) {
      theme = ThemeMode.dark;
    } else if (stored == ThemeMode.system.name) {
      theme = ThemeMode.system;
    } else {
      theme = ThemeMode.light;
    }
    return AppSettings(
      weightUnit: unit,
      themeMode: theme,
      reminderEnabled: prefs.getBool(_reminderKey) ?? false,
      reminderHour: prefs.getInt(_reminderHourKey) ?? 20,
      reminderMinute: prefs.getInt(_reminderMinuteKey) ?? 0,
    );
  }

  Future<void> setWeightUnit(WeightUnit unit) async {
    state = state.copyWith(weightUnit: unit);
    await _prefs.setString(_unitKey, unit.name);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await _prefs.setString(_themeKey, mode.name);
  }

  Future<void> setReminder({
    required bool enabled,
    int? hour,
    int? minute,
  }) async {
    state = state.copyWith(
      reminderEnabled: enabled,
      reminderHour: hour,
      reminderMinute: minute,
    );
    await _prefs.setBool(_reminderKey, enabled);
    if (hour != null) await _prefs.setInt(_reminderHourKey, hour);
    if (minute != null) await _prefs.setInt(_reminderMinuteKey, minute);
  }
}

final settingsProvider = NotifierProvider<SettingsController, AppSettings>(
  SettingsController.new,
);
