import 'package:flutter/material.dart';

import '../models/user_profile.dart';
import '../theme/palette.dart';
import '../utils/bmi.dart';
import '../utils/format.dart';
import 'bouncy.dart';

/// BMI + goal progress + over-limit alert message.
class BmiCard extends StatelessWidget {
  final UserProfile? profile;
  final double? latestWeight;
  final VoidCallback onEdit;
  const BmiCard({
    super.key,
    required this.profile,
    required this.latestWeight,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final p = profile;
    if (p == null) return _SetupPrompt(onTap: onEdit);

    final w = latestWeight ?? p.currentWeight;
    final bmi = bmiOf(w, p.heightCm);
    final cat = bmiCategory(bmi);
    final color = cat == 'Normal'
        ? kGreen
        : (cat == 'Underweight' ? kBlue : kOrange);
    final over = bmi >= kOverweightBmi;
    final overBy = w - healthyMaxKg(p.heightCm);

    final start = p.currentWeight;
    final goal = p.goalWeight;
    final denom = start - goal;
    final reached = denom > 0 ? w <= goal : w >= goal;
    final progress = (denom.abs() < 0.05 || reached)
        ? 1.0
        : ((start - w) / denom).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: over ? Border.all(color: kOrange.withValues(alpha: 0.5), width: 1.5) : null,
        boxShadow: [
          BoxShadow(
              color: kPurple.withValues(alpha: 0.12),
              blurRadius: 26,
              offset: const Offset(0, 12)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('BMI',
                        style: TextStyle(color: Colors.grey, fontSize: 14)),
                    Text(bmi.toStringAsFixed(1),
                        style: TextStyle(
                            fontSize: 34, fontWeight: FontWeight.w900, color: color)),
                    Text('Age ${p.age} · ${p.heightCm.toStringAsFixed(0)} cm',
                        style: const TextStyle(color: Colors.grey, fontSize: 13)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(cat,
                    style: TextStyle(
                        color: color, fontWeight: FontWeight.w700, fontSize: 15)),
              ),
              const SizedBox(width: 6),
              IconButton(
                onPressed: onEdit,
                tooltip: 'Edit goal',
                icon: Icon(Icons.edit_outlined, color: Colors.grey.shade500),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.flag_outlined, size: 18, color: kPurple),
              const SizedBox(width: 6),
              Text('Goal ${fmt(goal)} kg',
                  style: const TextStyle(fontWeight: FontWeight.w700, color: kInk)),
              const Spacer(),
              Text(reached ? 'Goal reached' : '${fmt((w - goal).abs())} kg to go',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: reached ? kGreen : Colors.grey.shade600)),
            ],
          ),
          const SizedBox(height: 8),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progress),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutCubic,
            builder: (_, v, __) => ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: v,
                minHeight: 10,
                backgroundColor: kPurple.withValues(alpha: 0.10),
                valueColor: AlwaysStoppedAnimation(reached ? kGreen : kPurple),
              ),
            ),
          ),
          if (over) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: kOrange.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.warning_amber_rounded, color: kOrange),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'You are ${fmt(overBy)} kg above the healthy range for your height '
                          '(max ≈ ${fmt(healthyMaxKg(p.heightCm))} kg). '
                          'Keep logging your weight and stay on track.',
                      style: const TextStyle(color: kInk, height: 1.35),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SetupPrompt extends StatelessWidget {
  final VoidCallback onTap;
  const _SetupPrompt({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Bouncy(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: kMainGradient,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
                color: kPurple.withValues(alpha: 0.3),
                blurRadius: 22,
                offset: const Offset(0, 10)),
          ],
        ),
        child: const Row(
          children: [
            Icon(Icons.flag_outlined, color: Colors.white, size: 32),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Set your goal',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800)),
                  SizedBox(height: 2),
                  Text('Enter height, age and goal weight to see your BMI.',
                      style: TextStyle(color: Colors.white70)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.white),
          ],
        ),
      ),
    );
  }
}
