import 'package:flutter/material.dart';

import '../../core/theme/app_glass.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_palette.dart';

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
    barrierColor: context.palette.barrier,
    builder:
        (context) => AppBottomSheet(heightFactor: heightFactor, child: child),
  );
}

/// Rounded-top sheet container with a drag handle. Content scrolls inside the
/// remaining space between [header]-style top content and any bottom bar the
/// caller composes inside [child].
class AppBottomSheet extends StatefulWidget {
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
  State<AppBottomSheet> createState() => _AppBottomSheetState();
}

class _AppBottomSheetState extends State<AppBottomSheet> {
  /// True only once the sheet has finished sliding in and come to rest.
  ///
  /// A backdrop blur re-samples everything behind the pane, so it re-runs on
  /// every frame the pane moves. Blurring a sheet *while it slides* therefore
  /// costs one full-screen blur per frame, which is what makes the slide-in
  /// stutter. The blur is switched on only once the sheet is parked, and off
  /// again the moment it starts leaving, so both the entrance and the exit
  /// stay smooth. At rest the blur is exactly as before — the gate costs
  /// nothing visually once the sheet stops.
  bool _settled = false;

  Animation<double>? _routeAnimation;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final animation = ModalRoute.of(context)?.animation;
    if (animation == _routeAnimation) return;
    _routeAnimation?.removeStatusListener(_onRouteStatus);
    _routeAnimation = animation;
    animation?.addStatusListener(_onRouteStatus);
    // No route animation means the sheet is not sliding at all (used as a
    // plain widget rather than a modal), so the blur stays on.
    _settled =
        animation == null || animation.status == AnimationStatus.completed;
  }

  void _onRouteStatus(AnimationStatus status) {
    if (!mounted) return;
    final settled = status == AnimationStatus.completed;
    if (settled != _settled) setState(() => _settled = settled);
  }

  @override
  void dispose() {
    _routeAnimation?.removeStatusListener(_onRouteStatus);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * widget.heightFactor;
    return Padding(
      // Lift the sheet above the software keyboard when it appears.
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: GlassSurface(
        thickness: GlassThickness.thick,
        borderRadius: AppRadius.sheetTop,
        constraints: BoxConstraints(maxHeight: maxHeight),
        // No blur while the sheet is in motion — see [_settled].
        backdrop: _settled,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.showHandle)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.md, bottom: 2),
                child: Container(
                  width: 36,
                  height: 5,
                  decoration: BoxDecoration(
                    color: context.palette.border,
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
              ),
            Flexible(child: widget.child),
          ],
        ),
      ),
    );
  }
}
