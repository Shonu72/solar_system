import 'package:flutter/foundation.dart';

@immutable
class OrbitPosition {
  const OrbitPosition({
    required this.x,
    required this.y,
    required this.z,
    required this.scale,
    required this.opacity,
    required this.angle,
  });

  final double x;
  final double y;
  final double z;
  final double scale;
  final double opacity;
  final double angle;
}
