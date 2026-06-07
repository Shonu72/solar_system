import 'package:flutter/material.dart';

import '../../../core/models/planet_model.dart';

class OrbitPathsPainter extends CustomPainter {
  const OrbitPathsPainter({
    required this.planets,
    required this.showLabels,
    this.highlightOrbitIndex,
  });

  final List<PlanetModel> planets;
  final bool showLabels;
  final int? highlightOrbitIndex;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final matrix = Matrix4.identity()
      ..setEntry(3, 2, 0.001)
      ..rotateX(0.92);

    canvas.save();
    canvas.translate(center.dx, center.dy + 8);
    canvas.transform(matrix.storage);

    for (var index = planets.length - 1; index >= 0; index--) {
      final planet = planets[index];
      final highlighted = index == highlightOrbitIndex;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = highlighted ? 2.2 : 1
        ..color = highlighted
            ? const Color(0xFF4DB7FF).withValues(alpha: 0.82)
            : const Color(0xFF9AB8D8).withValues(alpha: 0.22);
      final rect = Rect.fromCenter(
        center: Offset.zero,
        width: planet.orbitRadius * 2,
        height: planet.orbitHeight * 2,
      );
      canvas.drawOval(rect, paint);
    }

    canvas.restore();

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
      final offset = Offset(
        center.dx + planet.orbitRadius + 10,
        center.dy - planet.orbitHeight * 0.34 - label.height / 2,
      );
      canvas.drawCircle(offset + const Offset(-6, 8), 2.5, labelPaint);
      label.paint(canvas, offset);
    }
  }

  @override
  bool shouldRepaint(covariant OrbitPathsPainter oldDelegate) {
    return oldDelegate.planets != planets ||
        oldDelegate.showLabels != showLabels ||
        oldDelegate.highlightOrbitIndex != highlightOrbitIndex;
  }
}
