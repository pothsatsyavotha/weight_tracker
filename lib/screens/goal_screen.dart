import 'package:flutter/material.dart';

import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../theme/palette.dart';
import '../utils/bmi.dart';
import '../utils/format.dart';
import '../widgets/app_background.dart';
import '../widgets/app_text_field.dart';
import '../widgets/gradient_button.dart';

/// Goal & BMI setup: height, age, current weight, goal weight.
class GoalScreen extends StatefulWidget {
  final AuthService auth;
  const GoalScreen({super.key, required this.auth});

  @override
  State<GoalScreen> createState() => _GoalScreenState();
}

class _GoalScreenState extends State<GoalScreen> {
  late final TextEditingController _height;
  late final TextEditingController _age;
  late final TextEditingController _weight;
  late final TextEditingController _goal;
  String? _err;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final p = widget.auth.current?.profile;
    String s(num? v, {int d = 1}) => v == null ? '' : v.toStringAsFixed(d);
    _height = TextEditingController(text: s(p?.heightCm, d: 0));
    _age = TextEditingController(text: s(p?.age, d: 0));
    _weight = TextEditingController(text: s(p?.currentWeight));
    _goal = TextEditingController(text: s(p?.goalWeight));
  }

  @override
  void dispose() {
    _height.dispose();
    _age.dispose();
    _weight.dispose();
    _goal.dispose();
    super.dispose();
  }

  double? _num(TextEditingController c) =>
      double.tryParse(c.text.trim().replaceAll(',', '.'));

  Future<void> _save() async {
    final h = _num(_height);
    final a = _num(_age)?.round();
    final w = _num(_weight);
    final g = _num(_goal);

    String? err;
    if (h == null || h < 100 || h > 250) {
      err = 'Enter a height between 100 and 250 cm';
    } else if (a == null || a < 5 || a > 120) {
      err = 'Enter a valid age';
    } else if (w == null || w < 20 || w > 400) {
      err = 'Enter a valid current weight in kg';
    } else if (g == null || g < 20 || g > 400) {
      err = 'Enter a valid goal weight in kg';
    } else if (bmiOf(g, h) < kUnderweightBmi) {
      err = 'That goal is underweight (BMI under 18.5). '
          'Choose at least ${fmt(healthyMinKg(h))} kg.';
    }
    if (err != null) {
      setState(() => _err = err);
      return;
    }

    setState(() => _busy = true);
    await widget.auth.updateProfile(UserProfile(
      heightCm: h!,
      age: a!,
      currentWeight: w!,
      goalWeight: g!,
    ));
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final h = _num(_height);
    final w = _num(_weight);
    final canPreview = h != null && h >= 100 && h <= 250 && w != null && w >= 20;
    final bmi = canPreview ? bmiOf(w, h) : null;
    final cat = bmi == null ? null : bmiCategory(bmi);
    final color = cat == 'Normal' ? kGreen : (cat == 'Underweight' ? kBlue : kOrange);

    void changed(String _) => setState(() => _err = null);

    return AppBackground(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          scrolledUnderElevation: 0,
          centerTitle: true,
          title: ShaderMask(
            shaderCallback: (r) => kMainGradient.createShader(r),
            child: const Text('Goal & BMI',
                style: TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 22, color: Colors.white)),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          children: [
            AppTextField(
              controller: _height,
              label: 'Height',
              suffix: 'cm',
              icon: Icons.height,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: changed,
            ),
            const SizedBox(height: 14),
            AppTextField(
              controller: _age,
              label: 'Age',
              suffix: 'years',
              icon: Icons.cake_outlined,
              keyboardType: TextInputType.number,
              onChanged: changed,
            ),
            const SizedBox(height: 14),
            AppTextField(
              controller: _weight,
              label: 'Current weight',
              suffix: 'kg',
              icon: Icons.monitor_weight_outlined,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: changed,
            ),
            const SizedBox(height: 14),
            AppTextField(
              controller: _goal,
              label: 'Goal weight',
              suffix: 'kg',
              icon: Icons.flag_outlined,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: changed,
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 18),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: bmi == null
                  ? const SizedBox(key: ValueKey('none'))
                  : Container(
                key: const ValueKey('preview'),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Your BMI: ${bmi.toStringAsFixed(1)} · $cat',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: color)),
                    const SizedBox(height: 4),
                    Text(
                      'Healthy weight for your height: '
                          '${fmt(healthyMinKg(h!))} – ${fmt(healthyMaxKg(h))} kg',
                      style: const TextStyle(color: kInk),
                    ),
                  ],
                ),
              ),
            ),
            if (_err != null) ...[
              const SizedBox(height: 12),
              Text(_err!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Color(0xFFE53935), fontWeight: FontWeight.w600)),
            ],
            const SizedBox(height: 22),
            GradientButton(label: 'Save', busy: _busy, onTap: _save),
          ],
        ),
      ),
    );
  }
}
