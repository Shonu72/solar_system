import 'dart:math' as math;

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
}
