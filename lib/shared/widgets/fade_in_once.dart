import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/app_tokens.dart';

/// Fades [child] in once per widget lifetime.
///
/// The tab shell keeps pages alive, so a plain `.animate().fadeIn()` would
/// re-stagger every time the user returns to a tab. This drops the animation
/// layer after the first play and rebuilds as a plain child thereafter.
class FadeInOnce extends StatefulWidget {
  const FadeInOnce({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration,
  });

  final Widget child;
  final Duration delay;
  final Duration? duration;

  @override
  State<FadeInOnce> createState() => _FadeInOnceState();
}

class _FadeInOnceState extends State<FadeInOnce> {
  bool _done = false;

  @override
  Widget build(BuildContext context) {
    if (_done) return widget.child;
    return widget.child
        .animate(
          delay: widget.delay,
          onComplete: (_) {
            if (mounted) setState(() => _done = true);
          },
        )
        .fadeIn(
          duration: widget.duration ?? const Duration(milliseconds: 300),
          curve: AppMotion.emphasized,
        )
        .slideY(
          begin: 0.04,
          end: 0,
          curve: AppMotion.emphasized,
          duration: widget.duration ?? const Duration(milliseconds: 300),
        );
  }
}
