import 'package:flutter/material.dart';

@immutable
class PlanetModel {
  const PlanetModel({
    required this.name,
    required this.orbitRadius,
    required this.orbitHeight,
    required this.orbitalSpeed,
    required this.size,
    required this.imageAsset,
    required this.radiusLabel,
    required this.distanceLabel,
    required this.orbitalSpeedLabel,
    required this.rotationPeriodLabel,
    required this.facts,
    required this.colors,
    this.hasRing = false,
    this.isComet = false,
  });

  final String name;
  final double orbitRadius;
  final double orbitHeight;
  final double orbitalSpeed;
  final double size;
  final String imageAsset;
  final String radiusLabel;
  final String distanceLabel;
  final String orbitalSpeedLabel;
  final String rotationPeriodLabel;
  final List<String> facts;
  final List<Color> colors;
  final bool hasRing;
  final bool isComet;
}
