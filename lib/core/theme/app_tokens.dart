import 'package:flutter/material.dart';

/// Spacing scale (multiples of 4) used for padding and gaps across the app.
///
/// Vertical rhythm between blocks should come from a container's `gap`, not
/// from ad-hoc `SizedBox` spacers.
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
  static const double page = 20;

  /// Gap between major blocks in a scrolling page.
  static const double section = 16;
}

/// Corner-radius scale: small controls → cards → sheets.
class AppRadius {
  AppRadius._();

  /// Small controls: unit toggles, checkboxes, segmented segments.
  static const double chip = 8;

  /// Cards and list rows.
  static const double small = 14;

  /// Primary card surface.
  static const double card = 18;

  /// Panels and dialogs.
  static const double large = 24;

  /// Bottom sheets.
  static const double sheet = 24;

  /// Fully rounded pills: buttons, chips, tab bar.
  static const double pill = 999;

  static BorderRadius get chipAll => BorderRadius.circular(chip);
  static BorderRadius get smallAll => BorderRadius.circular(small);
  static BorderRadius get cardAll => BorderRadius.circular(card);
  static BorderRadius get largeAll => BorderRadius.circular(large);
  static BorderRadius get pillAll => BorderRadius.circular(pill);
  static const BorderRadius sheetTop = BorderRadius.vertical(
    top: Radius.circular(sheet),
  );
}

/// Elevation has been reduced to a single floating shadow.
///
/// Resting cards sit on the #F5F5F7 canvas and carry **no** shadow — that
/// contrast plus a hairline divider is what separates them. Only surfaces
/// that genuinely float above content (the pill tab bar, sheets) get a
/// shadow.
class AppShadows {
  AppShadows._();

  /// No shadow. Default for every resting card; the canvas provides contrast.
  static const List<BoxShadow> soft = [];

  /// The one shadow in the system: used by floating chrome.
  static const List<BoxShadow> floating = [
    BoxShadow(color: Color(0x1F000000), blurRadius: 24, offset: Offset(0, 8)),
  ];

  /// Gentle elevation for sticky bottom bars and sheets.
  static const List<BoxShadow> bar = [
    BoxShadow(color: Color(0x14000000), blurRadius: 16, offset: Offset(0, -2)),
  ];
}

/// Controlled gradients. Only three surfaces in the app are allowed to use
/// them: the primary CTA, the weight-progress bar, and trend-chart area fills.
class AppGradients {
  AppGradients._();

  /// Primary CTA background, left-to-right.
  static const LinearGradient cta = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF0066CC), Color(0xFF2E8BE6)],
  );

  /// Weight-progress bar fill, left-to-right.
  static const LinearGradient progress = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF0066CC), Color(0xFF66B3FF)],
  );

  /// Trend-chart area fill, top-to-bottom, using the accent colour.
  static const LinearGradient chartArea = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0x420066CC), Color(0x050066CC)],
  );
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

  /// Playful overshoot for checkmarks and celebrations.
  static const Curve spring = Curves.elasticOut;

  /// Press-feedback duration for tappable cards.
  static const Duration press = Duration(milliseconds: 120);
}
