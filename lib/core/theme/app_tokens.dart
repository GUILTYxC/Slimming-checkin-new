import 'package:flutter/material.dart';

/// Spacing scale (multiples of 4) used for padding and gaps across the app.
class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;

  /// Standard horizontal page padding.
  static const double page = 18;
}

/// Corner-radius scale: small chips → cards → sheets & dialogs.
class AppRadius {
  AppRadius._();

  static const double chip = 10;
  static const double small = 14;
  static const double card = 20;
  static const double large = 24;
  static const double sheet = 28;

  static BorderRadius get chipAll => BorderRadius.circular(chip);
  static BorderRadius get smallAll => BorderRadius.circular(small);
  static BorderRadius get cardAll => BorderRadius.circular(card);
  static BorderRadius get largeAll => BorderRadius.circular(large);
  static const BorderRadius sheetTop = BorderRadius.vertical(
    top: Radius.circular(sheet),
  );
}

/// Elevation shadows: soft resting cards vs. floating elements (nav button,
/// sheets, dialogs).
class AppShadows {
  AppShadows._();

  /// Diffuse, airy shadow for resting cards.
  static const List<BoxShadow> soft = [
    BoxShadow(color: Color(0x0F1A1D1F), blurRadius: 24, offset: Offset(0, 8)),
  ];

  /// Stronger lift for floating elements such as the centre check-in button.
  static const List<BoxShadow> floating = [
    BoxShadow(color: Color(0x332ED3B7), blurRadius: 20, offset: Offset(0, 8)),
    BoxShadow(color: Color(0x141A1D1F), blurRadius: 12, offset: Offset(0, 4)),
  ];

  /// Gentle elevation for sticky bottom bars.
  static const List<BoxShadow> bar = [
    BoxShadow(color: Color(0x0A1A1D1F), blurRadius: 16, offset: Offset(0, -4)),
  ];
}

/// Motion tokens: durations and curves shared by every animation so the whole
/// app moves with one consistent feel.
class AppMotion {
  AppMotion._();

  static const Duration fast = Duration(milliseconds: 180);
  static const Duration normal = Duration(milliseconds: 280);
  static const Duration slow = Duration(milliseconds: 500);

  /// Default emphasised exit curve for entrances and transitions.
  static const Curve emphasized = Curves.easeOutCubic;

  /// Playful overshoot for checkmarks, badges and celebrations.
  static const Curve spring = Curves.elasticOut;

  /// Press-feedback duration for tappable cards.
  static const Duration press = Duration(milliseconds: 120);
}
