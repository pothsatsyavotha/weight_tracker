import 'package:flutter/material.dart';

/// Fades in and slides up once when first built.
class FadeSlideIn extends StatelessWidget {
  final Widget child;
  final Duration delay;
  const FadeSlideIn({super.key, required this.child, this.delay = Duration.zero});

  @override
  Widget build(BuildContext context) {
    final total = 450 + delay.inMilliseconds;
    final start = delay.inMilliseconds / total;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: total),
      curve: Interval(start, 1, curve: Curves.easeOutCubic),
      builder: (_, t, child) => Opacity(
        opacity: t.clamp(0.0, 1.0),
        child: Transform.translate(offset: Offset(0, 28 * (1 - t)), child: child),
      ),
      child: child,
    );
  }
}
