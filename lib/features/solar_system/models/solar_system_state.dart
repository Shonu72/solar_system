import '../../../core/constants/planet_catalog.dart';
import '../../../core/models/placed_planet.dart';
import '../../../core/models/planet_model.dart';

enum CameraFocusTargetType { sun, selectedPlanet, planetName }

class CameraFocusRequest {
  const CameraFocusRequest({
    required this.token,
    required this.targetType,
    this.planetName,
  });

  final int token;
  final CameraFocusTargetType targetType;
  final String? planetName;
}

class SolarSystemState {
  const SolarSystemState({
    required this.availablePlanets,
    required this.placedPlanets,
    required this.isPlaying,
    required this.timeSpeed,
    required this.showOrbitLabels,
    required this.showStars,
    required this.cameraResetToken,
    required this.cinematicModeEnabled,
    required this.cinematicStepIndex,
    required this.cameraFocusRequest,
    this.selectedPlanetId,
    this.hoveredPlanetId,
    this.highlightOrbitIndex,
  });

  factory SolarSystemState.initial() {
    return const SolarSystemState(
      availablePlanets: planetCatalog,
      placedPlanets: [],
      isPlaying: true,
      timeSpeed: 1,
      showOrbitLabels: true,
      showStars: true,
      cameraResetToken: 0,
      cinematicModeEnabled: false,
      cinematicStepIndex: 0,
      cameraFocusRequest: CameraFocusRequest(
        token: 0,
        targetType: CameraFocusTargetType.sun,
      ),
    );
  }

  final List<PlanetModel> availablePlanets;
  final List<PlacedPlanet> placedPlanets;
  final bool isPlaying;
  final double timeSpeed;
  final bool showOrbitLabels;
  final bool showStars;
  final int cameraResetToken;
  final bool cinematicModeEnabled;
  final int cinematicStepIndex;
  final CameraFocusRequest cameraFocusRequest;
  final String? selectedPlanetId;
  final String? hoveredPlanetId;
  final int? highlightOrbitIndex;

  PlanetModel? get selectedPlanet {
    for (final placed in placedPlanets) {
      if (placed.id == selectedPlanetId) {
        return placed.planet;
      }
    }
    return null;
  }

  SolarSystemState copyWith({
    List<PlanetModel>? availablePlanets,
    List<PlacedPlanet>? placedPlanets,
    bool? isPlaying,
    double? timeSpeed,
    bool? showOrbitLabels,
    bool? showStars,
    int? cameraResetToken,
    bool? cinematicModeEnabled,
    int? cinematicStepIndex,
    CameraFocusRequest? cameraFocusRequest,
    String? selectedPlanetId,
    String? hoveredPlanetId,
    int? highlightOrbitIndex,
    bool clearSelectedPlanet = false,
    bool clearHoveredPlanet = false,
    bool clearHighlightOrbit = false,
  }) {
    return SolarSystemState(
      availablePlanets: availablePlanets ?? this.availablePlanets,
      placedPlanets: placedPlanets ?? this.placedPlanets,
      isPlaying: isPlaying ?? this.isPlaying,
      timeSpeed: timeSpeed ?? this.timeSpeed,
      showOrbitLabels: showOrbitLabels ?? this.showOrbitLabels,
      showStars: showStars ?? this.showStars,
      cameraResetToken: cameraResetToken ?? this.cameraResetToken,
      cinematicModeEnabled: cinematicModeEnabled ?? this.cinematicModeEnabled,
      cinematicStepIndex: cinematicStepIndex ?? this.cinematicStepIndex,
      cameraFocusRequest: cameraFocusRequest ?? this.cameraFocusRequest,
      selectedPlanetId: clearSelectedPlanet
          ? null
          : selectedPlanetId ?? this.selectedPlanetId,
      hoveredPlanetId: clearHoveredPlanet
          ? null
          : hoveredPlanetId ?? this.hoveredPlanetId,
      highlightOrbitIndex: clearHighlightOrbit
          ? null
          : highlightOrbitIndex ?? this.highlightOrbitIndex,
    );
  }
}
