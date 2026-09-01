import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_glass.dart';

/// The app's colours **resolved for the current brightness**.
///
/// [AppColors] and [AppColorsDark] are static tables; neither knows anything
/// about the theme that is actually on screen. A widget that reads
/// `AppColors.textPrimary` therefore gets near-black ink even when the app is
/// in dark mode, which is invisible on a black canvas.
///
/// Widgets should read colours through [AppPaletteX.palette] instead:
///
/// ```dart
/// final c = context.palette;
/// Text('体重', style: TextStyle(color: c.textSecondary));
/// ```
///
/// The two palettes expose exactly the same field names, so a screen can be
/// written once and be correct in both appearances. Adding a colour here is
/// the only step needed to make a surface theme-aware.
class AppPalette {
  const AppPalette({
    required this.canvas,
    required this.surface,
    required this.surfaceMuted,
    required this.background,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.textQuaternary,
    required this.hairline,
    required this.divider,
    required this.border,
    required this.primary,
    required this.primaryFocus,
    required this.primaryDark,
    required this.primarySoft,
    required this.primaryContainer,
    required this.success,
    required this.successText,
    required this.successSoft,
    required this.warning,
    required this.warningSoft,
    required this.danger,
    required this.dangerSoft,
    required this.weight,
    required this.weightSoft,
    required this.calorie,
    required this.calorieSoft,
    required this.bodyFat,
    required this.bodyFatSoft,
    required this.fillInset,
    required this.fillInsetThick,
    required this.strokeTop,
  });

  final Color canvas;
  final Color surface;
  final Color surfaceMuted;
  final Color background;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color textQuaternary;
  final Color hairline;
  final Color divider;
  final Color border;
  final Color primary;
  final Color primaryFocus;
  final Color primaryDark;
  final Color primarySoft;
  final Color primaryContainer;
  final Color success;
  final Color successText;
  final Color successSoft;
  final Color warning;
  final Color warningSoft;
  final Color danger;
  final Color dangerSoft;
  final Color weight;
  final Color weightSoft;
  final Color calorie;
  final Color calorieSoft;
  final Color bodyFat;
  final Color bodyFatSoft;

  /// Inset wells inside a glass pane — chips, icon wells, progress tracks.
  final Color fillInset;

  /// Inset wells on floating chrome, where the backdrop is busier.
  final Color fillInsetThick;

  /// Bright edge of a glass pane, for surfaces drawing their own stroke.
  final Color strokeTop;

  static const AppPalette light = AppPalette(
    canvas: AppColors.canvas,
    surface: AppColors.surface,
    surfaceMuted: AppColors.surfaceMuted,
    background: AppColors.background,
    textPrimary: AppColors.textPrimary,
    textSecondary: AppColors.textSecondary,
    textTertiary: AppColors.textTertiary,
    textQuaternary: AppColors.textQuaternary,
    hairline: AppColors.hairline,
    divider: AppColors.divider,
    border: AppColors.border,
    primary: AppColors.primary,
    primaryFocus: AppColors.primaryFocus,
    primaryDark: AppColors.primaryDark,
    primarySoft: AppColors.primarySoft,
    primaryContainer: AppColors.primaryContainer,
    success: AppColors.success,
    successText: AppColors.successText,
    successSoft: AppColors.successSoft,
    warning: AppColors.warning,
    warningSoft: AppColors.warningSoft,
    danger: AppColors.danger,
    dangerSoft: AppColors.dangerSoft,
    weight: AppColors.weight,
    weightSoft: AppColors.weightSoft,
    calorie: AppColors.calorie,
    calorieSoft: AppColors.calorieSoft,
    bodyFat: AppColors.bodyFat,
    bodyFatSoft: AppColors.bodyFatSoft,
    fillInset: AppGlass.fillInset,
    fillInsetThick: AppGlass.fillInsetThick,
    strokeTop: AppGlass.strokeTop,
  );

  static const AppPalette dark = AppPalette(
    canvas: AppColorsDark.canvas,
    surface: AppColorsDark.surface,
    surfaceMuted: AppColorsDark.surfaceMuted,
    background: AppColorsDark.background,
    textPrimary: AppColorsDark.textPrimary,
    textSecondary: AppColorsDark.textSecondary,
    textTertiary: AppColorsDark.textTertiary,
    textQuaternary: AppColorsDark.textQuaternary,
    hairline: AppColorsDark.hairline,
    divider: AppColorsDark.divider,
    border: AppColorsDark.border,
    primary: AppColorsDark.primary,
    primaryFocus: AppColorsDark.primaryFocus,
    primaryDark: AppColorsDark.primaryDark,
    primarySoft: AppColorsDark.primarySoft,
    primaryContainer: AppColorsDark.primaryContainer,
    success: AppColorsDark.success,
    successText: AppColorsDark.successText,
    successSoft: AppColorsDark.successSoft,
    warning: AppColorsDark.warning,
    warningSoft: AppColorsDark.warningSoft,
    danger: AppColorsDark.danger,
    dangerSoft: AppColorsDark.dangerSoft,
    weight: AppColorsDark.weight,
    weightSoft: AppColorsDark.weightSoft,
    calorie: AppColorsDark.calorie,
    calorieSoft: AppColorsDark.calorieSoft,
    bodyFat: AppColorsDark.bodyFat,
    bodyFatSoft: AppColorsDark.bodyFatSoft,
    fillInset: AppGlassDark.fillInset,
    fillInsetThick: AppGlassDark.fillInsetThick,
    strokeTop: AppGlassDark.edgeLight.colors.first,
  );
}

/// Resolves the palette for the theme currently on screen.
extension AppPaletteX on BuildContext {
  AppPalette get palette =>
      Theme.of(this).brightness == Brightness.dark
          ? AppPalette.dark
          : AppPalette.light;
}
