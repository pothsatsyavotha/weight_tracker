import 'package:flutter/material.dart';

import '../theme/palette.dart';
import 'bouncy.dart';

class GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool busy;
  const GradientButton(
      {super.key, required this.label, this.onTap, this.busy = false});

  @override
  Widget build(BuildContext context) {
    return Bouncy(
      onTap: busy ? null : onTap,
      child: Container(
        height: 54,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: kMainGradient,
          borderRadius: BorderRadius.circular(27),
          boxShadow: [
            BoxShadow(
                color: kBlue.withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 7)),
          ],
        ),
        child: busy
            ? const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white))
            : Text(label,
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
      ),
    );
  }
}
