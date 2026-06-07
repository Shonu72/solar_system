import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/planet_model.dart';
import '../controllers/solar_system_controller.dart';
import 'glass_panel.dart';

class PlanetToolbox extends ConsumerWidget {
  const PlanetToolbox({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planets = ref.watch(
      solarSystemControllerProvider.select((state) => state.availablePlanets),
    );

    return DecoratedBox(
      decoration: const BoxDecoration(color: Color(0xFF020711)),
      child: GlassPanel(
        margin: const EdgeInsets.fromLTRB(10, 6, 10, 10),
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'DRAG & DROP TO ADD PLANETS',
              style: TextStyle(
                color: Color(0xFF4EA6FF),
                fontWeight: FontWeight.w700,
                fontSize: 12,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: planets.length,
                separatorBuilder: (_, _) => const SizedBox(width: 18),
                itemBuilder: (context, index) {
                  return _ToolboxPlanet(planet: planets[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolboxPlanet extends StatelessWidget {
  const _ToolboxPlanet({required this.planet});

  final PlanetModel planet;

  @override
  Widget build(BuildContext context) {
    final chip = SizedBox(
      key: ValueKey('toolbox-${planet.name}'),
      width: 86,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _PlanetBadge(planet: planet, size: 58),
          const SizedBox(height: 8),
          Text(
            planet.name,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );

    return Draggable<PlanetModel>(
      data: planet,
      feedback: Opacity(
        opacity: 0.9,
        child: Transform.scale(
          scale: 1.15,
          child: _PlanetBadge(planet: planet, size: 64),
        ),
      ),
      dragAnchorStrategy: pointerDragAnchorStrategy,
      childWhenDragging: Opacity(opacity: 0.42, child: chip),
      child: chip,
    );
  }
}

class _PlanetBadge extends StatelessWidget {
  const _PlanetBadge({required this.planet, required this.size});

  final PlanetModel planet;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _ToolboxPlanetPainter(planet)),
    );
  }
}

class _ToolboxPlanetPainter extends CustomPainter {
  const _ToolboxPlanetPainter(this.planet);

  final PlanetModel planet;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2;
    if (planet.isComet) {
      final tailPaint = Paint()
        ..shader = const LinearGradient(
          colors: [Color(0x0083D8FF), Color(0xFFE8FAFF)],
        ).createShader(Offset.zero & size);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(size.width * 0.38, size.height * 0.52),
          width: size.width * 0.95,
          height: size.height * 0.28,
        ),
        tailPaint,
      );
    }
    if (planet.hasRing) {
      final ringPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = planet.colors.first.withValues(alpha: 0.7);
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(-0.35);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset.zero,
          width: radius * 2.9,
          height: radius,
        ),
        ringPaint,
      );
      canvas.restore();
    }
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: 0.9),
          planet.colors.first,
          planet.colors.last,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius * 0.82, paint);
  }

  @override
  bool shouldRepaint(covariant _ToolboxPlanetPainter oldDelegate) {
    return oldDelegate.planet != planet;
  }
}
