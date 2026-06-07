import 'package:flutter/material.dart';

import '../../../core/models/orbit_position.dart';
import '../../../core/models/placed_planet.dart';

class RenderedPlanet {
  const RenderedPlanet({
    required this.placedPlanet,
    required this.position,
    required this.center,
    required this.visualSize,
  });

  final PlacedPlanet placedPlanet;
  final OrbitPosition position;
  final Offset center;
  final double visualSize;
}
