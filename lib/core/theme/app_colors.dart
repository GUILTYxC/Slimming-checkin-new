import 'package:flutter/material.dart';

/// Central colour palette for the app.
///
/// The system is deliberately small so every screen converges on the same
/// look:
/// * one accent colour ([primary]) for anything tappable,
/// * four neutral greys for structure and text,
/// * three data colours used **only** inside charts and metric labels.
///
/// There are no decorative gradients left in the app — depth comes from
/// the #F5F5F7 canvas, hairline dividers and typographic weight.
class AppColors {
  AppColors._();

  // ── Surfaces ────────────────────────────────────────────────────────────
  /// Page background. White cards sit on this so they read as raised without
  /// needing a shadow.
  static const Color canvas = Color(0xFFF5F5F7);

  /// Card / sheet background.
  static const Color surface = Color(0xFFFFFFFF);

  /// Inset areas inside a card (chips, icon wells, progress tracks).
  static const Color surfaceMuted = Color(0xFFF5F5F7);

  /// Legacy name kept so older widgets keep compiling.
  static const Color background = canvas;

  // ── Text ────────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF1D1D1F);
  static const Color textSecondary = Color(0xFF6E6E73);
  static const Color textTertiary = Color(0xFF86868B);

  /// Only for de-emphasised meta text such as chart axis labels.
  static const Color textQuaternary = Color(0xFFA0A0A5);

  // ── Lines ───────────────────────────────────────────────────────────────
  /// Divider inside a white card.
  static const Color hairline = Color(0xFFE5E5EA);

  /// Extremely light separator used inside dense lists.
  static const Color divider = Color(0xFFF0F0F0);

  /// Outline for controls that need an edge (inputs, pill tab bar).
  static const Color border = Color(0xFFD2D2D7);

  // ── Brand: the single accent colour ─────────────────────────────────────
  static const Color primary = Color(0xFF0066CC);
  static const Color primaryFocus = Color(0xFF0071E3);

  /// Pressed / on-light text variant of the accent.
  static const Color primaryDark = Color(0xFF004F9E);

  /// Tinted accent background (icon wells, selected chips).
  static const Color primarySoft = Color(0xFFEBF3FC);
  static const Color primaryContainer = Color(0xFFD6E6FA);

  // ── Semantic ────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF34C759);

  /// Green is only legible on white below ~#34C759, so text uses this darker
  /// shade while fills use [success].
  static const Color successText = Color(0xFF248A3D);
  static const Color successSoft = Color(0xFFE3F5E8);

  static const Color warning = Color(0xFFFF9500);
  static const Color warningSoft = Color(0xFFFFF2E5);

  static const Color danger = Color(0xFFD70015);
  static const Color dangerSoft = Color(0xFFFFF2F2);

  // ── Data colours (charts and metric labels only) ────────────────────────
  /// Weight — the app's hero metric, so it shares the accent blue.
  static const Color weight = Color(0xFF0066CC);
  static const Color weightSoft = Color(0xFFEBF3FC);

  /// Calories burned.
  static const Color calorie = Color(0xFFFF9500);
  static const Color calorieSoft = Color(0xFFFFF2E5);

  /// Body-fat percentage.
  static const Color bodyFat = Color(0xFF5856D6);
  static const Color bodyFatSoft = Color(0xFFEEEDFC);
}
