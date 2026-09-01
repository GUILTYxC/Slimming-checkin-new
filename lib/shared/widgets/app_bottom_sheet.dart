import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_glass.dart';
import '../../core/theme/app_tokens.dart';

/// Presents [child] as a modal bottom sheet with the app's signature rounded
/// top corners, drag handle and spring-like entrance.
///
/// Returns whatever the sheet pops with.
Future<T?> showAppSheet<T>(
  BuildContext context, {
  required Widget child,
  double heightFactor = 0.88,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.32),
    builder:
        (context) => AppBottomSheet(heightFactor: heightFactor, child: child),
  );
}

/// Rounded-top sheet container with a drag handle. Content scrolls inside the
/// remaining space between [header]-style top content and any bottom bar the
/// caller composes inside [child].
class AppBottomSheet extends StatelessWidget {
  const AppBottomSheet({
    super.key,
    required this.child,
    this.heightFactor = 0.88,
    this.showHandle = true,
  });

  final Widget child;
  final double heightFactor;
  final bool showHandle;

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * heightFactor;
    return Padding(
      // Lift the sheet above the software keyboard when it appears.
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: GlassSurface(
        thickness: GlassThickness.thick,
        borderRadius: AppRadius.sheetTop,
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showHandle)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.md, bottom: 2),
                child: Container(
                  width: 36,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
              ),
            Flexible(child: child),
          ],
        ),
      ),
    );
  }
}
