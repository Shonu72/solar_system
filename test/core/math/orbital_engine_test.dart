import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:solar_system/core/constants/planet_catalog.dart';
import 'package:solar_system/core/math/orbital_engine.dart';

void main() {
  const engine = OrbitalEngine();

  test('calculates ellipse coordinates for known angles', () {
    final zero = engine.positionForAngle(
      angle: 0,
      orbitRadius: 100,
      orbitHeight: 40,
    );
    expect(zero.x, closeTo(100, 0.0001));
    expect(zero.y, closeTo(0, 0.0001));

    final quarter = engine.positionForAngle(
      angle: math.pi / 2,
      orbitRadius: 100,
      orbitHeight: 40,
    );
    expect(quarter.x, closeTo(0, 0.0001));
    expect(quarter.y, closeTo(40, 0.0001));
  });

  test('near depth renders brighter and larger than far depth', () {
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
    expect(near.scale, greaterThan(far.scale));
    expect(near.opacity, greaterThan(far.opacity));
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

  test('comet activity increases closer to the Sun', () {
    final comet = planetCatalog.firstWhere((planet) => planet.name == 'Comet');
    final near = engine.cometActivity(
      planet: comet,
      elapsedSeconds: 0,
      startAngle: math.pi / 2,
    );
    final far = engine.cometActivity(
      planet: comet,
      elapsedSeconds: 0,
      startAngle: 0,
    );

    expect(near, greaterThan(far));
    expect(near, inInclusiveRange(0.25, 1));
    expect(far, inInclusiveRange(0.25, 1));
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
