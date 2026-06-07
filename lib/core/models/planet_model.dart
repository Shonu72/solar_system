import 'package:flutter/material.dart';

enum PlanetSurfaceStyle {
  rocky,
  cloudy,
  ocean,
  gasGiant,
  iceGiant,
  moon,
  comet,
}

enum PlanetRingStyle { none, thin, saturn, uranus }

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
    required this.surfaceStyle,
    this.ringStyle = PlanetRingStyle.none,
    this.trailColor,
    this.axialTilt = 0,
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
  final PlanetSurfaceStyle surfaceStyle;
  final PlanetRingStyle ringStyle;
  final Color? trailColor;
  final double axialTilt;

  bool get hasRing => ringStyle != PlanetRingStyle.none;
  bool get isComet => surfaceStyle == PlanetSurfaceStyle.comet;
}
