import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/utils/app_date.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/dashboard_stats.dart';
import '../../core/theme/app_palette.dart';

/// Simple trailing moving average over the last [window] spots.
List<FlSpot> _movingAverage(List<FlSpot> spots, int window) {
  if (spots.length < 2) return spots;
  final out = <FlSpot>[];
  for (var i = 0; i < spots.length; i++) {
    final start = math.max(0, i - window + 1);
    var sum = 0.0;
    for (var j = start; j <= i; j++) {
      sum += spots[j].y;
    }
    out.add(FlSpot(spots[i].x, sum / (i - start + 1)));
  }
  return out;
}

/// Smooth weight-trend line with a soft gradient fill and a dashed goal line.
class WeightLineChart extends StatelessWidget {
  const WeightLineChart({
    super.key,
    required this.points,
    required this.unit,
    required this.targetKg,
    this.height = 190,
  });

  final List<WeightPoint> points;
  final WeightUnit unit;
  final double targetKg;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final values = [for (final p in points) unit.fromKg(p.kg)];
    final target = unit.fromKg(targetKg);
    final allValues = [...values, target];
    final minV = allValues.reduce(math.min);
    final maxV = allValues.reduce(math.max);
    final pad = math.max(1.0, (maxV - minV) * 0.25);
    final yInterval = math.max(1.0, ((maxV - minV) + 2 * pad) / 4);

    final spots = [
      for (var i = 0; i < values.length; i++) FlSpot(i.toDouble(), values[i]),
    ];

    return SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          minY: minV - pad,
          maxY: maxV + pad,
          minX: 0,
          maxX: (points.length - 1).clamp(1, 9999).toDouble(),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: yInterval,
            getDrawingHorizontalLine:
                (_) => FlLine(color: context.palette.divider, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                interval: yInterval,
                getTitlesWidget: (value, meta) {
                  // Hide labels hugging the top/bottom edge so the number
                  // never overlaps the chart edge or neighbouring text.
                  if (value > meta.max - yInterval * 0.5 ||
                      value < meta.min + yInterval * 0.5) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Text(
                      value.toStringAsFixed(0),
                      style: TextStyle(
                        color: context.palette.textTertiary,
                        fontSize: 11,
                      ),
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final i = value.round();
                  if (i < 0 || i >= points.length) {
                    return const SizedBox.shrink();
                  }
                  // Show at most ~4 labels to avoid clutter.
                  final step = (points.length / 4).ceil().clamp(1, 9999);
                  if (i % step != 0 && i != points.length - 1) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      AppDate.monthDay(points[i].date),
                      style: TextStyle(
                        color: context.palette.textTertiary,
                        fontSize: 10.5,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => context.palette.surface,
              tooltipRoundedRadius: 12,
              tooltipPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              getTooltipItems:
                  (spots) => [
                    for (final s in spots)
                      LineTooltipItem(
                        '${AppDate.monthDay(points[s.x.toInt()].date)}\n',
                        TextStyle(
                          color: context.palette.textTertiary,
                          fontSize: 11,
                        ),
                        children: [
                          TextSpan(
                            text: '${s.y.toStringAsFixed(1)} ${unit.suffix}',
                            style: TextStyle(
                              color: context.palette.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                  ],
            ),
          ),
          extraLinesData: ExtraLinesData(
            horizontalLines: [
              HorizontalLine(
                y: target,
                color: context.palette.border,
                strokeWidth: 1.4,
                dashArray: [5, 4],
                label: HorizontalLineLabel(
                  show: true,
                  alignment: Alignment.topRight,
                  style: TextStyle(
                    color: context.palette.textTertiary,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                  labelResolver: (_) => '目标 ${target.toStringAsFixed(0)}',
                ),
              ),
            ],
          ),
          lineBarsData: [
            if (spots.length >= 3)
              LineChartBarData(
                spots: _movingAverage(spots, 7),
                isCurved: true,
                curveSmoothness: 0.2,
                color: context.palette.weight.withValues(alpha: 0.35),
                barWidth: 1.4,
                isStrokeCapRound: true,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(show: false),
              ),
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.32,
              color: context.palette.weight,
              barWidth: 2.6,
              isStrokeCapRound: true,
              // Only the most recent reading gets a dot, so the line stays
              // quiet and the eye lands on today's value.
              dotData: FlDotData(
                show: true,
                checkToShowDot:
                    (spot, _) => spot.x == (points.length - 1).toDouble(),
                getDotPainter:
                    (spot, _, __, ___) => FlDotCirclePainter(
                      radius: 4.2,
                      color: context.palette.weight,
                      strokeWidth: 2.4,
                      strokeColor: Colors.white,
                    ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    context.palette.weight.withValues(alpha: 0.22),
                    context.palette.weight.withValues(alpha: 0.02),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Seven-day calorie bar chart with gradient rods and weekday labels.
class CalorieBarChart extends StatelessWidget {
  const CalorieBarChart({super.key, required this.points, this.height = 170});

  final List<CaloriePoint> points;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final maxKcal = points.fold<double>(0, (m, p) => math.max(m, p.kcal));
    final maxY = maxKcal <= 0 ? 100.0 : maxKcal * 1.25;

    return SizedBox(
      height: height,
      child: BarChart(
        BarChartData(
          maxY: maxY,
          alignment: BarChartAlignment.spaceAround,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => context.palette.surface,
              tooltipRoundedRadius: 12,
              tooltipPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              getTooltipItem:
                  (group, groupIndex, rod, rodIndex) => BarTooltipItem(
                    '${rod.toY.round()} 千卡',
                    TextStyle(
                      color: context.palette.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY / 3,
            getDrawingHorizontalLine:
                (_) => FlLine(color: context.palette.divider, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 38,
                interval: maxY / 3,
                getTitlesWidget: (value, meta) {
                  // Hide the top-edge label so it doesn't overlap the chart top.
                  if (value > meta.max - (maxY / 3) * 0.5) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Text(
                      value.toStringAsFixed(0),
                      style: TextStyle(
                        color: context.palette.textTertiary,
                        fontSize: 11,
                      ),
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                getTitlesWidget: (value, meta) {
                  final i = value.round();
                  if (i < 0 || i >= points.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      AppDate.shortWeekday(points[i].date),
                      style: TextStyle(
                        color: context.palette.textTertiary,
                        fontSize: 11,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: [
            for (var i = 0; i < points.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: points[i].kcal,
                    width: 16,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(6),
                    ),
                    color: context.palette.calorie,
                    backDrawRodData: BackgroundBarChartRodData(
                      show: true,
                      toY: maxY,
                      color: context.palette.fillInset,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// Body-fat percentage trend line with a soft gradient fill.
class BodyFatLineChart extends StatelessWidget {
  const BodyFatLineChart({super.key, required this.points, this.height = 190});

  final List<BodyFatPoint> points;
  final double? height;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text(
            '打卡时记录体脂率后，这里会显示趋势',
            style: TextStyle(color: context.palette.textTertiary, fontSize: 12.5),
          ),
        ),
      );
    }

    final values = [for (final p in points) p.percent];
    final minV = values.reduce(math.min);
    final maxV = values.reduce(math.max);
    final pad = math.max(1.0, (maxV - minV) * 0.25);
    final yInterval = math.max(1.0, ((maxV - minV) + 2 * pad) / 4);

    final spots = [
      for (var i = 0; i < values.length; i++) FlSpot(i.toDouble(), values[i]),
    ];

    return SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          minY: minV - pad,
          maxY: maxV + pad,
          minX: 0,
          maxX: (points.length - 1).clamp(1, 9999).toDouble(),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: yInterval,
            getDrawingHorizontalLine:
                (_) => FlLine(color: context.palette.divider, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                interval: yInterval,
                getTitlesWidget: (value, meta) {
                  // Hide labels hugging the top/bottom edge so the number
                  // never overlaps the chart edge or neighbouring text.
                  if (value > meta.max - yInterval * 0.5 ||
                      value < meta.min + yInterval * 0.5) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Text(
                      Formatters.bodyFat(value, withSuffix: false),
                      style: TextStyle(
                        color: context.palette.textTertiary,
                        fontSize: 11,
                      ),
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final i = value.round();
                  if (i < 0 || i >= points.length) {
                    return const SizedBox.shrink();
                  }
                  // Show at most ~4 labels to avoid clutter.
                  final step = (points.length / 4).ceil().clamp(1, 9999);
                  if (i % step != 0 && i != points.length - 1) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      AppDate.monthDay(points[i].date),
                      style: TextStyle(
                        color: context.palette.textTertiary,
                        fontSize: 10.5,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => context.palette.surface,
              tooltipRoundedRadius: 12,
              tooltipPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              getTooltipItems:
                  (spots) => [
                    for (final s in spots)
                      LineTooltipItem(
                        '${AppDate.monthDay(points[s.x.toInt()].date)}\n',
                        TextStyle(
                          color: context.palette.textTertiary,
                          fontSize: 11,
                        ),
                        children: [
                          TextSpan(
                            text: Formatters.bodyFat(s.y),
                            style: TextStyle(
                              color: context.palette.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                  ],
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.32,
              color: context.palette.bodyFat,
              barWidth: 2.6,
              isStrokeCapRound: true,
              // Only the most recent reading gets a dot.
              dotData: FlDotData(
                show: true,
                checkToShowDot:
                    (spot, _) => spot.x == (points.length - 1).toDouble(),
                getDotPainter:
                    (spot, _, __, ___) => FlDotCirclePainter(
                      radius: 4.2,
                      color: context.palette.bodyFat,
                      strokeWidth: 2.4,
                      strokeColor: Colors.white,
                    ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    context.palette.bodyFat.withValues(alpha: 0.22),
                    context.palette.bodyFat.withValues(alpha: 0.02),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
