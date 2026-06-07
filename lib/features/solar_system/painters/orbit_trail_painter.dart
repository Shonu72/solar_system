import 'package:flutter/material.dart';

import '../../../core/math/orbital_engine.dart';
import '../../../core/models/placed_planet.dart';

class OrbitTrailPainter extends CustomPainter {
  OrbitTrailPainter({
    required this.planets,
    required this.elapsedSeconds,
    required this.projector,
    required Listenable repaint,
    this.sceneScale = 1,
    this.engine = const OrbitalEngine(),
  }) : super(repaint: repaint);

  final List<PlacedPlanet> planets;
  final double Function() elapsedSeconds;
  final double sceneScale;
  final OrbitalEngine engine;
  final Projector3D projector;

  @override
  void paint(Canvas canvas, Size size) {
    final elapsed = elapsedSeconds();
    for (final placed in planets) {
      final samples = engine.trailSamples3D(
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
        final alpha = (1.0 - index / samples.length) * 0.34;
        final paint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = (placed.planet.isComet ? 2.1 : 1.35) * sceneScale
          ..strokeCap = StrokeCap.round
          ..color = (placed.planet.trailColor ?? placed.planet.colors.first)
              .withValues(alpha: alpha);

        final proj1 = projector.project(samples[index].x, samples[index].y, samples[index].z);
        final proj2 = projector.project(samples[index + 1].x, samples[index + 1].y, samples[index + 1].z);

        canvas.drawLine(
          Offset(proj1.x, proj1.y),
          Offset(proj2.x, proj2.y),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant OrbitTrailPainter oldDelegate) {
    return oldDelegate.planets != planets ||
        oldDelegate.sceneScale != sceneScale ||
        oldDelegate.projector.azimuth != projector.azimuth ||
        oldDelegate.projector.elevation != projector.elevation ||
        oldDelegate.projector.zoom != projector.zoom ||
        oldDelegate.projector.target.x != projector.target.x ||
        oldDelegate.projector.target.y != projector.target.y ||
        oldDelegate.projector.target.z != projector.target.z;
  }
}

