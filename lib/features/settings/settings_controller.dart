import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/providers.dart';
import '../../core/utils/formatters.dart';

class AppSettings {
  const AppSettings({
    this.weightUnit = WeightUnit.kg,
    this.themeMode = ThemeMode.light,
  });

  final WeightUnit weightUnit;
  final ThemeMode themeMode;

  AppSettings copyWith({WeightUnit? weightUnit, ThemeMode? themeMode}) =>
      AppSettings(
        weightUnit: weightUnit ?? this.weightUnit,
        themeMode: themeMode ?? this.themeMode,
      );
}

class SettingsController extends Notifier<AppSettings> {
  static const _unitKey = 'settings.weightUnit';
  static const _themeKey = 'settings.themeMode';

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  AppSettings build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final unit = prefs.getString(_unitKey) == WeightUnit.lb.name
        ? WeightUnit.lb
        : WeightUnit.kg;
    final theme = prefs.getString(_themeKey) == ThemeMode.system.name
        ? ThemeMode.system
        : ThemeMode.light;
    return AppSettings(weightUnit: unit, themeMode: theme);
  }

  Future<void> setWeightUnit(WeightUnit unit) async {
    state = state.copyWith(weightUnit: unit);
    await _prefs.setString(_unitKey, unit.name);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await _prefs.setString(_themeKey, mode.name);
  }
}

final settingsProvider =
    NotifierProvider<SettingsController, AppSettings>(SettingsController.new);
