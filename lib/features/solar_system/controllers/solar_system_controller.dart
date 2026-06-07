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
  static const cinematicSequence = [
    'Sun',
    'Mercury',
    'Venus',
    'Earth',
    'Mars',
    'Jupiter',
    'Saturn',
    'Uranus',
    'Neptune',
  ];

  @override
  SolarSystemState build() => SolarSystemState.initial();

  void addPlanet(PlanetModel planet, double simulationSeconds) {
    final existing = state.placedPlanets.where((placed) {
      return placed.planet.name == planet.name;
    });
    if (existing.isNotEmpty) {
      final placed = existing.first;
      state = state.copyWith(
        selectedPlanetId: placed.id,
        highlightOrbitIndex: placed.orbitIndex,
      );
      return;
    }

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
        cinematicModeEnabled: false,
        clearSelectedPlanet: true,
        clearHighlightOrbit: true,
      );
      return;
    }

    final placed = state.placedPlanets.where((planet) => planet.id == id);
    state = state.copyWith(
      cinematicModeEnabled: false,
      selectedPlanetId: id,
      highlightOrbitIndex: placed.isEmpty ? null : placed.first.orbitIndex,
      clearHighlightOrbit: placed.isEmpty,
      cameraFocusRequest: _focusRequest(CameraFocusTargetType.selectedPlanet),
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
    state = state.copyWith(
      cinematicModeEnabled: false,
      cameraResetToken: state.cameraResetToken + 1,
    );
  }

  void resetScene() {
    state = SolarSystemState.initial().copyWith(
      cameraResetToken: state.cameraResetToken + 1,
    );
  }

  void toggleCinematicMode(double simulationSeconds) {
    if (state.cinematicModeEnabled) {
      state = state.copyWith(cinematicModeEnabled: false);
      return;
    }
    _ensureCinematicPlanets(simulationSeconds);
    state = state.copyWith(
      cinematicModeEnabled: true,
      cinematicStepIndex: 0,
      cameraFocusRequest: _focusRequest(CameraFocusTargetType.sun),
    );
  }

  void nextCinematicStep(double simulationSeconds) {
    _ensureCinematicPlanets(simulationSeconds);
    final nextIndex = (state.cinematicStepIndex + 1) % cinematicSequence.length;
    final targetName = cinematicSequence[nextIndex];
    state = state.copyWith(
      cinematicModeEnabled: true,
      cinematicStepIndex: nextIndex,
      cameraFocusRequest: targetName == 'Sun'
          ? _focusRequest(CameraFocusTargetType.sun)
          : _focusRequest(
              CameraFocusTargetType.planetName,
              planetName: targetName,
            ),
    );
  }

  CameraFocusRequest _focusRequest(
    CameraFocusTargetType targetType, {
    String? planetName,
  }) {
    return CameraFocusRequest(
      token: state.cameraFocusRequest.token + 1,
      targetType: targetType,
      planetName: planetName,
    );
  }

  void _ensureCinematicPlanets(double simulationSeconds) {
    var placedPlanets = [...state.placedPlanets];
    var changed = false;
    for (final name in cinematicSequence.skip(1)) {
      final alreadyPlaced = placedPlanets.any((placed) {
        return placed.planet.name == name;
      });
      if (alreadyPlaced) {
        continue;
      }
      final planet = state.availablePlanets.firstWhere((item) {
        return item.name == name;
      });
      final orbitIndex = state.availablePlanets.indexWhere((item) {
        return item.name == planet.name;
      });
      placedPlanets.add(
        PlacedPlanet(
          id: _ids.next(planet.name.toLowerCase()),
          planet: planet,
          orbitIndex: orbitIndex,
          startAngle: -math.pi / 2 + (orbitIndex * 0.16),
          createdAtSeconds: simulationSeconds,
        ),
      );
      changed = true;
    }
    if (changed) {
      state = state.copyWith(placedPlanets: placedPlanets);
    }
  }
}
