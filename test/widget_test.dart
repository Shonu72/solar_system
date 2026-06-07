import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:solar_system/features/solar_system/controllers/solar_system_controller.dart';
import 'package:solar_system/features/solar_system/presentation/solar_system_lab_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('renders Solar System Lab shell and toolbox', (tester) async {
    tester.view.physicalSize = const Size(1400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpApp(tester);

    expect(find.textContaining('SOLAR SYSTEM'), findsOneWidget);
    expect(find.text('SELECTED PLANET'), findsOneWidget);
    expect(find.text('DRAG & DROP TO ADD PLANETS'), findsOneWidget);
    expect(find.text('Earth'), findsOneWidget);
    expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    expect(find.byIcon(Icons.pause), findsOneWidget);
  });

  testWidgets('sidebars can collapse and expand', (tester) async {
    tester.view.physicalSize = const Size(1400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpApp(tester);

    expect(find.text('SELECTED PLANET'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('toggle-info-sidebar')));
    await tester.pump();

    expect(find.text('PLANET INFO'), findsOneWidget);
    expect(find.text('SELECTED PLANET'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('toggle-info-sidebar')));
    await tester.pump();

    expect(find.text('SELECTED PLANET'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('toggle-controls-sidebar')));
    await tester.pump();

    expect(find.text('CONTROLS'), findsOneWidget);
    expect(find.byIcon(Icons.play_arrow), findsNothing);
  });

  testWidgets('renders without overflow on phone landscape', (tester) async {
    tester.view.physicalSize = const Size(932, 430);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpApp(tester);

    expect(find.byKey(const ValueKey('toggle-info-sidebar')), findsOneWidget);
    expect(find.text('DRAG & DROP TO ADD PLANETS'), findsOneWidget);
    expect(find.byIcon(Icons.pause), findsOneWidget);
  });

  testWidgets('dragging Earth adds and selects it', (tester) async {
    tester.view.physicalSize = const Size(1400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpApp(tester);

    await tester.dragFrom(
      tester.getCenter(find.byKey(const ValueKey('toolbox-Earth'))),
      const Offset(280, -360),
    );
    await tester.pump();

    expect(find.text('6,371 km'), findsOneWidget);
    expect(find.text('149.6 million km'), findsOneWidget);
  });

  testWidgets('dragging Saturn adds and selects it', (tester) async {
    tester.view.physicalSize = const Size(1400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpApp(tester);

    await tester.dragFrom(
      tester.getCenter(find.byKey(const ValueKey('toolbox-Saturn'))),
      const Offset(-80, -360),
    );
    await tester.pump();

    expect(find.text('58,232 km'), findsOneWidget);
    expect(find.text('1.43 billion km'), findsOneWidget);
  });

  testWidgets('dragging Comet adds and selects it', (tester) async {
    tester.view.physicalSize = const Size(1400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpApp(tester);

    await tester.dragFrom(
      tester.getCenter(find.byKey(const ValueKey('toolbox-Comet'))),
      const Offset(-520, -360),
    );
    await tester.pump();

    expect(find.text('Comet'), findsWidgets);
    expect(find.text('Highly elliptical'), findsOneWidget);
  });

  testWidgets('dragging the same planet twice does not duplicate it', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = ProviderContainer();
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const SolarSystemLabApp(),
      ),
    );

    await tester.dragFrom(
      tester.getCenter(find.byKey(const ValueKey('toolbox-Jupiter'))),
      const Offset(80, -360),
    );
    await tester.pump();

    expect(
      container.read(solarSystemControllerProvider).placedPlanets,
      hasLength(1),
    );

    expect(find.byKey(const ValueKey('toolbox-Jupiter')), findsOneWidget);
    expect(
      tester
          .widget<Opacity>(find.byKey(const ValueKey('toolbox-Jupiter')))
          .opacity,
      0.44,
    );

    container
        .read(solarSystemControllerProvider.notifier)
        .addPlanet(
          container
              .read(solarSystemControllerProvider)
              .availablePlanets
              .firstWhere((planet) => planet.name == 'Jupiter'),
          0,
        );

    expect(
      container.read(solarSystemControllerProvider).placedPlanets,
      hasLength(1),
    );

    await tester.pumpWidget(const SizedBox());
    container.dispose();
  });

  testWidgets('pause, speed, and reset controls update visible state', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpApp(tester);

    await tester.tap(find.byIcon(Icons.pause));
    await tester.pump();
    await tester.tap(find.text('1x'));
    await tester.pump(const Duration(milliseconds: 250));
    await tester.tap(find.text('10x'));
    await tester.pump();

    expect(find.text('100x'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.restart_alt));
    await tester.pump();

    expect(find.text('100x'), findsNothing);
    expect(find.text('1x'), findsOneWidget);
  });
}

Future<void> _pumpApp(WidgetTester tester) {
  return tester.pumpWidget(const ProviderScope(child: SolarSystemLabApp()));
}
