# Solar System Lab Code Flow

## Simple Version

The app is split into four main parts:

1. `main.dart` starts the app and locks it to landscape.
2. `SolarSystemScreen` builds the full layout: left info panel, center solar system canvas, right controls, and bottom toolbox.
3. `SolarSystemController` owns app state: placed planets, selected planet, play/pause, speed, cinematic mode, and camera reset.
4. `SolarSystemCanvas` draws and animates the solar system using `CustomPainter`.

The user drags a planet from the toolbox. The canvas receives it through `DragTarget`, asks the controller to add it, and then painters render it orbiting around the Sun.

## Entry Flow

File: `lib/main.dart`

The app starts by initializing Flutter, locking orientation to landscape, and wrapping the app with Riverpod:

```dart
WidgetsFlutterBinding.ensureInitialized();
SystemChrome.setPreferredOrientations([...landscape...]);
runApp(const ProviderScope(child: SolarSystemLabApp()));
```

`ProviderScope` enables Riverpod globally.

File: `lib/features/solar_system/presentation/solar_system_lab_app.dart`

`SolarSystemLabApp` creates the `MaterialApp`, dark theme, and loads `SolarSystemScreen`.

## Screen Layout

File: `lib/features/solar_system/presentation/solar_system_screen.dart`

`SolarSystemScreen` builds the page:

```text
Left info sidebar | SolarSystemCanvas | Right controls
Bottom toolbox
```

It also:

- shows a portrait warning if the device is not landscape
- supports collapsible left and right sidebars
- paints a starfield behind the full app so no black gaps show

## State Flow

File: `lib/features/solar_system/models/solar_system_state.dart`

`SolarSystemState` is the full app state:

- `availablePlanets`
- `placedPlanets`
- `selectedPlanetId`
- `isPlaying`
- `timeSpeed`
- `showOrbitLabels`
- `showStars`
- `cinematicModeEnabled`
- `cameraFocusRequest`

File: `lib/features/solar_system/controllers/solar_system_controller.dart`

`SolarSystemController` mutates that state.

Important methods:

- `addPlanet(...)`: adds a planet unless already placed
- `selectPlanet(...)`: selects a planet and requests camera focus
- `play()` / `pause()`
- `setTimeSpeed(...)`
- `resetScene()`
- `toggleCinematicMode(...)`
- `nextCinematicStep(...)`

Duplicate prevention happens in `addPlanet(...)`:

```dart
final existing = state.placedPlanets.where((placed) {
  return placed.planet.name == planet.name;
});
if (existing.isNotEmpty) {
  // select existing planet instead of adding duplicate
}
```

## Drag And Drop Flow

File: `lib/features/solar_system/widgets/planet_toolbox.dart`

`PlanetToolbox` renders each planet as a `Draggable<PlanetModel>`.

When the user drags a planet:

```text
Toolbox Draggable
→ SolarSystemCanvas DragTarget
→ controller.addPlanet(...)
→ state.placedPlanets updates
→ painters render planet
```

Already placed planets are dimmed and no longer draggable.

## Animation Flow

File: `lib/features/solar_system/widgets/solar_system_canvas.dart`

`SolarSystemCanvas` owns the animation clock:

```dart
AnimationController _renderClock
```

Every tick:

- if `isPlaying`, simulation time increases
- planet painters repaint
- Riverpod state is not updated every frame

That is important for performance. Riverpod handles discrete state changes; animation stays local to the canvas.

## Orbital Math

File: `lib/core/math/orbital_engine.dart`

`OrbitalEngine` calculates position:

```dart
x = orbitRadius * cos(angle)
y = orbitHeight * sin(angle)
z = sin(angle)
```

Then `z` controls:

- scale
- opacity
- draw order

So planets in front look larger/brighter, and planets behind look smaller/dimmer.

## Rendering Layers

The canvas uses separated `CustomPainter` layers:

1. `StarFieldPainter`
2. `OrbitPathsPainter`
3. `AsteroidBeltPainter`
4. `OrbitTrailPainter`
5. `PlanetLayerPainter`

Painter files:

- `lib/features/solar_system/painters/star_field_painter.dart`
- `lib/features/solar_system/painters/orbit_paths_painter.dart`
- `lib/features/solar_system/painters/asteroid_belt_painter.dart`
- `lib/features/solar_system/painters/orbit_trail_painter.dart`
- `lib/features/solar_system/painters/planet_layer_painter.dart`

This is why the app stays performant: only moving layers need continuous repainting.

## Planet Drawing

File: `lib/features/solar_system/painters/planet_surface_painter.dart`

`PlanetSurfacePainter` handles visual styles:

- rocky planets
- gas giants
- ice giants
- moon craters
- Saturn/Uranus rings
- comet tail

Planet metadata comes from:

```text
lib/core/constants/planet_catalog.dart
```

## Camera Flow

The canvas uses `InteractiveViewer` and `TransformationController`.

Manual camera behavior:

- user pans/zooms directly
- tapping a planet selects and focuses it

Programmatic camera behavior:

- controller emits a `CameraFocusRequest`
- canvas listens to the request token
- canvas animates the camera to the Sun or target planet

Cinematic mode auto-places tour planets and cycles:

```text
Sun → Mercury → Venus → Earth → Mars → Jupiter → Saturn → Uranus → Neptune
```

## Controls Flow

File: `lib/features/solar_system/widgets/control_panel.dart`

`ControlPanel` calls controller methods:

- Play
- Pause
- Reset
- Speed cycle
- Cinematic
- Labels
- Stars
- Camera reset

Example:

```dart
onPressed: controller.pause
```

UI never directly mutates planet lists. It asks the controller.

## Info Panel Flow

File: `lib/features/solar_system/widgets/planet_info_panel.dart`

`PlanetInfoPanel` watches selected planet state.

If no planet is selected:

- shows empty instruction

If a planet is selected:

- shows name
- radius
- distance
- speed
- rotation
- facts

## Senior-Level Summary

The architecture is:

```text
UI Widgets
  ↓ user events
SolarSystemController
  ↓ immutable state
SolarSystemState
  ↓ watched by widgets/painters
Canvas + Panels
```

The simulation itself is deliberately not stored in Riverpod per frame. The animation clock and elapsed time live inside `SolarSystemCanvas`, while app-level state changes stay discrete. That avoids excessive rebuilds and keeps the simulator smooth.

Painters are split by responsibility so background/static layers are separated from moving planet rendering. This matches the performance goal: only moving layers need continuous repainting.
