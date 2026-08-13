import 'dart:math' as math;
import 'dart:ui';

import '../models/orbit_position.dart';
import '../models/planet_model.dart';
import '../models/placed_planet.dart';

class Vector3d {
  final double x;
  final double y;
  final double z;

  const Vector3d(this.x, this.y, this.z);

  static Vector3d lerp(Vector3d a, Vector3d b, double t) {
    return Vector3d(
      a.x + (b.x - a.x) * t,
      a.y + (b.y - a.y) * t,
      a.z + (b.z - a.z) * t,
    );
  }
}

class Vector3 {
  final double x;
  final double y;
  final double z; // Camera-space depth
  final double scale; // Perspective scale multiplier

  const Vector3(this.x, this.y, this.z, this.scale);
}

class Projector3D {
  final double azimuth;
  final double elevation;
  final double zoom;
  final Vector3d target;
  final Size viewportSize;
  final double sceneScale;

  const Projector3D({
    required this.azimuth,
    required this.elevation,
    required this.zoom,
    required this.target,
    required this.viewportSize,
    required this.sceneScale,
  });

  Vector3 project(double x, double y, double z) {
    // 1. Translate relative to focus target
    final rx = x - target.x;
    final ry = y - target.y;
    final rz = z - target.z;

    // 2. Rotate around Y-axis (azimuth/yaw)
    final cosA = math.cos(azimuth);
    final sinA = math.sin(azimuth);
    final x1 = rx * cosA - rz * sinA;
    final y1 = ry;
    final z1 = rx * sinA + rz * cosA;

    // 3. Rotate around X-axis (elevation/pitch)
    final cosE = math.cos(elevation);
    final sinE = math.sin(elevation);
    final x2 = x1;
    final y2 = y1 * cosE - z1 * sinE;
    final z2 = y1 * sinE + z1 * cosE;

    // 4. Perspective Projection
    const d = 1600.0;
    // Limit z2 to prevent divide-by-zero or extreme sizes close to clipping plane
    final clampedZ = z2.clamp(-d * 0.9, d * 0.9);
    final perspectiveScale = d / (d - clampedZ);

    final screenX = viewportSize.width / 2 + x2 * zoom * perspectiveScale * sceneScale;
    final screenY = viewportSize.height / 2 + y2 * zoom * perspectiveScale * sceneScale;

    return Vector3(screenX, screenY, clampedZ, perspectiveScale);
  }
}

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
      isComet: planet.surfaceStyle == PlanetSurfaceStyle.comet,
    );
  }

  OrbitPosition positionForAngle({
    required double angle,
    required double orbitRadius,
    required double orbitHeight,
    bool isComet = false,
  }) {
    // All orbits in 3D are circular in the X-Z plane for visual alignment
    final rz = orbitRadius;

    return OrbitPosition(
      x: orbitRadius * math.cos(angle),
      y: 0.0,
      z: rz * math.sin(angle),
      scale: 1.0,
      opacity: 1.0,
      angle: angle,
    );
  }

  List<PlacedPlanet> sortByDepth(
    Iterable<PlacedPlanet> planets,
    double elapsedSeconds,
  ) {
    // Note: sorting in 3D should be done in the painter using the camera projection.
    // This method remains for compatibility and fallback.
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
      position.x * position.x + position.y * position.y + position.z * position.z,
    );
    final maxDistance = planet.orbitRadius;
    final normalized = (1.0 - (distance / maxDistance)).clamp(0.0, 1.0);
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
      return Offset(position.x, position.z);
    });
  }

  List<Vector3d> trailSamples3D({
    required PlanetModel planet,
    required double elapsedSeconds,
    required double startAngle,
    required int sampleCount,
    required double sampleSpacingSeconds,
  }) {
    return List<Vector3d>.generate(sampleCount, (index) {
      final sampleTime = elapsedSeconds - index * sampleSpacingSeconds;
      final position = positionFor(
        planet: planet,
        elapsedSeconds: sampleTime,
        startAngle: startAngle,
      );
      return Vector3d(position.x, position.y, position.z);
    });
  }
}

