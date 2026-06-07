import 'package:flutter/material.dart';

import '../../../core/math/orbital_engine.dart';
import '../../../core/models/placed_planet.dart';

class OrbitTrailPainter extends CustomPainter {
  OrbitTrailPainter({
    required this.planets,
    required this.elapsedSeconds,
    required Listenable repaint,
    this.engine = const OrbitalEngine(),
  }) : super(repaint: repaint);

  final List<PlacedPlanet> planets;
  final double Function() elapsedSeconds;
  final OrbitalEngine engine;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final elapsed = elapsedSeconds();
    for (final placed in planets) {
      final samples = engine.trailSamples(
        planet: placed.planet,
        elapsedSeconds: elapsed - placed.createdAtSeconds,
        startAngle: placed.startAngle,
        sampleCount: placed.planet.isComet ? 28 : 18,
        sampleSpacingSeconds: placed.planet.isComet ? 0.22 : 0.16,
      );
      if (samples.length < 2) {
        continue;
      }

      for (var index = 0; index < samples.length - 1; index++) {
        final alpha = (1 - index / samples.length) * 0.34;
        final paint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = placed.planet.isComet ? 2.1 : 1.35
          ..strokeCap = StrokeCap.round
          ..color = (placed.planet.trailColor ?? placed.planet.colors.first)
              .withValues(alpha: alpha);
        canvas.drawLine(
          center + samples[index],
          center + samples[index + 1],
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant OrbitTrailPainter oldDelegate) {
    return oldDelegate.planets != planets;
  }
}
