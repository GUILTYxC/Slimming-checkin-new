import 'package:flutter/material.dart';

import '../../core/theme/app_glass.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_palette.dart';

/// Resting card surface — a pane of frosted glass over the aurora backdrop.
///
/// With [glass] on (the default) the card is a [GlassSurface]: it blurs and
/// saturates whatever sits behind it, then adds a translucent fill, a specular
/// sheen and a bright 1px edge. No opaque white, no hairline divider, no
/// crisp shadow — the pane reads as physical glass rather than paper.
///
/// When [onTap] is provided the card ripples and gently scales down while
/// pressed for tactile feedback.
class AppCard extends StatefulWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.xl),
    this.onTap,
    this.onLongPress,
    this.color,
    this.radius = AppRadius.card,
    this.border,
    this.shadow,
    this.clip = true,
    this.glass = true,
    this.sheen = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Color? color;
  final double radius;

  /// Glass specular wash. Turn off over dense form text so it stays legible.
  final bool sheen;

  /// Optional outline. Only needed when a glass pane needs a stronger edge.
  final BoxBorder? border;

  /// Overrides the glass shadow. Pass an empty list to remove it.
  final List<BoxShadow>? shadow;

  /// Set to false when a child must paint outside the rounded corners.
  final bool clip;

  /// Render as frosted glass. Turn off for the rare surface that must be
  /// fully opaque (e.g. a chart tooltip).
  final bool glass;

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (value == _pressed) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final br = BorderRadius.circular(widget.radius);
    Widget content = Padding(padding: widget.padding, child: widget.child);
    if (widget.onTap != null || widget.onLongPress != null) {
      content = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          onLongPress: widget.onLongPress,
          onHighlightChanged: _setPressed,
          borderRadius: br,
          splashColor: context.palette.primary.withValues(alpha: 0.08),
          highlightColor: context.palette.primary.withValues(alpha: 0.05),
          child: content,
        ),
      );
    }

    final Widget surface =
        widget.glass
            ? GlassSurface(
              radius: widget.radius,
              color: widget.color,
              border: widget.border,
              sheen: widget.sheen,
              shadow: _pressed ? const <BoxShadow>[] : widget.shadow,
              // The material deforms, not just the geometry: blur tightens,
              // fill densifies, rim dims, highlight drifts inward. See
              // [GlassSurface.pressed].
              pressed: _pressed,
              child: content,
            )
            : AnimatedContainer(
              duration: AppMotion.press,
              decoration: BoxDecoration(
                color: widget.color ?? context.palette.surface,
                borderRadius: br,
                boxShadow:
                    _pressed ? const [] : (widget.shadow ?? AppShadows.soft),
                border: widget.border ?? Border.all(color: context.palette.hairline),
              ),
              child: content,
            );

    final card = AnimatedScale(
      scale: _pressed ? 0.98 : 1,
      duration: AppMotion.press,
      curve: Curves.easeOut,
      child: surface,
    );

    return widget.clip && !widget.glass ? ClipRRect(borderRadius: br, child: card) : card;
  }
}
