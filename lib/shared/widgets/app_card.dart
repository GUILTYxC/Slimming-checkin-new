import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Soft, diffuse shadow used by every raised surface for a light, airy feel.
const List<BoxShadow> kSoftShadow = [
  BoxShadow(
    color: Color(0x0F1A1D1F),
    blurRadius: 24,
    offset: Offset(0, 8),
  ),
];

/// Rounded white surface with a soft shadow. Optionally tappable with a ripple.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.onTap,
    this.color,
    this.radius = 20,
    this.border,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;
  final double radius;
  final BoxBorder? border;

  @override
  Widget build(BuildContext context) {
    final br = BorderRadius.circular(radius);
    Widget content = Padding(padding: padding, child: child);
    if (onTap != null) {
      content = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: br,
          splashColor: AppColors.primarySoft.withValues(alpha: 0.6),
          highlightColor: AppColors.primarySoft.withValues(alpha: 0.3),
          child: content,
        ),
      );
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color ?? AppColors.surface,
        borderRadius: br,
        boxShadow: kSoftShadow,
        border: border,
      ),
      child: ClipRRect(borderRadius: br, child: content),
    );
  }
}
