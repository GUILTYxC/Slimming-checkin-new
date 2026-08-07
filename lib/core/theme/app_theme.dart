import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_tokens.dart';

/// Builds the light Material 3 theme used across every platform.
class AppTheme {
  AppTheme._();

  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.background,
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
      ),
    );

    return base.copyWith(
      textTheme: _textTheme(base.textTheme),
      appBarTheme: const AppBarThemeData(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        iconTheme: IconThemeData(color: AppColors.textPrimary),
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.sheetTop),
        constraints: BoxConstraints(maxWidth: 640),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.largeAll),
        titleTextStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
        ),
        contentTextStyle: const TextStyle(
          fontSize: 14.5,
          height: 1.5,
          color: AppColors.textSecondary,
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          visualDensity: VisualDensity.compact,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          textStyle: WidgetStateProperty.all(
            const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            return selected ? AppColors.primaryDark : AppColors.textSecondary;
          }),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            return selected ? AppColors.primarySoft : Colors.transparent;
          }),
          side: WidgetStateProperty.all(BorderSide.none),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: AppRadius.chipAll),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: AppColors.surfaceMuted,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        hintStyle: const TextStyle(color: AppColors.textTertiary),
        border: OutlineInputBorder(
          borderRadius: AppRadius.smallAll,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.smallAll,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.smallAll,
          borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.smallAll,
          borderSide: const BorderSide(color: AppColors.danger, width: 1.4),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 54),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryDark,
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.chipAll),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceMuted,
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.chipAll),
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
          headlineMedium: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
          titleLarge: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
          titleMedium: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
          bodyMedium: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
          labelLarge: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        );
  }
}
