import 'package:flutter/material.dart';

import '../models/weight_entry.dart';
import '../theme/palette.dart';
import '../utils/format.dart';
import 'delta_chip.dart';
import 'fade_slide_in.dart';
import 'weight_chart.dart';

class StatsCard extends StatelessWidget {
  final List<WeightEntry> entries;
  const StatsCard({super.key, required this.entries});

  @override
  Widget build(BuildContext context) {
    final current = entries.last.weight;
    final change = current - entries.first.weight;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
              color: kPurple.withValues(alpha: 0.12),
              blurRadius: 26,
              offset: const Offset(0, 12)),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Current',
                        style: TextStyle(color: Colors.grey, fontSize: 14)),
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: current),
                      duration: const Duration(milliseconds: 900),
                      curve: Curves.easeOutCubic,
                      builder: (_, v, __) => ShaderMask(
                        shaderCallback: (r) => kMainGradient.createShader(r),
                        child: Text('${fmt(v)} kg',
                            style: const TextStyle(
                                fontSize: 34,
                                fontWeight: FontWeight.w900,
                                color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
              FadeSlideIn(
                delay: const Duration(milliseconds: 300),
                child: DeltaChip(delta: change),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(height: 260, child: WeightChart(entries: entries)),
          const SizedBox(height: 4),
          const Text('Unit: kg',
              style: TextStyle(color: Colors.grey, fontSize: 13)),
        ],
      ),
    );
  }
}
