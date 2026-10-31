import 'package:flutter/material.dart';

import '../theme/palette.dart';
import '../utils/format.dart';

class DeltaChip extends StatelessWidget {
  final double delta;
  final bool small;
  const DeltaChip({super.key, required this.delta, this.small = false});

  @override
  Widget build(BuildContext context) {
    final down = delta < 0;
    final flat = delta == 0;
    final color = flat ? Colors.grey : (down ? kGreen : kOrange);
    final icon = flat
        ? Icons.remove
        : (down ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      padding: EdgeInsets.symmetric(
          horizontal: small ? 8 : 12, vertical: small ? 3 : 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: small ? 14 : 18, color: color),
          const SizedBox(width: 2),
          Text('${fmt(delta.abs())} kg',
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: small ? 13 : 16)),
        ],
      ),
    );
  }
}
