import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_glass.dart';
import 'app_tokens.dart';

/// Builds the Material 3 themes used across every platform.
///
/// Every scaffold is transparent: the aurora backdrop behind the app shows
/// through, and glass surfaces blur it. Chrome is deliberately quiet so
/// content and typography carry the hierarchy.
///
/// Light and dark are produced by the same builder with different colour
/// resolutions, so the two can never drift apart structurally — only the
/// palette differs. See [AppColorsDark] for the two rules that make dark
/// mode more than a recolour.
class AppTheme {
  AppTheme._();

  static ThemeData light() => _build(dark: false);

  static ThemeData dark() => _build(dark: true);

  static ThemeData _build({required bool dark}) {
    // Resolve the palette once. Everything below reads from these, so adding
    // a dark value to AppColorsDark is enough to switch a whole surface.
    final surface = dark ? AppColorsDark.surface : AppColors.surface;
    final surfaceMuted = dark
        ? AppColorsDark.surfaceMuted
        : AppColors.surfaceMuted;
    final textPrimary = dark ? AppColorsDark.textPrimary : AppColors.textPrimary;
    final textSecondary = dark
        ? AppColorsDark.textSecondary
        : AppColors.textSecondary;
    final textTertiary = dark
        ? AppColorsDark.textTertiary
        : AppColors.textTertiary;
    final border = dark ? AppColorsDark.border : AppColors.border;
    final primary = dark ? AppColorsDark.primary : AppColors.primary;
    final primaryDark = dark ? AppColorsDark.primaryDark : AppColors.primaryDark;
    final primaryContainer = dark
        ? AppColorsDark.primaryContainer
        : AppColors.primaryContainer;
    final primarySoft = dark ? AppColorsDark.primarySoft : AppColors.primarySoft;
    final danger = dark ? AppColorsDark.danger : AppColors.danger;
    final weight = dark ? AppColorsDark.weight : AppColors.weight;
    final fillInset = dark ? AppGlassDark.fillInset : AppGlass.fillInset;
    final strokeSide = dark ? AppGlassDark.strokeSide : AppGlass.strokeSide;

    final base = ThemeData(
      useMaterial3: true,
      brightness: dark ? Brightness.dark : Brightness.light,
      // Transparent so the aurora backdrop behind the app is what shows
      // through — glass surfaces then have something to refract.
      scaffoldBackgroundColor: Colors.transparent,
      canvasColor: Colors.transparent,
      splashFactory: InkSparkle.splashFactory,
      colorScheme: ColorScheme(
        brightness: dark ? Brightness.dark : Brightness.light,
        primary: primary,
        onPrimary: Colors.white,
        primaryContainer: primaryContainer,
        onPrimaryContainer: primaryDark,
        secondary: weight,
        onSecondary: Colors.white,
        surface: surface,
        onSurface: textPrimary,
        error: danger,
        onError: Colors.white,
        outline: border,
        surfaceContainerHighest: surfaceMuted,
      ),
    );

    return base.copyWith(
      textTheme: _textTheme(base.textTheme, dark: dark),
      appBarTheme: AppBarThemeData(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        // Status bar content flips: dark ink on a light canvas, light ink on
        // a black one.
        systemOverlayStyle: dark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        iconTheme: IconThemeData(color: textPrimary),
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: textPrimary.withValues(alpha: dark ? 0.12 : 0.08),
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
      datePickerTheme: DatePickerThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
      ),
      timePickerTheme: TimePickerThemeData(backgroundColor: surface),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.largeAll),
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        contentTextStyle: TextStyle(
          fontSize: 14.5,
          height: 1.5,
          color: textSecondary,
        ),
      ),
      // Segment sits on a track supplied by the caller; the selected segment
      // is a translucent pill that *lifts* off the track — white in light
      // mode, a faint white wash in dark mode, where an opaque pill would
      // punch a hole in the glass.
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
            return selected ? textPrimary : textSecondary;
          }),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            if (!selected) return Colors.transparent;
            return dark
                ? Colors.white.withValues(alpha: 0.14)
                : Colors.white.withValues(alpha: 0.82);
          }),
          side: WidgetStateProperty.all(BorderSide.none),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: AppRadius.chipAll),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        // In dark mode the field is a *darker* well than the sheet it sits
        // in, so the fill is a whisper of white rather than a sheet of it.
        fillColor: dark
            ? Colors.white.withValues(alpha: 0.07)
            : Colors.white.withValues(alpha: 0.55),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        hintStyle: TextStyle(color: textTertiary),
        border: OutlineInputBorder(
          borderRadius: AppRadius.smallAll,
          borderSide: strokeSide,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.smallAll,
          borderSide: strokeSide,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.smallAll,
          borderSide: BorderSide(color: primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.smallAll,
          borderSide: BorderSide(color: danger, width: 1.4),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.smallAll,
          borderSide: BorderSide(color: danger, width: 1.6),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: primaryContainer,
          disabledForegroundColor: Colors.white,
          minimumSize: const Size(0, 54),
          elevation: 0,
          textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.smallAll),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          minimumSize: const Size(0, 54),
          textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
          side: strokeSide,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.smallAll),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: textSecondary),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        // A near-black bar is invisible on a black canvas; dark mode uses the
        // raised surface grey instead so the bar reads as a lifted pane.
        backgroundColor: dark ? AppColorsDark.surfaceMuted : textPrimary,
        contentTextStyle: TextStyle(
          color: dark ? AppColorsDark.textPrimary : Colors.white,
          fontSize: 15,
        ),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.chipAll),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: fillInset,
        selectedColor: primarySoft,
        side: BorderSide.none,
        labelStyle: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.pillAll),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primary,
        linearTrackColor: fillInset,
        linearMinHeight: 6,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.all(Colors.white),
        trackColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected)
                  ? primary
                  : (dark ? AppColorsDark.hairline : AppColors.hairline),
        ),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
    );
  }

  static TextTheme _textTheme(TextTheme base, {required bool dark}) {
    final textPrimary = dark ? AppColorsDark.textPrimary : AppColors.textPrimary;
    final textSecondary = dark
        ? AppColorsDark.textSecondary
        : AppColors.textSecondary;
    final textTertiary = dark
        ? AppColorsDark.textTertiary
        : AppColors.textTertiary;

    return base
        .apply(bodyColor: textPrimary, displayColor: textPrimary)
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
          bodyMedium: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            letterSpacing: -0.22,
            height: 1.43,
            color: textSecondary,
          ),
          labelLarge: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.24,
          ),
          labelMedium: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            letterSpacing: -0.08,
            color: textSecondary,
          ),
          labelSmall: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: textTertiary,
          ),
        );
  }
}
