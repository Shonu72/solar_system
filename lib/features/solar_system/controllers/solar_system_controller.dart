import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/placed_planet.dart';
import '../../../core/models/planet_model.dart';
import '../../../core/utils/id_factory.dart';
import '../models/solar_system_state.dart';

final solarSystemControllerProvider =
    NotifierProvider<SolarSystemController, SolarSystemState>(
      SolarSystemController.new,
    );

class SolarSystemController extends Notifier<SolarSystemState> {
  final IdFactory _ids = IdFactory();

  @override
  SolarSystemState build() => SolarSystemState.initial();

  void addPlanet(PlanetModel planet, double simulationSeconds) {
    final index = state.availablePlanets.indexWhere((item) {
      return item.name == planet.name;
    });
    final orbitIndex = index < 0 ? state.placedPlanets.length : index;
    final placed = PlacedPlanet(
      id: _ids.next(planet.name.toLowerCase()),
      planet: planet,
      orbitIndex: orbitIndex,
      startAngle: -math.pi / 2 + (orbitIndex * 0.16),
      createdAtSeconds: simulationSeconds,
    );

    state = state.copyWith(
      placedPlanets: [...state.placedPlanets, placed],
      selectedPlanetId: placed.id,
      highlightOrbitIndex: orbitIndex,
    );
  }

  void selectPlanet(String? id) {
    if (id == null) {
      state = state.copyWith(
        clearSelectedPlanet: true,
        clearHighlightOrbit: true,
      );
      return;
    }

    final placed = state.placedPlanets.where((planet) => planet.id == id);
    state = state.copyWith(
      selectedPlanetId: id,
      highlightOrbitIndex: placed.isEmpty ? null : placed.first.orbitIndex,
      clearHighlightOrbit: placed.isEmpty,
    );
  }

  void hoverPlanet(String? id) {
    state = id == null
        ? state.copyWith(clearHoveredPlanet: true)
        : state.copyWith(hoveredPlanetId: id);
  }

  void setDropHighlight(bool isHighlighted) {
    state = isHighlighted
        ? state.copyWith(highlightOrbitIndex: state.placedPlanets.length)
        : state.copyWith(clearHighlightOrbit: true);
  }

  void play() => state = state.copyWith(isPlaying: true);

  void pause() => state = state.copyWith(isPlaying: false);

  void setTimeSpeed(double speed) {
    state = state.copyWith(timeSpeed: speed);
  }

  void toggleOrbitLabels() {
    state = state.copyWith(showOrbitLabels: !state.showOrbitLabels);
  }

  void toggleStars() {
    state = state.copyWith(showStars: !state.showStars);
  }

  void resetCamera() {
    state = state.copyWith(cameraResetToken: state.cameraResetToken + 1);
  }

  void resetScene() {
    state = SolarSystemState.initial().copyWith(
      cameraResetToken: state.cameraResetToken + 1,
    );
  }
}
