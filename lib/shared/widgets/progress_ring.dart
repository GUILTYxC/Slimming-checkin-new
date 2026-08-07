import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Circular progress indicator with a gradient stroke that animates whenever
/// [progress] (0..1) changes. Optionally shows a [center] widget in the middle.
class ProgressRing extends StatelessWidget {
  const ProgressRing({
    super.key,
    required this.progress,
    this.size = 190,
    this.stroke = 16,
    this.center,
    this.gradient = AppColors.primaryGradient,
    this.trackColor = AppColors.surfaceMuted,
    this.duration = const Duration(milliseconds: 1200),
  });

  final double progress;
  final double size;
  final double stroke;
  final Widget? center;
  final List<Color> gradient;
  final Color trackColor;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: progress.clamp(0.0, 1.0).toDouble()),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _RingPainter(
              progress: value,
              stroke: stroke,
              gradient: gradient,
              trackColor: trackColor,
            ),
            child: Center(child: center),
          ),
        );
      },
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.stroke,
    required this.gradient,
    required this.trackColor,
  });

  final double progress;
  final double stroke;
  final List<Color> gradient;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - stroke) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    const startAngle = -math.pi / 2;
    final sweep = 2 * math.pi * progress;

    final track =
        Paint()
          ..color = trackColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 0, 2 * math.pi, false, track);

    if (progress <= 0) return;

    final fg =
        Paint()
          ..shader = SweepGradient(
            startAngle: startAngle,
            endAngle: startAngle + 2 * math.pi,
            colors: gradient,
            transform: const GradientRotation(-math.pi / 2),
          ).createShader(rect)
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, startAngle, sweep, false, fg);

    // Glowing cap at the leading edge of the progress arc.
    final endAngle = startAngle + sweep;
    final tip = Offset(
      center.dx + radius * math.cos(endAngle),
      center.dy + radius * math.sin(endAngle),
    );
    final glow =
        Paint()
          ..color = gradient.last.withValues(alpha: 0.30)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(tip, stroke * 0.62, glow);
    canvas.drawCircle(tip, stroke * 0.34, Paint()..color = Colors.white);
    canvas.drawCircle(tip, stroke * 0.22, Paint()..color = gradient.last);
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress ||
      old.stroke != stroke ||
      old.trackColor != trackColor;
}
