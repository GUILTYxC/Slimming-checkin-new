import 'package:flutter/material.dart';

/// Smoothly tweens a numeric value when it *changes*, formatting each frame
/// with [formatter].
///
/// The count starts from the value itself, not from zero. A stat that climbs
/// up from zero every time its page is re-entered reads as a loading glitch
/// rather than as motion — it is noise on every navigation, and it hides the
/// one moment a count-up is actually informative: when the number really
/// moves, e.g. a fresh weigh-in landing. So the tween only departs from the
/// current value when that value changes.
class AnimatedCount extends StatefulWidget {
  const AnimatedCount({
    super.key,
    required this.value,
    required this.formatter,
    this.style,
    this.duration = const Duration(milliseconds: 900),
    this.curve = Curves.easeOutCubic,
  });

  final double value;
  final String Function(double) formatter;
  final TextStyle? style;
  final Duration duration;
  final Curve curve;

  @override
  State<AnimatedCount> createState() => _AnimatedCountState();
}

class _AnimatedCountState extends State<AnimatedCount> {
  /// Where the next tween starts.
  ///
  /// Initialised to the value itself, so the first build — and every rebuild
  /// that follows a navigation — resolves to a tween with no distance to
  /// cover and simply shows the number. It only becomes a real starting point
  /// in [didUpdateWidget], when the incoming value differs from the old one.
  late double _from = widget.value;

  @override
  void didUpdateWidget(AnimatedCount oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) _from = oldWidget.value;
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: _from, end: widget.value),
      duration: widget.duration,
      curve: widget.curve,
      builder: (context, v, _) => Text(widget.formatter(v), style: widget.style),
    );
  }
}
