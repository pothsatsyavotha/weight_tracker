import 'package:flutter/material.dart';

import '../theme/palette.dart';

class PulseLoader extends StatefulWidget {
  const PulseLoader({super.key});

  @override
  State<PulseLoader> createState() => _PulseLoaderState();
}

class _PulseLoaderState extends State<PulseLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1200))
    ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 90,
      height: 90,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) => Stack(
          alignment: Alignment.center,
          children: [
            for (final o in [0.0, 0.5])
              Opacity(
                opacity: 1 - ((_c.value + o) % 1),
                child: Container(
                  width: 90 * ((_c.value + o) % 1),
                  height: 90 * ((_c.value + o) % 1),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: kPurple, width: 3),
                  ),
                ),
              ),
            Container(
              width: 26,
              height: 26,
              decoration:
              const BoxDecoration(gradient: kMainGradient, shape: BoxShape.circle),
            ),
          ],
        ),
      ),
    );
  }
}
