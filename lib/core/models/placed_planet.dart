import 'package:flutter/foundation.dart';

import 'planet_model.dart';

@immutable
class PlacedPlanet {
  const PlacedPlanet({
    required this.id,
    required this.planet,
    required this.orbitIndex,
    required this.startAngle,
    required this.createdAtSeconds,
  });

  final String id;
  final PlanetModel planet;
  final int orbitIndex;
  final double startAngle;
  final double createdAtSeconds;

  PlacedPlanet copyWith({
    String? id,
    PlanetModel? planet,
    int? orbitIndex,
    double? startAngle,
    double? createdAtSeconds,
  }) {
    return PlacedPlanet(
      id: id ?? this.id,
      planet: planet ?? this.planet,
      orbitIndex: orbitIndex ?? this.orbitIndex,
      startAngle: startAngle ?? this.startAngle,
      createdAtSeconds: createdAtSeconds ?? this.createdAtSeconds,
    );
  }
}
