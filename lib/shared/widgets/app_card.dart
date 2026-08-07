import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';

/// Soft, diffuse shadow used by every raised surface for a light, airy feel.
const List<BoxShadow> kSoftShadow = AppShadows.soft;

/// Rounded white surface with a soft shadow. When [onTap] is provided the
/// card ripples and gently scales down while pressed for tactile feedback.
class AppCard extends StatefulWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.page),
    this.onTap,
    this.color,
    this.radius = AppRadius.card,
    this.border,
    this.shadow = kSoftShadow,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;
  final double radius;
  final BoxBorder? border;
  final List<BoxShadow>? shadow;

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
    if (widget.onTap != null) {
      content = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          onHighlightChanged: _setPressed,
          borderRadius: br,
          splashColor: AppColors.primarySoft.withValues(alpha: 0.6),
          highlightColor: AppColors.primarySoft.withValues(alpha: 0.3),
          child: content,
        ),
      );
    }
    return AnimatedScale(
      scale: _pressed ? 0.98 : 1,
      duration: AppMotion.press,
      curve: Curves.easeOut,
      child: AnimatedContainer(
        duration: AppMotion.press,
        decoration: BoxDecoration(
          color: widget.color ?? AppColors.surface,
          borderRadius: br,
          boxShadow: _pressed ? const [] : widget.shadow,
          border: widget.border,
        ),
        child: ClipRRect(borderRadius: br, child: content),
      ),
    );
  }
}
