import 'dart:math' as math;

import 'package:flutter/material.dart';

class AsteroidBeltPainter extends CustomPainter {
  const AsteroidBeltPainter({this.seed = 77});

  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final random = math.Random(seed);
    final paint = Paint();

    for (var i = 0; i < 420; i++) {
      final angle = random.nextDouble() * math.pi * 2;
      final radius = 252 + random.nextDouble() * 70;
      final heightScale = 0.32 + random.nextDouble() * 0.04;
      final jitter = Offset(
        (random.nextDouble() - 0.5) * 10,
        (random.nextDouble() - 0.5) * 5,
      );
      final depth = (math.sin(angle) + 1) / 2;
      final point =
          Offset(
            center.dx + math.cos(angle) * radius,
            center.dy + math.sin(angle) * radius * heightScale,
          ) +
          jitter;
      final sizePx = 0.45 + random.nextDouble() * 1.5 + depth * 0.55;
      paint.color = Color.lerp(
        const Color(0xFF8C704C),
        const Color(0xFFD7BC8A),
        random.nextDouble(),
      )!.withValues(alpha: 0.16 + depth * 0.34);
      canvas.drawCircle(point, sizePx, paint);
    }
  }

  @override
  bool shouldRepaint(covariant AsteroidBeltPainter oldDelegate) {
    return oldDelegate.seed != seed;
  }
}
