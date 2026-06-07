import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:solar_system/core/constants/planet_catalog.dart';
import 'package:solar_system/core/math/orbital_engine.dart';

void main() {
  const engine = OrbitalEngine();

  test('calculates circular coordinates for known angles in horizontal X-Z plane', () {
    final zero = engine.positionForAngle(
      angle: 0,
      orbitRadius: 100,
      orbitHeight: 40,
    );
    expect(zero.x, closeTo(100, 0.0001));
    expect(zero.y, closeTo(0, 0.0001));
    expect(zero.z, closeTo(0, 0.0001));

    final quarter = engine.positionForAngle(
      angle: math.pi / 2,
      orbitRadius: 100,
      orbitHeight: 40,
    );
    expect(quarter.x, closeTo(0, 0.0001));
    expect(quarter.y, closeTo(0, 0.0001));
    expect(quarter.z, closeTo(100, 0.0001));
  });

  test('depth values check: near vs far in Z axis', () {
    final far = engine.positionForAngle(
      angle: -math.pi / 2,
      orbitRadius: 100,
      orbitHeight: 40,
    );
    final near = engine.positionForAngle(
      angle: math.pi / 2,
      orbitRadius: 100,
      orbitHeight: 40,
    );

    expect(near.z, greaterThan(far.z));
  });

  test('3D projection scales elements correctly based on depth', () {
    const projector = Projector3D(
      azimuth: 0.0,
      elevation: 0.6,
      zoom: 1.0,
      target: Vector3d(0, 0, 0),
      viewportSize: Size(800, 600),
      sceneScale: 1.0,
    );

    // Front planet (closer to camera / positive Z after rotation)
    final nearProj = projector.project(0, 0, 200);
    // Back planet (further from camera / negative Z after rotation)
    final farProj = projector.project(0, 0, -200);

    expect(nearProj.scale, greaterThan(farProj.scale));
  });

  test('position is deterministic for fixed elapsed time and speed', () {
    final planet = planetCatalog.first;
    final first = engine.positionFor(
      planet: planet,
      elapsedSeconds: 12.5,
      startAngle: 0.25,
    );
    final second = engine.positionFor(
      planet: planet,
      elapsedSeconds: 12.5,
      startAngle: 0.25,
    );

    expect(second.x, first.x);
    expect(second.y, first.y);
    expect(second.z, first.z);
  });

  test('comet activity is within valid bounds', () {
    final comet = planetCatalog.firstWhere((planet) => planet.name == 'Comet');
    final activity = engine.cometActivity(
      planet: comet,
      elapsedSeconds: 0,
      startAngle: math.pi / 2,
    );

    expect(activity, inInclusiveRange(0.25, 1));
  });

  test('trail samples are deterministic for fixed inputs', () {
    final earth = planetCatalog.firstWhere((planet) => planet.name == 'Earth');
    final first = engine.trailSamples(
      planet: earth,
      elapsedSeconds: 8,
      startAngle: 0.4,
      sampleCount: 6,
      sampleSpacingSeconds: 0.2,
    );
    final second = engine.trailSamples(
      planet: earth,
      elapsedSeconds: 8,
      startAngle: 0.4,
      sampleCount: 6,
      sampleSpacingSeconds: 0.2,
    );

    expect(first, hasLength(6));
    expect(second, first);
  });
}
