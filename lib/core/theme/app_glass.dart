import 'dart:ui';

import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_tokens.dart';

/// iOS-style **Liquid Glass** material tokens.
///
/// Glass in this app is always the same four-layer recipe, so every glass
/// surface in the app reads as the same physical material:
///
/// 1. **blur** — the content behind the surface is blurred and saturation
///    lifted, which is what produces the "vibrancy" iOS glass is known for;
/// 2. **fill** — a translucent white that lets the blurred backdrop through;
/// 3. **sheen** — a top-to-bottom specular wash that reads as a curved edge;
/// 4. **stroke** — a 1px bright edge on top, dimmer at the bottom, giving the
///    pane visible thickness.
///
/// Two thicknesses exist: [GlassThickness.regular] for resting content cards
/// and [GlassThickness.thick] for floating chrome (pill tab bar, sheets,
/// dialogs) that has to stay legible over busy content.
class AppGlass {
  AppGlass._();

  // ── Blur ───────────────────────────────────────────────────────────────
  /// Backdrop blur radius for content cards.
  static const double blurRegular = 16;

  /// Backdrop blur radius for floating chrome.
  static const double blurThick = 28;

  // ── Fill ───────────────────────────────────────────────────────────────
  /// Resting card fill (≈62% white). Transparent enough that the aurora
  /// behind it shifts as the page scrolls.
  static const Color fillRegular = Color(0x9EFFFFFF);

  /// Floating chrome fill (≈75% white) — denser than a card so small labels
  /// stay legible, but still open enough that a card nested inside a sheet
  /// has something left to refract.
  static const Color fillThick = Color(0xBFFFFFFF);

  /// Inset wells (chips, icon wells, progress tracks) inside a glass card.
  /// A whisper of ink rather than grey, so it stays translucent.
  static const Color fillInset = Color(0x0F1D1D1F);

  /// Inset wells on chrome, where the backdrop is busier.
  static const Color fillInsetThick = Color(0x141D1D1F);

  /// Translucent fill for a bar or chip pinned over a pane — the pinned save
  /// bar in the check-in sheet, the streak pill on the dashboard.
  ///
  /// Light mode lifts these off the pane with white; dark mode (see
  /// [AppGlassDark.barFill]) has to drop them with ink instead.
  static const Color barFill = Color(0x8CFFFFFF);

  /// Inset input well fill — a denser white than [fillInset], matching
  /// `InputDecorationTheme.fillColor` so custom editors and stock text fields
  /// read as the same surface.
  static const Color wellFill = Color(0x8CFFFFFF);

  /// Modal scrim behind dialogs and sheets. Dims a light canvas with black.
  static const Color barrier = Color(0x52000000);

  // ── Stroke ─────────────────────────────────────────────────────────────
  /// Width of the bright rim that runs around the outside of a pane.
  static const double edgeWidth = 1.2;

  /// Width of the darker refraction band just inside the bright rim. This is
  /// the band that makes a pane read as *thick* rather than as a flat sheet.
  static const double refractionWidth = 2.6;

  /// Gap between the outer edge and the refraction band.
  static const double refractionInset = 1.1;

  /// Brightness of the rim, top → bottom.
  ///
  /// A uniform white outline is what makes a "frosted card" look like paper.
  /// Real glass is brightest where the key light grazes it (the top edge),
  /// dimmest along the sides, and bright *again* along the bottom where light
  /// that travelled through the pane bounces back off whatever is behind it.
  /// That top-bright / side-dim / bottom-bright asymmetry is the single
  /// strongest cue that a surface has physical thickness.
  static const LinearGradient edgeLight = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xE6FFFFFF), // top — key light
      Color(0x2EFFFFFF), // upper sides
      Color(0x1AFFFFFF), // lower sides
      Color(0x99FFFFFF), // bottom — bounce light
    ],
    stops: [0.0, 0.42, 0.72, 1.0],
  );

  /// The refraction band: a whisper of cool shadow, not grey.
  static const Color refraction = Color(0x1400264D);

  /// Light pooling along the inside of the bottom edge.
  static const Color caustic = Color(0x59FFFFFF);

  /// Bright top edge of the pane (fallback for surfaces that opt out of the
  /// painted rim).
  static const Color strokeTop = Color(0xCCFFFFFF);

  /// Dimmer bottom edge — this asymmetry is what makes the pane look thick.
  static const Color strokeBottom = Color(0x59FFFFFF);

  /// Default 1px stroke used when a surface does not need the split edge.
  static const BorderSide strokeSide = BorderSide(
    color: Color(0xA6FFFFFF),
    width: 1.1,
  );

  // ── Sheen ──────────────────────────────────────────────────────────────
  /// Specular wash falling from the top edge of the surface.
  static const LinearGradient sheen = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0x52FFFFFF), Color(0x00FFFFFF)],
    stops: [0.0, 0.6],
  );

  /// Colour of the specular highlight. See [specularAlignment].
  static const Color specular = Color(0x26FFFFFF);

  /// A soft specular highlight sitting just inside the top-left corner.
  ///
  /// The linear [sheen] alone reads as a flat wash. On curved glass the light
  /// source also produces a distinct bright *spot* where the surface normal
  /// points at the light — an elongated highlight rather than a gradient.
  /// It is deliberately faint: real glass highlights are easy to overdo.
  static const Alignment specularAlignment = Alignment(-0.72, -0.86);

  // ── Press response ─────────────────────────────────────────────────────
  /// Fraction of the blur lost at full press.
  ///
  /// Pressing liquid glass flattens it against whatever is behind, so there
  /// is less distance for light to scatter over and the blur tightens. A
  /// surface that only shrinks under a finger is reacting like paper; the
  /// material has to react too.
  static const double pressBlurDrop = 0.28;

  /// How much denser the fill gets at full press, in alpha units.
  static const double pressFillGain = 0.10;

  /// Where the specular highlight drifts to at full press.
  ///
  /// The highlight slides toward the centre because the surface is bowing —
  /// this is the detail that reads as "liquid" rather than "dimmed".
  static const Alignment specularAlignmentPressed = Alignment(-0.60, -0.76);

  /// Rim brightness multiplier at full press: less thickness, less light
  /// travelling through the edge.
  static const double pressRimFade = 0.62;

  /// Duration of the press settle. Slightly longer than the geometric scale
  /// so the material visibly flows rather than snapping.
  static const Duration pressDuration = Duration(milliseconds: 180);

  // ── Shadows ────────────────────────────────────────────────────────────
  /// Diffuse, slightly blue-tinted shadow. Glass scatters light, so its
  /// shadow is softer and cooler than an opaque card's.
  static const List<BoxShadow> shadow = [
    BoxShadow(color: Color(0x1200264D), blurRadius: 22, offset: Offset(0, 8)),
    BoxShadow(color: Color(0x0A00264D), blurRadius: 2, offset: Offset(0, 1)),
  ];

  /// Larger, deeper shadow for floating chrome.
  static const List<BoxShadow> shadowFloating = [
    BoxShadow(color: Color(0x2400264D), blurRadius: 32, offset: Offset(0, 12)),
    BoxShadow(color: Color(0x1000264D), blurRadius: 3, offset: Offset(0, 1)),
  ];

  /// Backdrop filter shared by every glass surface.
  ///
  /// The saturation lift is the Flutter equivalent of UIKit's
  /// `UIVibrancyEffect`: without it, blurred content looks washed out and
  /// grey instead of rich.
  static ImageFilter filter(double sigma) => ImageFilter.compose(
    outer: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
    inner: const ColorFilter.matrix(<double>[
      1.14, 0, 0, 0, 0, //
      0, 1.14, 0, 0, 0, //
      0, 0, 1.14, 0, 0, //
      0, 0, 0, 1, 0, //
    ]),
  );
}

/// Dark-mode glass recipe.
///
/// Dark glass is **not** light glass recoloured. The physics inverts:
///
/// * the fill is translucent *ink* rather than translucent white — it darkens
///   the backdrop instead of lifting it;
/// * the rim stays white but is dialled way down, because on a black canvas
///   white reads far louder than it does on a light one;
/// * the refraction band is black, not a cool tint — the pane is already
///   dark, so the band has to remove light rather than add colour;
/// * the specular highlight is halved again, for the same reason the rim is.
///
/// Separation between stacked panes comes almost entirely from the rim here,
/// not from shadow: a drop shadow is invisible on black.
class AppGlassDark {
  AppGlassDark._();

  /// Resting card fill (≈62% of #1C1C1E).
  static const Color fillRegular = Color(0x9E1C1C1E);

  /// Floating chrome fill (≈75% of #2C2C2E).
  static const Color fillThick = Color(0xBF2C2C2E);

  /// Inset wells are *lighter* than the pane in dark mode — a whisper of
  /// white, the inverse of [AppGlass.fillInset].
  static const Color fillInset = Color(0x14FFFFFF);

  /// Inset wells on chrome.
  static const Color fillInsetThick = Color(0x1FFFFFFF);

  /// Translucent fill for a bar pinned inside a sheet.
  ///
  /// Light mode lifts the bar off the sheet with white; dark mode has to drop
  /// it with ink instead. A 55%-white bar sitting on a dark sheet is not a
  /// bar, it is a glare strip.
  static const Color barFill = Color(0x8C1C1C1E);

  /// Inset input well fill. On black the well has to *catch* light rather
  /// than drop it, so this is a whisper of white instead of a sheet of ink.
  static const Color wellFill = Color(0x12FFFFFF);

  /// Modal scrim. A black canvas needs a much heavier scrim to read as
  /// "dim" — 32% black on black is invisible.
  static const Color barrier = Color(0x99000000);

  /// Bright top edge, for surfaces that draw their own stroke. Dimmer than
  /// [AppGlass.strokeTop] — see [edgeLight].
  static const Color strokeTop = Color(0x99FFFFFF);

  /// Rim brightness, top → bottom. Same asymmetry as light mode, roughly 40%
  /// lower across the board.
  static const LinearGradient edgeLight = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0x99FFFFFF), // top — key light
      Color(0x1AFFFFFF), // upper sides
      Color(0x12FFFFFF), // lower sides
      Color(0x59FFFFFF), // bottom — bounce light
    ],
    stops: [0.0, 0.42, 0.72, 1.0],
  );

  /// The pane is already dark, so the refraction band removes light.
  static const Color refraction = Color(0x4D000000);

  /// Light pooling along the inside of the bottom edge. Weaker than light
  /// mode — on black it does not take much to look like a glow stick.
  static const Color caustic = Color(0x2EFFFFFF);

  /// Specular wash, dimmer than [AppGlass.sheen].
  static const LinearGradient sheen = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0x1AFFFFFF), Color(0x00FFFFFF)],
    stops: [0.0, 0.6],
  );

  /// Specular highlight colour — roughly half the alpha of light mode.
  static const Color specular = Color(0x14FFFFFF);

  /// Default 1px stroke for controls that need an edge. Dimmer than
  /// [AppGlass.strokeSide]: a 65%-white hairline would scream on black.
  static const BorderSide strokeSide = BorderSide(
    color: Color(0x40FFFFFF),
    width: 1.1,
  );

  /// Shadows are near-useless on black; these exist only to stop a floating
  /// pane from bleeding into the content behind it.
  static const List<BoxShadow> shadow = [
    BoxShadow(color: Color(0x66000000), blurRadius: 24, offset: Offset(0, 8)),
    BoxShadow(color: Color(0x33000000), blurRadius: 2, offset: Offset(0, 1)),
  ];

  static const List<BoxShadow> shadowFloating = [
    BoxShadow(color: Color(0x8C000000), blurRadius: 34, offset: Offset(0, 12)),
    BoxShadow(color: Color(0x4D000000), blurRadius: 3, offset: Offset(0, 1)),
  ];

  /// Dark glass needs *more* saturation lift, not less: a black backdrop
  /// drains colour out of whatever is blurred behind the pane.
  static ImageFilter filter(double sigma) => ImageFilter.compose(
    outer: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
    inner: const ColorFilter.matrix(<double>[
      1.28, 0, 0, 0, 0, //
      0, 1.28, 0, 0, 0, //
      0, 0, 1.28, 0, 0, //
      0, 0, 0, 1, 0, //
    ]),
  );
}

/// Which glass recipe a surface uses.
enum GlassThickness {
  /// Resting content cards.
  regular,

  /// Floating chrome: pill tab bar, sheets, dialogs, toasts.
  thick,
}

/// Fixed aurora backdrop painted behind the whole app.
///
/// Liquid glass needs something to refract, and a flat grey canvas gives it
/// nothing. Three large, very low-opacity radial washes — drawn from the
/// existing data colours (weight blue, calorie orange, body-fat indigo) so no
/// new colour enters the system — sit behind every screen and stay put while
/// content scrolls over them. Each glass surface therefore picks up a slightly
/// different tint depending on where it happens to sit on screen.
class GlassBackdrop extends StatelessWidget {
  const GlassBackdrop({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: dark ? AppColorsDark.canvas : AppColors.canvas,
      ),
      child: Stack(
        fit: StackFit.expand,
        // Explicit and non-directional. This backdrop sits *above*
        // MaterialApp in the tree, so there is no Directionality ancestor to
        // resolve a directional alignment from — the default
        // AlignmentDirectional.topStart would throw. StackFit.expand already
        // hands the child a tight fill constraint, so the resolved rect is
        // identical either way; this just removes the ambient dependency.
        alignment: Alignment.topLeft,
        children: [
          // Dark mode runs the aurora much hotter: on black, the light mode
          // alphas are barely visible, and glass with nothing to refract is
          // just a flat grey rectangle.
          if (dark) ...[
            const _AuroraBlob(
              alignment: Alignment(-0.9, -0.95),
              size: 460,
              color: AppColorsDark.weight,
              alpha: 0.42,
            ),
            const _AuroraBlob(
              alignment: Alignment(1.0, -0.4),
              size: 400,
              color: AppColorsDark.bodyFat,
              alpha: 0.36,
            ),
            const _AuroraBlob(
              alignment: Alignment(-0.75, 0.98),
              size: 480,
              color: AppColorsDark.calorie,
              alpha: 0.34,
            ),
            const _AuroraBlob(
              alignment: Alignment(0.7, 0.62),
              size: 340,
              color: AppColorsDark.primary,
              alpha: 0.24,
            ),
          ] else ...[
            const _AuroraBlob(
              alignment: Alignment(-0.9, -0.95),
              size: 460,
              color: AppColors.weight,
              alpha: 0.26,
            ),
            const _AuroraBlob(
              alignment: Alignment(1.0, -0.4),
              size: 400,
              color: AppColors.bodyFat,
              alpha: 0.20,
            ),
            const _AuroraBlob(
              alignment: Alignment(-0.75, 0.98),
              size: 480,
              color: AppColors.calorie,
              alpha: 0.20,
            ),
            const _AuroraBlob(
              alignment: Alignment(0.7, 0.62),
              size: 340,
              color: AppColors.primary,
              alpha: 0.14,
            ),
          ],
          child,
        ],
      ),
    );
  }
}

class _AuroraBlob extends StatelessWidget {
  const _AuroraBlob({
    required this.alignment,
    required this.size,
    required this.color,
    required this.alpha,
  });

  final Alignment alignment;
  final double size;
  final Color color;
  final double alpha;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: alpha),
              color.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }
}

/// A dialog rendered as a pane of thick glass.
///
/// The theme sets `dialogTheme.backgroundColor` to transparent so dialogs do
/// not paint an opaque Material surface of their own; wrap dialog content in
/// this instead. Keeps the same inset geometry Flutter's [Dialog] uses.
class GlassDialog extends StatelessWidget {
  const GlassDialog({
    super.key,
    required this.child,
    this.insetPadding = const EdgeInsets.symmetric(
      horizontal: 40,
      vertical: 24,
    ),
    this.padding = const EdgeInsets.fromLTRB(24, 24, 24, 14),
    this.radius = AppRadius.large,
  });

  final Widget child;
  final EdgeInsets insetPadding;
  final EdgeInsets padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: insetPadding,
      child: GlassSurface(
        thickness: GlassThickness.thick,
        radius: radius,
        padding: padding,
        child: child,
      ),
    );
  }
}

/// Paints the rim of a glass pane.
///
/// Three bands, outside in:
/// 1. a **bright rim** whose brightness varies around the perimeter
///    (see [AppGlass.edgeLight]);
/// 2. a **refraction band** — a thin, cool, darkened ring just inside the rim
///    standing in for the way a thick curved edge bends light away from the
///    viewer;
/// 3. a **caustic** along the inside of the bottom edge, where light that
///    travelled through the pane pools before leaving.
///
/// This is a painter rather than a [BoxDecoration] border because a flat
/// [BorderSide] cannot vary its brightness around the perimeter — and that
/// variation is the whole point.
class GlassRimPainter extends CustomPainter {
  const GlassRimPainter({
    required this.borderRadius,
    this.refraction = true,
    this.dark = false,
    this.press = 0,
  });

  /// Resolved corner radii. Non-symmetric shapes (a sheet that only rounds
  /// its top corners) are supported.
  final BorderRadius borderRadius;

  /// Set to false on very small controls, where a refraction band would just
  /// read as dirt.
  final bool refraction;

  /// Switches to the [AppGlassDark] rim recipe: a dimmer white edge and a
  /// black refraction band.
  final bool dark;

  /// Press progress, 0 → 1. Dims the whole rim, since a flattened pane has
  /// less thickness for light to travel through.
  ///
  /// Only non-zero while the finger is down, so the layer this costs is never
  /// paid at rest.
  final double press;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndCorners(
      rect,
      topLeft: borderRadius.topLeft,
      topRight: borderRadius.topRight,
      bottomLeft: borderRadius.bottomLeft,
      bottomRight: borderRadius.bottomRight,
    );

    if (press > 0) {
      final fade = 1 - (1 - AppGlass.pressRimFade) * press;
      canvas.saveLayer(
        rect.inflate(6),
        Paint()..color = Color.fromARGB((255 * fade).round(), 255, 255, 255),
      );
    }

    // 1 — bright rim.
    canvas.drawRRect(
      rrect.deflate(AppGlass.edgeWidth / 2),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = AppGlass.edgeWidth
        ..shader = (dark ? AppGlassDark.edgeLight : AppGlass.edgeLight)
            .createShader(rect),
    );

    if (!refraction) return;

    // 2 — refraction band.
    const inset = AppGlass.edgeWidth + AppGlass.refractionInset;
    const band = AppGlass.refractionWidth;
    canvas.drawRRect(
      rrect.deflate(inset + band / 2),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = band
        ..color = dark ? AppGlassDark.refraction : AppGlass.refraction,
    );

    // 3 — caustic, clipped to the lower third so the top edge stays clean.
    canvas.save();
    canvas.clipRect(
      Rect.fromLTWH(
        rect.left,
        rect.bottom - rect.height * 0.36,
        rect.width,
        rect.height * 0.36,
      ),
    );
    canvas.drawRRect(
      rrect.deflate(inset + band + 0.9),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = dark ? AppGlassDark.caustic : AppGlass.caustic,
    );
    canvas.restore();

    if (press > 0) canvas.restore();
  }

  @override
  bool shouldRepaint(GlassRimPainter old) =>
      old.borderRadius != borderRadius ||
      old.refraction != refraction ||
      old.dark != dark ||
      old.press != press;
}

/// A translucent pane of glass.
///
/// This is the building block behind [AppCard], the pill tab bar, bottom
/// sheets and dialogs — anywhere the app needs to read as a physical sheet of
/// glass rather than a flat white rectangle.
///
/// Everything painted behind the pane (the [GlassBackdrop] aurora, scrolling
/// content) is blurred and saturation-lifted, then covered with a translucent
/// white fill, a specular sheen and a bright 1px edge.
class GlassSurface extends StatelessWidget {
  const GlassSurface({
    super.key,
    required this.child,
    this.radius = AppRadius.card,
    this.borderRadius,
    this.thickness = GlassThickness.regular,
    this.color,
    this.border,
    this.shadow,
    this.blur,
    this.backdrop,
    this.sheen = true,
    this.inset = false,
    this.pressed = false,
    this.width,
    this.height,
    this.constraints,
    this.padding,
    this.alignment,
  });

  final Widget child;

  /// Corner radius of the pane. Ignored when [borderRadius] is given.
  final double radius;

  /// Full corner-radius control, e.g. [AppRadius.sheetTop] for a sheet that
  /// only rounds its top corners.
  final BorderRadiusGeometry? borderRadius;

  /// Picks the fill/blur/shadow recipe.
  final GlassThickness thickness;

  /// Overrides the fill. Rarely needed — prefer switching [thickness].
  final Color? color;

  /// Overrides the stroke.
  final BoxBorder? border;

  /// Overrides the drop shadow. Pass an empty list to remove it entirely.
  final List<BoxShadow>? shadow;

  /// Overrides the backdrop blur radius.
  final double? blur;

  /// Whether to apply a backdrop blur. Defaults to `true` only for
  /// [GlassThickness.thick] — floating chrome that overlaps moving content —
  /// and `false` for resting cards.
  ///
  /// A backdrop blur is a full offscreen pass that re-runs every frame the
  /// pixels behind the pane change, so stacking one on every card multiplies
  /// the GPU load by the number of visible cards. Cards sit on the soft
  /// aurora, where a blur is visually invisible (a radial gradient blurs into
  /// the same gradient), so they skip it. See [GlassSurface.build].
  final bool? backdrop;

  /// Set to false for small controls where a sheen would look noisy.
  final bool sheen;

  /// True when this pane sits *inside* another glass pane. Insets are lighter
  /// and skip the shadow so nested glass does not stack darkness.
  final bool inset;

  /// True while a finger is on the pane.
  ///
  /// The material deforms rather than just the geometry: the blur tightens,
  /// the fill densifies, the rim dims and the specular highlight slides
  /// toward the centre, as it would if a soft sheet bowed under pressure.
  /// All of it eases over [AppGlass.pressDuration] so the glass visibly
  /// flows into its pressed state instead of snapping.
  final bool pressed;

  final double? width;
  final double? height;
  final BoxConstraints? constraints;
  final EdgeInsetsGeometry? padding;
  final AlignmentGeometry? alignment;

  bool get _thick => thickness == GlassThickness.thick;

  @override
  Widget build(BuildContext context) {
    final br = (borderRadius ?? BorderRadius.circular(radius)).resolve(
      Directionality.of(context),
    );
    final dark = Theme.of(context).brightness == Brightness.dark;
    final baseSigma =
        blur ?? (_thick ? AppGlass.blurThick : AppGlass.blurRegular);
    final baseFill =
        color ??
        (_thick
            ? (dark ? AppGlassDark.fillThick : AppGlass.fillThick)
            : (dark ? AppGlassDark.fillRegular : AppGlass.fillRegular));
    final shadows =
        shadow ??
        (inset
            ? const <BoxShadow>[]
            : (_thick
                ? (dark ? AppGlassDark.shadowFloating : AppGlass.shadowFloating)
                : (dark ? AppGlassDark.shadow : AppGlass.shadow)));
    final useBackdrop = backdrop ?? _thick;

    Widget content = child;
    if (padding case final p?) {
      content = Padding(padding: p, child: content);
    }

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: pressed ? 1 : 0),
      duration: AppGlass.pressDuration,
      curve: AppMotion.emphasized,
      builder: (context, t, child) {
        final fill =
            t == 0
                ? baseFill
                : baseFill.withValues(
                  alpha: (baseFill.a + AppGlass.pressFillGain * t).clamp(
                    0.0,
                    1.0,
                  ),
                );
        final spec =
            Alignment.lerp(
              AppGlass.specularAlignment,
              AppGlass.specularAlignmentPressed,
              t,
            )!;

        Widget pane = DecoratedBox(
          decoration: BoxDecoration(color: fill),
          child: Stack(
            fit: StackFit.passthrough,
            children: [
              child!,
              // Specular highlight: a soft elongated spot just inside the
              // top-left corner, where the surface normal points at the
              // light. Sits under the rim so the rim stays crisp. It drifts
              // toward the centre while pressed.
              if (sheen)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Align(
                      alignment: spec,
                      child: FractionallySizedBox(
                        widthFactor: 0.62,
                        heightFactor: 0.30,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              colors: [
                                dark
                                    ? AppGlassDark.specular
                                    : AppGlass.specular,
                                const Color(0x00FFFFFF),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              // Sheen + rim ride on top of the content: they belong to the
              // front face of the glass, not to what is inside it.
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: br,
                      // Only set when the caller overrides the stroke; the
                      // default rim is painted by [GlassRimPainter] below,
                      // which can vary brightness around the perimeter.
                      border: border,
                      gradient:
                          sheen
                              ? (dark
                                  ? AppGlassDark.sheen
                                  : AppGlass.sheen)
                              : null,
                    ),
                    child:
                        border != null
                            ? null
                            : CustomPaint(
                              painter: GlassRimPainter(
                                borderRadius: br,
                                // Nested glass is too small for a refraction
                                // band to read as anything but dirt.
                                refraction: !inset,
                                dark: dark,
                                press: t,
                              ),
                            ),
                  ),
                ),
              ),
            ],
          ),
        );

        // A backdrop blur is a full offscreen pass that re-runs every frame
        // the pixels behind the pane move — scrolling a list of cards
        // therefore multiplies the GPU load by the number of visible cards.
        // Cards sit on the soft aurora, where a blur is visually invisible
        // (a radial gradient blurs into the same gradient), so they skip it.
        // Only floating chrome that overlaps moving text — the tab bar,
        // sheets and dialogs — keeps the blur.
        if (useBackdrop) {
          final sigma = baseSigma * (1 - AppGlass.pressBlurDrop * t);
          pane = BackdropFilter(
            filter:
                dark ? AppGlassDark.filter(sigma) : AppGlass.filter(sigma),
            child: pane,
          );
        }

        return Container(
          width: width,
          height: height,
          constraints: constraints,
          alignment: alignment,
          // The shadow lives on an outer container so it is painted *behind*
          // the pane rather than being smeared into it.
          decoration: BoxDecoration(borderRadius: br, boxShadow: shadows),
          child: ClipRRect(borderRadius: br, child: pane),
        );
      },
      child: content,
    );
  }
}
