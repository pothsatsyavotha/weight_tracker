import 'package:flutter/material.dart';

import '../theme/palette.dart';

class EmptyState extends StatefulWidget {
  const EmptyState({super.key});

  @override
  State<EmptyState> createState() => _EmptyStateState();
}

class _EmptyStateState extends State<EmptyState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1600))
    ..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 320,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _c,
              builder: (_, child) => Transform.translate(
                offset: Offset(0, -12 * Curves.easeInOut.transform(_c.value)),
                child: child,
              ),
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  gradient: kMainGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                        color: kPurple.withValues(alpha: 0.35),
                        blurRadius: 24,
                        offset: const Offset(0, 10)),
                  ],
                ),
                child: const Icon(Icons.monitor_weight_outlined,
                    color: Colors.white, size: 44),
              ),
            ),
            const SizedBox(height: 24),
            const Text('No weight entries in this period',
                style: TextStyle(color: Colors.grey, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
