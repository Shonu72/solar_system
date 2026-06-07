import 'dart:math' as math;

import 'package:flutter/material.dart';

class StarFieldPainter extends CustomPainter {
  const StarFieldPainter({this.seed = 42, this.showStars = true});

  final int seed;
  final bool showStars;

  @override
  void paint(Canvas canvas, Size size) {
    final background = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF020611), Color(0xFF081827), Color(0xFF01030A)],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, background);

    if (!showStars) {
      return;
    }

    final random = math.Random(seed);
    for (var i = 0; i < 260; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final tier = random.nextDouble();
      final radius = tier > 0.965
          ? 1.9
          : tier > 0.83
          ? 1.15
          : 0.55;
      final alpha = tier > 0.965
          ? 0.92
          : tier > 0.83
          ? 0.72
          : 0.42;
      final paint = Paint()
        ..color = Color.lerp(
          const Color(0xFF9ED5FF),
          Colors.white,
          random.nextDouble(),
        )!.withValues(alpha: alpha);
      canvas.drawCircle(Offset(x, y), radius, paint);
    }

    final nebula = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 28)
      ..color = const Color(0xFF2B6CB0).withValues(alpha: 0.08);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.58, size.height * 0.42),
        width: size.width * 0.52,
        height: size.height * 0.28,
      ),
      nebula,
    );
  }

  @override
  bool shouldRepaint(covariant StarFieldPainter oldDelegate) {
    return oldDelegate.showStars != showStars || oldDelegate.seed != seed;
  }
}
