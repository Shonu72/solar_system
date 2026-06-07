import 'dart:math' as math;
import 'dart:ui';

import '../models/orbit_position.dart';
import '../models/planet_model.dart';
import '../models/placed_planet.dart';

class OrbitalEngine {
  const OrbitalEngine();

  OrbitPosition positionFor({
    required PlanetModel planet,
    required double elapsedSeconds,
    double startAngle = 0,
  }) {
    final angle = startAngle + elapsedSeconds * planet.orbitalSpeed;
    return positionForAngle(
      angle: angle,
      orbitRadius: planet.orbitRadius,
      orbitHeight: planet.orbitHeight,
    );
  }

  OrbitPosition positionForAngle({
    required double angle,
    required double orbitRadius,
    required double orbitHeight,
  }) {
    final z = math.sin(angle);
    final normalizedDepth = (z + 1) / 2;

    return OrbitPosition(
      x: orbitRadius * math.cos(angle),
      y: orbitHeight * z,
      z: z,
      scale: 0.76 + normalizedDepth * 0.42,
      opacity: 0.55 + normalizedDepth * 0.45,
      angle: angle,
    );
  }

  List<PlacedPlanet> sortByDepth(
    Iterable<PlacedPlanet> planets,
    double elapsedSeconds,
  ) {
    final sorted = planets.toList();
    sorted.sort((a, b) {
      final aPosition = positionFor(
        planet: a.planet,
        elapsedSeconds: elapsedSeconds - a.createdAtSeconds,
        startAngle: a.startAngle,
      );
      final bPosition = positionFor(
        planet: b.planet,
        elapsedSeconds: elapsedSeconds - b.createdAtSeconds,
        startAngle: b.startAngle,
      );
      return aPosition.z.compareTo(bPosition.z);
    });
    return sorted;
  }

  double cometActivity({
    required PlanetModel planet,
    required double elapsedSeconds,
    double startAngle = 0,
  }) {
    final position = positionFor(
      planet: planet,
      elapsedSeconds: elapsedSeconds,
      startAngle: startAngle,
    );
    final distance = math.sqrt(
      position.x * position.x + position.y * position.y,
    );
    final maxDistance = math.max(planet.orbitRadius, planet.orbitHeight);
    final normalized = (1 - (distance / maxDistance)).clamp(0.0, 1.0);
    return 0.25 + normalized * 0.75;
  }

  List<Offset> trailSamples({
    required PlanetModel planet,
    required double elapsedSeconds,
    required double startAngle,
    required int sampleCount,
    required double sampleSpacingSeconds,
  }) {
    return List<Offset>.generate(sampleCount, (index) {
      final sampleTime = elapsedSeconds - index * sampleSpacingSeconds;
      final position = positionFor(
        planet: planet,
        elapsedSeconds: sampleTime,
        startAngle: startAngle,
      );
      return Offset(position.x, position.y);
    });
  }
}
