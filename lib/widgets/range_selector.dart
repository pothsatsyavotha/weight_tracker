import 'package:flutter/material.dart';

import '../models/range.dart';
import '../theme/palette.dart';

class RangeSelector extends StatelessWidget {
  final Range value;
  final ValueChanged<Range> onChanged;
  const RangeSelector({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
              color: kPurple.withValues(alpha: 0.10),
              blurRadius: 16,
              offset: const Offset(0, 6)),
        ],
      ),
      child: LayoutBuilder(builder: (context, box) {
        final w = box.maxWidth / Range.values.length;
        return SizedBox(
          height: 42,
          child: Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 380),
                curve: Curves.easeOutBack,
                left: value.index * w,
                top: 0,
                bottom: 0,
                width: w,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: kMainGradient,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                          color: kBlue.withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 4)),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  for (final r in Range.values)
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => onChanged(r),
                        child: Center(
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 250),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: r == value
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: r == value ? Colors.white : kInk,
                            ),
                            child: Text(r.label),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      }),
    );
  }
}
