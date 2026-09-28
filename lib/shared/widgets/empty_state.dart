import 'package:flutter/material.dart';

import '../../core/theme/app_glass.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_palette.dart';

/// Friendly centred placeholder for empty screens.
///
/// Uses the single accent tint so an empty screen still has one focal point,
/// and always pairs the message with an action so the user knows the next
/// step.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // A sphere of glass rather than a flat tinted circle: it blurs
            // whatever aurora wash sits behind it, so the empty state picks
            // up the colour of wherever it happens to land on screen.
            GlassSurface(
              radius: 999,
              width: 104,
              height: 104,
              alignment: Alignment.center,
              child: Icon(icon, size: 40, color: context.palette.primary),
            ),
            const SizedBox(height: AppSpacing.xxl),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
                color: context.palette.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                letterSpacing: 0,
                color: context.palette.textSecondary,
              ),
            ),
            if (action != null) ...[
              const SizedBox(height: AppSpacing.xxl),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
