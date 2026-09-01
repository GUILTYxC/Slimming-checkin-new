import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_glass.dart';
import 'app_tokens.dart';

/// Builds the light Material 3 theme used across every platform.
///
/// Every scaffold is transparent: the aurora backdrop behind the app shows
/// through, and glass surfaces blur it. Chrome is deliberately quiet so
/// content and typography carry the hierarchy.
class AppTheme {
  AppTheme._();

  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      // Transparent so the aurora backdrop behind the app is what shows
      // through — glass surfaces then have something to refract.
      scaffoldBackgroundColor: Colors.transparent,
      canvasColor: Colors.transparent,
      splashFactory: InkSparkle.splashFactory,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: Colors.white,
        primaryContainer: AppColors.primaryContainer,
        onPrimaryContainer: AppColors.primaryDark,
        secondary: AppColors.weight,
        onSecondary: Colors.white,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        error: AppColors.danger,
        onError: Colors.white,
        outline: AppColors.border,
        surfaceContainerHighest: AppColors.surfaceMuted,
      ),
    );

    return base.copyWith(
      textTheme: _textTheme(base.textTheme),
      appBarTheme: const AppBarThemeData(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        iconTheme: IconThemeData(color: AppColors.textPrimary),
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: AppColors.textPrimary.withValues(alpha: 0.08),
        thickness: 1,
        space: 1,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.sheetTop),
        constraints: BoxConstraints(maxWidth: 640),
      ),
      // Pickers stay opaque: they are dense lists where a blurred backdrop
      // would cost legibility for no gain.
      datePickerTheme: const DatePickerThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
      ),
      timePickerTheme: const TimePickerThemeData(
        backgroundColor: AppColors.surface,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.largeAll),
        titleTextStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        contentTextStyle: const TextStyle(
          fontSize: 14.5,
          height: 1.5,
          color: AppColors.textSecondary,
        ),
      ),
      // Segment sits on a #F5F5F7 track supplied by the caller; the selected
      // segment is a white pill with no outline.
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          visualDensity: VisualDensity.compact,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          textStyle: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            return TextStyle(
              fontSize: 13,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            );
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            return selected ? AppColors.textPrimary : AppColors.textSecondary;
          }),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            return selected
                ? Colors.white.withValues(alpha: 0.82)
                : Colors.transparent;
          }),
          side: WidgetStateProperty.all(BorderSide.none),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: AppRadius.chipAll),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.55),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        hintStyle: const TextStyle(color: AppColors.textTertiary),
        border: OutlineInputBorder(
          borderRadius: AppRadius.smallAll,
          borderSide: AppGlass.strokeSide,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.smallAll,
          borderSide: AppGlass.strokeSide,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.smallAll,
          borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.smallAll,
          borderSide: const BorderSide(color: AppColors.danger, width: 1.4),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.smallAll,
          borderSide: const BorderSide(color: AppColors.danger, width: 1.6),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.primaryContainer,
          disabledForegroundColor: Colors.white,
          minimumSize: const Size(0, 54),
          elevation: 0,
          textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.smallAll,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          minimumSize: const Size(0, 54),
          textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
          side: AppGlass.strokeSide,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.smallAll,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: AppColors.textSecondary,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 15),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.chipAll),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppGlass.fillInset,
        selectedColor: AppColors.primarySoft,
        side: BorderSide.none,
        labelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.pillAll),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppGlass.fillInset,
        linearMinHeight: 6,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.all(Colors.white),
        trackColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected)
                  ? AppColors.primary
                  : AppColors.hairline,
        ),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
    );
  }

  static TextTheme _textTheme(TextTheme base) {
    return base
        .apply(
          bodyColor: AppColors.textPrimary,
          displayColor: AppColors.textPrimary,
        )
        .copyWith(
          // 56 — the hero metric number on the dashboard.
          displayLarge: const TextStyle(
            fontSize: 56,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.28,
            height: 1.07,
          ),
          // 28 — screen titles. Same size on every screen.
          headlineMedium: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
            height: 1.2,
          ),
          // 22 — card titles.
          titleLarge: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
            height: 1.25,
          ),
          // 17 — list row titles.
          titleMedium: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.37,
            height: 1.3,
          ),
          bodyLarge: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w400,
            letterSpacing: -0.37,
            height: 1.47,
          ),
          bodyMedium: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            letterSpacing: -0.22,
            height: 1.43,
            color: AppColors.textSecondary,
          ),
          labelLarge: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.24,
          ),
          labelMedium: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            letterSpacing: -0.08,
            color: AppColors.textSecondary,
          ),
          labelSmall: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textTertiary,
          ),
        );
  }
}
