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
    // Softer, slightly longer entrance than the Material default so the
    // sheet never reads as a hard cut from transparent to opaque.
    transitionAnimationController: AnimationController(
      vsync: Navigator.of(context),
      duration: const Duration(milliseconds: 320),
      reverseDuration: const Duration(milliseconds: 240),
    ),
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
  /// Continuous 0..1 blur strength, driven by the route entrance animation.
  ///
  /// A backdrop blur re-samples everything behind the pane, so a full blur
  /// during the slide costs one offscreen pass per frame and stutters. The
  /// blur is kept at 0 for the first half of the slide, then *ramps* to 1
  /// over the second half and parks there. Ramping with the slide (instead
  /// of snapping on after the sheet stops) is what keeps the pane from
  /// looking like it suddenly went opaque.
  double _blur = 0;

  Animation<double>? _routeAnimation;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final animation = ModalRoute.of(context)?.animation;
    if (animation == _routeAnimation) return;
    _routeAnimation?.removeListener(_onRouteTick);
    _routeAnimation = animation;
    animation?.addListener(_onRouteTick);
    // No route animation means the sheet is not sliding at all (used as a
    // plain widget rather than a modal), so the blur stays fully on.
    _blur = animation == null ? 1.0 : _blurFor(animation.value);
  }

  void _onRouteTick() {
    if (!mounted) return;
    final t = _routeAnimation?.value ?? 1.0;
    final next = _blurFor(t);
    if ((next - _blur).abs() < 0.01) return;
    setState(() => _blur = next);
  }

  /// 0 for the first 55% of the entrance, smoothstep up to 1 by the end.
  /// On the way out the same curve runs backwards, so dismiss softens too.
  double _blurFor(double t) {
    if (t <= 0.55) return 0;
    if (t >= 1) return 1;
    final u = (t - 0.55) / 0.45;
    // Smoothstep: C1-continuous, no corner at the ramp edges.
    return u * u * (3 - 2 * u);
  }

  @override
  void dispose() {
    _routeAnimation?.removeListener(_onRouteTick);
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
        blurStrength: _blur,
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
