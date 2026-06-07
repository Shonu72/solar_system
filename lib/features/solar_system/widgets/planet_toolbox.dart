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
    final placedNames = ref.watch(
      solarSystemControllerProvider.select((state) {
        return state.placedPlanets.map((placed) => placed.planet.name).toSet();
      }),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 115;
        final badgeSize = compact ? 32.0 : 58.0;
        final chipWidth = compact ? 64.0 : 86.0;
        final separator = compact ? 10.0 : 18.0;

        return GlassPanel(
          margin: EdgeInsets.fromLTRB(
            10,
            compact ? 4 : 6,
            10,
            compact ? 6 : 10,
          ),
          padding: EdgeInsets.fromLTRB(
            compact ? 12 : 16,
            compact ? 6 : 10,
            compact ? 12 : 16,
            compact ? 6 : 12,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'DRAG & DROP TO ADD PLANETS',
                style: TextStyle(
                  color: const Color(0xFF4EA6FF),
                  fontWeight: FontWeight.w700,
                  fontSize: compact ? 11 : 12,
                  letterSpacing: 0,
                ),
              ),
              SizedBox(height: compact ? 4 : 8),
              Expanded(
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: planets.length,
                  separatorBuilder: (_, _) => SizedBox(width: separator),
                  itemBuilder: (context, index) {
                    final planet = planets[index];
                    return _ToolboxPlanet(
                      planet: planet,
                      isPlaced: placedNames.contains(planet.name),
                      badgeSize: badgeSize,
                      chipWidth: chipWidth,
                      compact: compact,
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ToolboxPlanet extends StatelessWidget {
  const _ToolboxPlanet({
    required this.planet,
    required this.isPlaced,
    required this.badgeSize,
    required this.chipWidth,
    required this.compact,
  });

  final PlanetModel planet;
  final bool isPlaced;
  final double badgeSize;
  final double chipWidth;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final chip = Opacity(
      key: ValueKey('toolbox-${planet.name}'),
      opacity: isPlaced ? 0.44 : 1,
      child: SizedBox(
        width: chipWidth,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _PlanetBadge(planet: planet, size: badgeSize),
            SizedBox(height: compact ? 3 : 8),
            Text(
              planet.name,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: TextStyle(
                color: isPlaced ? const Color(0xFF8EA6BD) : Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: compact ? 11 : 14,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );

    if (isPlaced) {
      return Tooltip(
        message: '${planet.name} is already in orbit',
        child: chip,
      );
    }

    return Draggable<PlanetModel>(
      data: planet,
      feedback: Opacity(
        opacity: 0.9,
        child: Transform.scale(
          scale: 1.15,
          child: _PlanetBadge(planet: planet, size: badgeSize + 6),
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
