import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/math/orbital_engine.dart';

class AsteroidBeltPainter extends CustomPainter {
  const AsteroidBeltPainter({
    required this.projector,
    required this.drawFront,
    this.seed = 77,
    this.sceneScale = 1,
  });

  final int seed;
  final double sceneScale;
  final Projector3D projector;
  final bool drawFront;

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(seed);
    final paint = Paint();
    
    // Project the Sun to find its camera depth
    final sunProj = projector.project(0, 0, 0);

    for (var i = 0; i < 420; i++) {
      final angle = random.nextDouble() * math.pi * 2;
      final radius = 252 + random.nextDouble() * 70;
      final yJitter = (random.nextDouble() - 0.5) * 8.0;

      // 3D coordinates in world space (X-Z plane is orbital plane)
      final x3d = radius * math.cos(angle);
      final z3d = radius * math.sin(angle);
      final y3d = yJitter;

      final proj = projector.project(x3d, y3d, z3d);

      // Render only matching depth half
      final isFront = proj.z >= sunProj.z;
      if (isFront != drawFront) {
        continue;
      }

      // Calculate depth-based opacity
      final depthNormalized = ((proj.z - sunProj.z) / 400.0 + 0.5).clamp(0.0, 1.0);

      final sizePx = (0.45 + random.nextDouble() * 1.5) * sceneScale * projector.zoom * proj.scale;
      paint.color = Color.lerp(
        const Color(0xFF8C704C),
        const Color(0xFFD7BC8A),
        random.nextDouble(),
      )!.withValues(alpha: (0.16 + depthNormalized * 0.34).clamp(0.0, 1.0));

      canvas.drawCircle(Offset(proj.x, proj.y), sizePx, paint);
    }
  }

  @override
  bool shouldRepaint(covariant AsteroidBeltPainter oldDelegate) {
    return oldDelegate.seed != seed ||
        oldDelegate.sceneScale != sceneScale ||
        oldDelegate.drawFront != drawFront ||
        oldDelegate.projector.azimuth != projector.azimuth ||
        oldDelegate.projector.elevation != projector.elevation ||
        oldDelegate.projector.zoom != projector.zoom ||
        oldDelegate.projector.target.x != projector.target.x ||
        oldDelegate.projector.target.y != projector.target.y ||
        oldDelegate.projector.target.z != projector.target.z;
  }
}

