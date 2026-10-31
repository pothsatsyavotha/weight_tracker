import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/weight_entry.dart';
import '../theme/palette.dart';
import '../utils/format.dart';

class WeightChart extends StatelessWidget {
  final List<WeightEntry> entries;
  const WeightChart({super.key, required this.entries});

  @override
  Widget build(BuildContext context) {
    final first = entries.first.date;
    final last = entries.last.date;
    final span = last.difference(first).inDays.toDouble();
    final maxX = span == 0 ? 1.0 : span;

    final spots = [
      for (final e in entries)
        FlSpot(e.date.difference(first).inDays.toDouble(), e.weight)
    ];
    final weights = entries.map((e) => e.weight);
    final minW = weights.reduce((a, b) => a < b ? a : b);
    final maxW = weights.reduce((a, b) => a > b ? a : b);
    final pad = ((maxW - minW) * 0.2).clamp(0.3, 100.0);

    final dateFmt = DateFormat('d MMM y');
    const grey = TextStyle(color: Colors.grey, fontSize: 13);

    return LineChart(
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      LineChartData(
        minX: 0,
        maxX: maxX,
        minY: minW - pad,
        maxY: maxW + pad,
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(
              color: Colors.grey.shade200, strokeWidth: 1, dashArray: [5, 5]),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(),
          leftTitles: const AxisTitles(),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 44,
              getTitlesWidget: (v, meta) {
                if (v == meta.min || v == meta.max) return const SizedBox();
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  child: Text(fmt(v), style: grey),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              interval: maxX,
              getTitlesWidget: (v, meta) {
                final isFirst = v == 0;
                final isLast = v == maxX;
                if (!isFirst && !isLast) return const SizedBox();
                if (isLast && span == 0) return const SizedBox();
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  space: 10,
                  fitInside: SideTitleFitInsideData.fromTitleMeta(meta),
                  child:
                  Text(dateFmt.format(isFirst ? first : last), style: grey),
                );
              },
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          handleBuiltInTouches: true,
          getTouchedSpotIndicator: (bar, indexes) => [
            for (final _ in indexes)
              TouchedSpotIndicatorData(
                FlLine(color: kPurple.withValues(alpha: 0.4), strokeWidth: 2),
                FlDotData(
                  getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                    radius: 8,
                    color: Colors.white,
                    strokeWidth: 4,
                    strokeColor: kPurple,
                  ),
                ),
              ),
          ],
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => kInk,
            getTooltipItems: (spots) => [
              for (final s in spots)
                LineTooltipItem(
                  '${fmt(s.y)} kg',
                  const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700),
                ),
            ],
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            preventCurveOverShooting: true,
            gradient: const LinearGradient(colors: [kTeal, kBlue, kPurple]),
            barWidth: 4,
            isStrokeCapRound: true,
            dotData: FlDotData(
              getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                radius: 5,
                color: Colors.white,
                strokeWidth: 3,
                strokeColor: kBlue,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  kBlue.withValues(alpha: 0.35),
                  kPurple.withValues(alpha: 0.02),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
