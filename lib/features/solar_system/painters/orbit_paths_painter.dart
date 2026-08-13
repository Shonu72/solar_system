import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/math/orbital_engine.dart';
import '../../../core/models/planet_model.dart';

class OrbitPathsPainter extends CustomPainter {
  const OrbitPathsPainter({
    required this.planets,
    required this.showLabels,
    required this.projector,
    this.highlightOrbitIndex,
    this.sceneScale = 1,
  });

  final List<PlanetModel> planets;
  final bool showLabels;
  final int? highlightOrbitIndex;
  final double sceneScale;
  final Projector3D projector;

  @override
  void paint(Canvas canvas, Size size) {
    final planePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8)
      ..color = const Color(0xFF5BA9FF).withValues(alpha: 0.08);

    // Draw the overall plane boundary in 3D (a large circle of radius 530)
    final boundaryPath = Path();
    const segments = 120;
    for (var i = 0; i <= segments; i++) {
      final theta = (i * 2 * math.pi) / segments;
      final x = 530 * math.cos(theta);
      final z = 530 * math.sin(theta);
      final proj = projector.project(x, 0.0, z);
      if (i == 0) {
        boundaryPath.moveTo(proj.x, proj.y);
      } else {
        boundaryPath.lineTo(proj.x, proj.y);
      }
    }
    canvas.drawPath(boundaryPath, planePaint);

    for (var index = planets.length - 1; index >= 0; index--) {
      final planet = planets[index];
      final highlighted = index == highlightOrbitIndex;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = highlighted ? 2.2 : 1.0
        ..color = highlighted
            ? const Color(0xFF4DB7FF).withValues(alpha: 0.82)
            : const Color(0xFF9AB8D8).withValues(alpha: 0.22);

      final rx = planet.orbitRadius;
      final rz = planet.orbitRadius;

      final path = Path();
      for (var i = 0; i <= segments; i++) {
        final theta = (i * 2 * math.pi) / segments;
        final x = rx * math.cos(theta);
        final z = rz * math.sin(theta);
        final proj = projector.project(x, 0.0, z);
        if (i == 0) {
          path.moveTo(proj.x, proj.y);
        } else {
          path.lineTo(proj.x, proj.y);
        }
      }
      canvas.drawPath(path, paint);
    }

    if (!showLabels) {
      return;
    }

    final labelPaint = Paint()..color = Colors.white.withValues(alpha: 0.72);
    final textStyle = const TextStyle(
      color: Color(0xFFCFE8FF),
      fontSize: 11,
      letterSpacing: 0,
    );

    for (var index = 0; index < planets.length; index++) {
      final planet = planets[index];
      final highlighted = index == highlightOrbitIndex;
      if (!highlighted && index.isOdd) {
        continue;
      }
      final label = TextPainter(
        text: TextSpan(text: planet.name, style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();

      final proj = projector.project(planet.orbitRadius, 0.0, 0.0);
      final offset = Offset(proj.x + 10, proj.y - label.height / 2);

      canvas.drawCircle(offset + const Offset(-6, 8), 2.5, labelPaint);
      label.paint(canvas, offset);
    }
  }

  @override
  bool shouldRepaint(covariant OrbitPathsPainter oldDelegate) {
    return oldDelegate.planets != planets ||
        oldDelegate.showLabels != showLabels ||
        oldDelegate.highlightOrbitIndex != highlightOrbitIndex ||
        oldDelegate.sceneScale != sceneScale ||
        oldDelegate.projector.azimuth != projector.azimuth ||
        oldDelegate.projector.elevation != projector.elevation ||
        oldDelegate.projector.zoom != projector.zoom ||
        oldDelegate.projector.target.x != projector.target.x ||
        oldDelegate.projector.target.y != projector.target.y ||
        oldDelegate.projector.target.z != projector.target.z;
  }
}

