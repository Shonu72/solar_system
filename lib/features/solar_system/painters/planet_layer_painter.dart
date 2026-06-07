import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/math/orbital_engine.dart';
import '../../../core/models/placed_planet.dart';
import '../models/rendered_planet.dart';
import 'planet_surface_painter.dart';

class PlanetLayerPainter extends CustomPainter {
  PlanetLayerPainter({
    required this.planets,
    required this.elapsedSeconds,
    required this.selectedPlanetId,
    required this.hoveredPlanetId,
    required this.showLabels,
    required Listenable repaint,
    this.sceneScale = 1,
    this.engine = const OrbitalEngine(),
  }) : super(repaint: repaint);

  final List<PlacedPlanet> planets;
  final double Function() elapsedSeconds;
  final String? selectedPlanetId;
  final String? hoveredPlanetId;
  final bool showLabels;
  final double sceneScale;
  final OrbitalEngine engine;
  final PlanetSurfacePainter surfacePainter = const PlanetSurfacePainter();

  static const sunRadius = 46.0;

  List<RenderedPlanet> renderItems(Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final elapsed = elapsedSeconds();
    final sorted = engine.sortByDepth(planets, elapsed);
    return sorted.map((placed) {
      final position = engine.positionFor(
        planet: placed.planet,
        elapsedSeconds: elapsed - placed.createdAtSeconds,
        startAngle: placed.startAngle,
      );
      final visualSize = placed.planet.size * position.scale * sceneScale;
      return RenderedPlanet(
        placedPlanet: placed,
        position: position,
        center: Offset(
          center.dx + position.x * sceneScale,
          center.dy + position.y * sceneScale,
        ),
        visualSize: visualSize,
      );
    }).toList();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    _paintSun(canvas, center);

    for (final item in renderItems(size)) {
      _paintPlanet(canvas, item, center);
    }
  }

  void _paintSun(Canvas canvas, Offset center) {
    final seconds = elapsedSeconds();
    final pulse = 0.5 + math.sin(seconds * 1.8) * 0.5;
    final haloPaint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30)
      ..color = const Color(0xFFFFA51F).withValues(alpha: 0.25 + pulse * 0.1);
    final scaledSunRadius = sunRadius * sceneScale;
    canvas.drawCircle(
      center,
      scaledSunRadius * (1.7 + pulse * 0.12),
      haloPaint,
    );

    final glowPaint = Paint()
      ..shader =
          const RadialGradient(
            colors: [
              Color(0xFFFFFFFF),
              Color(0xFFFFD85A),
              Color(0xFFFF7A00),
              Color(0x00FF7A00),
            ],
            stops: [0.05, 0.42, 0.74, 1],
          ).createShader(
            Rect.fromCircle(center: center, radius: scaledSunRadius * 1.45),
          );
    canvas.drawCircle(center, scaledSunRadius * 1.45, glowPaint);

    final surfacePaint = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFFFFF4A8), Color(0xFFFF9D00), Color(0xFFD64500)],
      ).createShader(Rect.fromCircle(center: center, radius: scaledSunRadius));
    canvas.drawCircle(center, scaledSunRadius, surfacePaint);
  }

  void _paintPlanet(Canvas canvas, RenderedPlanet item, Offset sunCenter) {
    final planet = item.placedPlanet.planet;
    final selected = item.placedPlanet.id == selectedPlanetId;
    final hovered = item.placedPlanet.id == hoveredPlanetId;
    final radius = item.visualSize / 2;
    final opacity = item.position.opacity;

    if (selected || hovered) {
      final ringPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = selected ? 2.4 : 1.5
        ..color = const Color(
          0xFF57C8FF,
        ).withValues(alpha: selected ? 0.88 : 0.55);
      canvas.drawCircle(item.center, radius + 8, ringPaint);
    }

    surfacePainter.paintCometTail(canvas, item, elapsedSeconds(), sunCenter);
    surfacePainter.paintRingsBehind(canvas, item, opacity);
    surfacePainter.paintPlanetBody(canvas, item, elapsedSeconds());
    surfacePainter.paintRingsFront(canvas, item, opacity);

    if (showLabels || selected || hovered) {
      final labelStyle = TextStyle(
        color: selected ? const Color(0xFF62C9FF) : Colors.white,
        fontSize: selected ? 14 : 12,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        letterSpacing: 0,
      );
      final label = TextPainter(
        text: TextSpan(text: planet.name, style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: 120);
      label.paint(
        canvas,
        Offset(item.center.dx - label.width / 2, item.center.dy + radius + 8),
      );
    }
  }

  @override
  bool shouldRepaint(covariant PlanetLayerPainter oldDelegate) {
    return oldDelegate.planets != planets ||
        oldDelegate.selectedPlanetId != selectedPlanetId ||
        oldDelegate.hoveredPlanetId != hoveredPlanetId ||
        oldDelegate.showLabels != showLabels ||
        oldDelegate.sceneScale != sceneScale;
  }
}
