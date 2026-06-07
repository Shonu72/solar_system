import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/math/orbital_engine.dart';
import '../../../core/models/planet_model.dart';
import '../models/rendered_planet.dart';

class PlanetSurfacePainter {
  const PlanetSurfacePainter({this.engine = const OrbitalEngine()});

  final OrbitalEngine engine;

  void paintRingsBehind(Canvas canvas, RenderedPlanet item, double opacity) {
    final planet = item.placedPlanet.planet;
    if (!planet.hasRing) {
      return;
    }
    _paintRingArc(canvas, item, opacity, drawFront: false);
  }

  void paintRingsFront(Canvas canvas, RenderedPlanet item, double opacity) {
    final planet = item.placedPlanet.planet;
    if (!planet.hasRing) {
      return;
    }
    _paintRingArc(canvas, item, opacity, drawFront: true);
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

    _paintShade(canvas, item);
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

  void _paintShade(Canvas canvas, RenderedPlanet item) {
    final radius = item.visualSize / 2;
    final paint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.58, 0.5),
        colors: [Colors.transparent, Colors.black.withValues(alpha: 0.34)],
      ).createShader(Rect.fromCircle(center: item.center, radius: radius));
    canvas.drawCircle(item.center, radius, paint);
  }

  void _paintRingArc(
    Canvas canvas,
    RenderedPlanet item,
    double opacity, {
    required bool drawFront,
  }) {
    final planet = item.placedPlanet.planet;
    final radius = item.visualSize / 2;
    final ringWidth = switch (planet.ringStyle) {
      PlanetRingStyle.saturn => radius * 4.0,
      PlanetRingStyle.uranus => radius * 3.2,
      PlanetRingStyle.thin => radius * 2.8,
      PlanetRingStyle.none => radius * 0,
    };
    final ringHeight = switch (planet.ringStyle) {
      PlanetRingStyle.saturn => radius * 1.45,
      PlanetRingStyle.uranus => radius * 0.92,
      PlanetRingStyle.thin => radius * 0.85,
      PlanetRingStyle.none => radius * 0,
    };

    canvas.save();
    canvas.translate(item.center.dx, item.center.dy);
    canvas.rotate((planet.axialTilt / 180) * math.pi * 0.18 - 0.28);

    final baseAlpha = planet.ringStyle == PlanetRingStyle.saturn ? 0.72 : 0.42;
    for (var i = 0; i < 3; i++) {
      final rect = Rect.fromCenter(
        center: Offset.zero,
        width: ringWidth + i * radius * 0.22,
        height: ringHeight + i * radius * 0.08,
      );
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.2, radius * (0.09 - i * 0.016))
        ..color = planet.colors.first.withValues(
          alpha: opacity * baseAlpha * (1 - i * 0.18),
        );
      canvas.drawArc(rect, drawFront ? 0 : math.pi, math.pi, false, paint);
    }

    canvas.restore();
  }
}
