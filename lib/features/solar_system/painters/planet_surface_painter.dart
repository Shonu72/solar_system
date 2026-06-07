import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/math/orbital_engine.dart';
import '../../../core/models/planet_model.dart';
import '../models/rendered_planet.dart';

class PlanetSurfacePainter {
  const PlanetSurfacePainter({this.engine = const OrbitalEngine()});

  final OrbitalEngine engine;

  void paintRingsBehind(Canvas canvas, RenderedPlanet item, double opacity, Projector3D projector) {
    final planet = item.placedPlanet.planet;
    if (!planet.hasRing) {
      return;
    }
    _paintRingArc(canvas, item, opacity, projector, drawFront: false);
  }

  void paintRingsFront(Canvas canvas, RenderedPlanet item, double opacity, Projector3D projector) {
    final planet = item.placedPlanet.planet;
    if (!planet.hasRing) {
      return;
    }
    _paintRingArc(canvas, item, opacity, projector, drawFront: true);
  }

  void paintCometTail(
    Canvas canvas,
    RenderedPlanet item,
    double elapsedSeconds,
    Offset sunCenter,
  ) {
    final planet = item.placedPlanet.planet;
    if (!planet.isComet) {
      return;
    }

    final activity = engine.cometActivity(
      planet: planet,
      elapsedSeconds: elapsedSeconds - item.placedPlanet.createdAtSeconds,
      startAngle: item.placedPlanet.startAngle,
    );
    final radius = item.visualSize / 2;
    final fromSun = item.center - sunCenter;
    final direction = fromSun.distance == 0
        ? const Offset(-1, 0)
        : fromSun / fromSun.distance;
    final normal = Offset(-direction.dy, direction.dx);
    final length = radius * (7.5 + activity * 8);
    final width = radius * (1.2 + activity * 1.3);
    final end = item.center + direction * length;

    final tail = Path()
      ..moveTo(
        item.center.dx + normal.dx * radius * 0.5,
        item.center.dy + normal.dy * radius * 0.5,
      )
      ..quadraticBezierTo(
        item.center.dx + direction.dx * length * 0.45 + normal.dx * width,
        item.center.dy + direction.dy * length * 0.45 + normal.dy * width,
        end.dx,
        end.dy,
      )
      ..quadraticBezierTo(
        item.center.dx + direction.dx * length * 0.45 - normal.dx * width,
        item.center.dy + direction.dy * length * 0.45 - normal.dy * width,
        item.center.dx - normal.dx * radius * 0.5,
        item.center.dy - normal.dy * radius * 0.5,
      )
      ..close();

    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          const Color(0xFFE8FAFF).withValues(alpha: 0.72 * activity),
          const Color(0xFF83D8FF).withValues(alpha: 0.26 * activity),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: item.center, radius: length));
    canvas.drawPath(tail, paint);
  }

  void paintPlanetBody(
    Canvas canvas,
    RenderedPlanet item,
    double elapsedSeconds,
    Offset sunCenter,
  ) {
    final planet = item.placedPlanet.planet;
    final radius = item.visualSize / 2;
    final opacity = item.position.opacity;
    final bodyBounds = Rect.fromCircle(center: item.center, radius: radius);

    canvas.save();
    canvas.clipPath(Path()..addOval(bodyBounds));
    _paintBase(canvas, item, opacity);

    switch (planet.surfaceStyle) {
      case PlanetSurfaceStyle.rocky:
        _paintRockySurface(canvas, item, opacity);
      case PlanetSurfaceStyle.cloudy:
        _paintCloudBands(canvas, item, opacity, elapsedSeconds);
      case PlanetSurfaceStyle.ocean:
        _paintOceanSurface(canvas, item, opacity, elapsedSeconds);
      case PlanetSurfaceStyle.gasGiant:
        _paintGasGiantBands(canvas, item, opacity, elapsedSeconds);
      case PlanetSurfaceStyle.iceGiant:
        _paintIceGiantGlow(canvas, item, opacity, elapsedSeconds);
      case PlanetSurfaceStyle.moon:
        _paintMoonCraters(canvas, item, opacity);
      case PlanetSurfaceStyle.comet:
        _paintCometNucleus(canvas, item, opacity);
    }

    _paintShade(canvas, item, sunCenter);
    canvas.restore();
  }

  void _paintBase(Canvas canvas, RenderedPlanet item, double opacity) {
    final planet = item.placedPlanet.planet;
    final radius = item.visualSize / 2;
    final paint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.35, -0.45),
        colors: [
          Colors.white.withValues(alpha: 0.92 * opacity),
          planet.colors.first.withValues(alpha: opacity),
          planet.colors.last.withValues(alpha: opacity),
        ],
        stops: const [0, 0.34, 1],
      ).createShader(Rect.fromCircle(center: item.center, radius: radius));
    canvas.drawCircle(item.center, radius, paint);
  }

  void _paintRockySurface(Canvas canvas, RenderedPlanet item, double opacity) {
    final radius = item.visualSize / 2;
    final random = math.Random(item.placedPlanet.planet.name.hashCode);
    final paint = Paint()..style = PaintingStyle.fill;
    for (var i = 0; i < 16; i++) {
      final angle = random.nextDouble() * math.pi * 2;
      final distance = random.nextDouble() * radius * 0.72;
      final craterRadius = radius * (0.05 + random.nextDouble() * 0.09);
      paint.color = Colors.black.withValues(
        alpha: 0.08 + random.nextDouble() * 0.1,
      );
      canvas.drawCircle(
        item.center + Offset(math.cos(angle), math.sin(angle)) * distance,
        craterRadius,
        paint,
      );
    }
  }

  void _paintCloudBands(
    Canvas canvas,
    RenderedPlanet item,
    double opacity,
    double elapsedSeconds,
  ) {
    final radius = item.visualSize / 2;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = radius * 0.16
      ..color = Colors.white.withValues(alpha: 0.16 * opacity);
    for (var i = -2; i <= 2; i++) {
      final y = item.center.dy + i * radius * 0.28;
      final shift = math.sin(elapsedSeconds * 0.35 + i) * radius * 0.16;
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(item.center.dx + shift, y),
          width: radius * 2.2,
          height: radius * 0.7,
        ),
        math.pi * 0.05,
        math.pi * 0.9,
        false,
        paint,
      );
    }
  }

  void _paintOceanSurface(
    Canvas canvas,
    RenderedPlanet item,
    double opacity,
    double elapsedSeconds,
  ) {
    final radius = item.visualSize / 2;
    final landPaint = Paint()
      ..color = const Color(0xFF55B46D).withValues(alpha: 0.62 * opacity);
    for (var i = 0; i < 4; i++) {
      final phase = elapsedSeconds * 0.18 + i * 1.7;
      final rect = Rect.fromCenter(
        center:
            item.center +
            Offset(
              math.cos(phase) * radius * 0.34,
              math.sin(phase) * radius * 0.28,
            ),
        width: radius * (0.52 + i * 0.08),
        height: radius * 0.28,
      );
      canvas.drawOval(rect, landPaint);
    }
    final cloudPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.08
      ..color = Colors.white.withValues(alpha: 0.32 * opacity);
    canvas.drawArc(
      Rect.fromCircle(center: item.center, radius: radius * 0.72),
      -0.8,
      1.5,
      false,
      cloudPaint,
    );
  }

  void _paintGasGiantBands(
    Canvas canvas,
    RenderedPlanet item,
    double opacity,
    double elapsedSeconds,
  ) {
    final radius = item.visualSize / 2;
    for (var i = -4; i <= 4; i++) {
      final bandPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * 0.15
        ..color = (i.isEven ? Colors.white : const Color(0xFF8B4A2C))
            .withValues(alpha: (i.isEven ? 0.18 : 0.16) * opacity);
      final shift = math.sin(elapsedSeconds * 0.24 + i) * radius * 0.1;
      canvas.drawLine(
        Offset(
          item.center.dx - radius + shift,
          item.center.dy + i * radius * 0.18,
        ),
        Offset(
          item.center.dx + radius + shift,
          item.center.dy + i * radius * 0.18,
        ),
        bandPaint,
      );
    }

    if (item.placedPlanet.planet.name == 'Jupiter') {
      final stormPaint = Paint()
        ..color = const Color(0xFFB94D32).withValues(alpha: 0.62 * opacity);
      canvas.drawOval(
        Rect.fromCenter(
          center: item.center + Offset(radius * 0.34, radius * 0.22),
          width: radius * 0.64,
          height: radius * 0.32,
        ),
        stormPaint,
      );
    }
  }

  void _paintIceGiantGlow(
    Canvas canvas,
    RenderedPlanet item,
    double opacity,
    double elapsedSeconds,
  ) {
    final radius = item.visualSize / 2;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.08
      ..color = Colors.white.withValues(alpha: 0.18 * opacity);
    for (var i = 0; i < 3; i++) {
      canvas.drawArc(
        Rect.fromCenter(
          center: item.center,
          width: radius * (1.3 + i * 0.25),
          height: radius * (0.55 + i * 0.12),
        ),
        elapsedSeconds * 0.12 + i,
        math.pi * 0.9,
        false,
        paint,
      );
    }
  }

  void _paintMoonCraters(Canvas canvas, RenderedPlanet item, double opacity) {
    final radius = item.visualSize / 2;
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.18 * opacity);
    final offsets = [
      Offset(-0.35, -0.22),
      Offset(0.2, -0.35),
      Offset(0.3, 0.18),
      Offset(-0.12, 0.32),
    ];
    for (final offset in offsets) {
      canvas.drawCircle(item.center + offset * radius, radius * 0.13, paint);
    }
  }

  void _paintCometNucleus(Canvas canvas, RenderedPlanet item, double opacity) {
    final radius = item.visualSize / 2;
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3 * opacity);
    canvas.drawCircle(
      item.center + Offset(-radius * 0.18, -radius * 0.2),
      radius * 0.28,
      paint,
    );
  }

  void _paintShade(Canvas canvas, RenderedPlanet item, Offset sunCenter) {
    final radius = item.visualSize / 2;
    final lightVector = sunCenter - item.center;
    final lightDirection = lightVector.distance == 0
        ? const Offset(-1, -1)
        : lightVector / lightVector.distance;
    final shadowCenter = item.center - lightDirection * radius * 0.48;
    final highlightCenter = item.center + lightDirection * radius * 0.36;

    final highlightPaint = Paint()
      ..shader =
          RadialGradient(
            colors: [
              Colors.white.withValues(alpha: 0.24 * item.position.opacity),
              Colors.transparent,
            ],
          ).createShader(
            Rect.fromCircle(center: highlightCenter, radius: radius * 0.74),
          );
    canvas.drawCircle(item.center, radius, highlightPaint);

    final paint = Paint()
      ..shader =
          RadialGradient(
            colors: [
              Colors.transparent,
              Colors.black.withValues(alpha: 0.18),
              Colors.black.withValues(alpha: 0.48),
            ],
            stops: const [0, 0.58, 1],
          ).createShader(
            Rect.fromCircle(center: shadowCenter, radius: radius * 1.35),
          );
    canvas.drawCircle(item.center, radius, paint);
  }

  void _paintRingArc(
    Canvas canvas,
    RenderedPlanet item,
    double opacity,
    Projector3D projector, {
    required bool drawFront,
  }) {
    final planet = item.placedPlanet.planet;
    final radius = item.visualSize / 2;

    // Define the ring radius multiplier relative to planet size
    final ringRadiiMultiplier = switch (planet.ringStyle) {
      PlanetRingStyle.saturn => const [1.5, 1.8, 2.1],
      PlanetRingStyle.uranus => const [1.3, 1.45, 1.6],
      PlanetRingStyle.thin => const [1.3, 1.4],
      PlanetRingStyle.none => const <double>[],
    };

    // Calculate planet's 3D position in world space
    final angle = item.position.angle;
    final planetX = planet.orbitRadius * math.cos(angle);
    final planetZ = planet.orbitRadius * math.sin(angle);
    const planetY = 0.0;

    final planetProjected = projector.project(planetX, planetY, planetZ);
    final tiltRad = (planet.axialTilt / 180) * math.pi;
    final baseAlpha = planet.ringStyle == PlanetRingStyle.saturn ? 0.72 : 0.42;

    for (var ringIdx = 0; ringIdx < ringRadiiMultiplier.length; ringIdx++) {
      final ringRadius = planet.size * ringRadiiMultiplier[ringIdx];
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.0, radius * 0.09 * (1.0 - ringIdx * 0.15))
        ..color = planet.colors.first.withValues(
          alpha: opacity * baseAlpha * (1.0 - ringIdx * 0.18),
        );

      const segments = 90;
      for (var i = 0; i < segments; i++) {
        final theta1 = (i * 2 * math.pi) / segments;
        final theta2 = ((i + 1) * 2 * math.pi) / segments;

        // Local space: circle in horizontal X-Z plane, rotated around X-axis by tiltRad
        final lx1 = ringRadius * math.cos(theta1);
        final lz1 = ringRadius * math.sin(theta1);
        final rx1 = lx1;
        final ry1 = -lz1 * math.sin(tiltRad);
        final rz1 = lz1 * math.cos(tiltRad);

        final lx2 = ringRadius * math.cos(theta2);
        final lz2 = ringRadius * math.sin(theta2);
        final rx2 = lx2;
        final ry2 = -lz2 * math.sin(tiltRad);
        final rz2 = lz2 * math.cos(tiltRad);

        // Convert to world space
        final wx1 = planetX + rx1;
        final wy1 = planetY + ry1;
        final wz1 = planetZ + rz1;

        final wx2 = planetX + rx2;
        final wy2 = planetY + ry2;
        final wz2 = planetZ + rz2;

        // Project to camera space
        final proj1 = projector.project(wx1, wy1, wz1);
        final proj2 = projector.project(wx2, wy2, wz2);

        final segmentDepth = (proj1.z + proj2.z) / 2;
        final isFront = segmentDepth >= planetProjected.z;

        if (isFront == drawFront) {
          canvas.drawLine(
            Offset(proj1.x, proj1.y),
            Offset(proj2.x, proj2.y),
            paint,
          );
        }
      }
    }
  }
}
