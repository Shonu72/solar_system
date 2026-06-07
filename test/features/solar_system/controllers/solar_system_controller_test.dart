import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solar_system/features/solar_system/controllers/solar_system_controller.dart';
import 'package:solar_system/features/solar_system/models/solar_system_state.dart';

void main() {
  test('cinematic mode starts tour and creates focus request', () {
    final controller = ProviderContainer();
    addTearDown(controller.dispose);

    final notifier = controller.read(solarSystemControllerProvider.notifier);
    notifier.toggleCinematicMode(0);

    final state = controller.read(solarSystemControllerProvider);
    expect(state.cinematicModeEnabled, isTrue);
    expect(state.cinematicStepIndex, 0);
    expect(state.cameraFocusRequest.targetType, CameraFocusTargetType.sun);
    expect(state.cameraFocusRequest.token, greaterThan(0));
    expect(
      state.placedPlanets.map((placed) => placed.planet.name),
      containsAll(['Mercury', 'Earth', 'Neptune']),
    );
  });

  test('reset clears cinematic state', () {
    final controller = ProviderContainer();
    addTearDown(controller.dispose);

    final notifier = controller.read(solarSystemControllerProvider.notifier);
    notifier.toggleCinematicMode(0);
    notifier.resetScene();

    final state = controller.read(solarSystemControllerProvider);
    expect(state.cinematicModeEnabled, isFalse);
    expect(state.placedPlanets, isEmpty);
  });
}
