# 3D Solar System Lab - Interview Preparation & Codebase Guide

This document contains a comprehensive breakdown of the architecture, custom mathematics, graphics pipeline, state management, and interaction system of the **3D Solar System Lab** project. Use this guide to understand the engineering decisions, explain the code during technical interviews, and review mock questions and answers.

---

## 1. Architecture & Folder Structure

The project is structured according to clean architecture principles, separating reusable core infrastructure (math, models, constants) from feature-specific UI and state management.

```
lib/
├── main.dart
├── core/
│   ├── constants/
│   │   └── planet_catalog.dart          # Constant details of all available celestial bodies
│   ├── math/
│   │   └── orbital_engine.dart          # 3D projection, vector types, and circular coordinate math
│   ├── models/
│   │   ├── orbit_position.dart          # Position capsule containing x, y, z, scale, and opacity
│   │   ├── placed_planet.dart           # An instance of a planet placed in orbit
│   │   └── planet_model.dart            # Constant configuration for a planet type (size, speed, colors, tilt)
│   └── utils/
│       └── id_factory.dart              # Generates unique, name-based keys for active elements
└── features/
    └── solar_system/
        ├── controllers/
        │   └── solar_system_controller.dart # Notifier managing the simulation state
        ├── models/
        │   ├── rendered_planet.dart     # Projects planet data ready for painting
        │   └── solar_system_state.dart  # Immutable state model (placed planets, selections, play state)
        ├── painters/
        │   ├── asteroid_belt_painter.dart# 3D asteroid belt split into front/back layers
        │   ├── orbit_paths_painter.dart # projects and draws concentric orbit tracks
        │   ├── orbit_trail_painter.dart # Draws fading orbital history paths
        │   ├── planet_layer_painter.dart# Performs global Z-sorting and paints planets + Sun
        │   ├── planet_surface_painter.dart# Renders planet bodies, shading, and axial-tilted rings
        │   └── star_field_painter.dart  # Generates static background stars and nebulae
        ├── presentation/
        │   └── solar_system_screen.dart # Landscape layout shell with collapsing sidebar controls
        └── widgets/
            ├── control_panel.dart       # Playback, speed, labels, reset, and camera controllers
            ├── glass_panel.dart         # Reusable backdrop-filtered glassmorphism panel
            ├── planet_info_panel.dart   # Displays selected planet specifications and facts
            ├── planet_toolbox.dart      # Horizontal list of draggable catalog elements
            └── solar_system_canvas.dart # Captures gestures and bridges Flutter inputs with 3D projection
```

---

## 2. Key Mathematical & 3D Projection Concepts

To implement 3D rendering without a bulky external framework (like Unity or three.js), the app uses a custom orthographic-to-perspective projection pipeline defined in [orbital_engine.dart](file:///Users/shouryasonu/Development/solar_system/lib/core/math/orbital_engine.dart).

### 3D Coordinate Mapping
Orbits are projected on the horizontal **X-Z plane** rather than the standard 2D canvas X-Y plane.
* **$X$-Coordinate**: Represents left-right horizontal distance: $X = R \cos(\theta)$
* **$Y$-Coordinate**: Represents elevation (always $0.0$ for flat orbits).
* **$Z$-Coordinate**: Represents depth distance (pointing into the screen): $Z = R \sin(\theta)$

### Camera Projector (`Projector3D`)
The [Projector3D](file:///Users/shouryasonu/Development/solar_system/lib/core/math/orbital_engine.dart#L33-L81) class rotates and projects 3D coordinates into 2D viewport coordinates using a sequence of matrix-like transformations:

1. **Translation relative to target**:
   $$X_{rel} = X - Target_X$$
   $$Y_{rel} = Y - Target_Y$$
   $$Z_{rel} = Z - Target_Z$$
2. **Rotation around Y-axis (Yaw/Azimuth)**:
   $$X_1 = X_{rel} \cos(\text{azimuth}) - Z_{rel} \sin(\text{azimuth})$$
   $$Y_1 = Y_{rel}$$
   $$Z_1 = X_{rel} \sin(\text{azimuth}) + Z_{rel} \cos(\text{azimuth})$$
3. **Rotation around X-axis (Pitch/Elevation)**:
   $$X_2 = X_1$$
   $$Y_2 = Y_1 \cos(\text{elevation}) - Z_1 \sin(\text{elevation})$$
   $$Z_2 = Y_1 \sin(\text{elevation}) + Z_1 \cos(\text{elevation})$$
4. **Perspective Division**:
   A focal constant ($d = 1600.0$) is used to scale down objects further away:
   $$\text{Perspective Scale} = \frac{d}{d - Z_2}$$
   $$Screen_X = \frac{ViewportWidth}{2} + X_2 \cdot Zoom \cdot \text{Perspective Scale} \cdot \text{SceneScale}$$
   $$Screen_Y = \frac{ViewportHeight}{2} + Y_2 \cdot Zoom \cdot \text{Perspective Scale} \cdot \text{SceneScale}$$

---

## 3. Advanced Custom Painters

The visual depth sorting and overlapping effects are handled manually in the `CustomPainter` implementations:

### Global Depth Sorting (Painter's Algorithm)
In [planet_layer_painter.dart](file:///Users/shouryasonu/Development/solar_system/lib/features/solar_system/painters/planet_layer_painter.dart), depth buffer sorting is simulated using the Painter's Algorithm:
1. All active planets and the Sun are gathered into a list.
2. They are projected to find their camera-space depth ($Z_2$).
3. The list is sorted in ascending order (furthest away painted first, closest painted last).
4. Iterating this list ensures that planets dynamically orbit behind the Sun and pass in front of it correctly.

### Saturn/Uranus 3D Ring Overlaps
Rings cannot be drawn as simple 2D ovals, because half of the ring must render *behind* the planet, while the other half must render *in front* of it.
* In [planet_surface_painter.dart](file:///Users/shouryasonu/Development/solar_system/lib/features/solar_system/painters/planet_surface_painter.dart), the rings are divided into **120 segments** in 3D space.
* The segments are rotated according to the planet's **axial tilt** and the camera's azimuth/elevation.
* During the painting phase, the ring segments are checked relative to the planet's center depth ($Z_2$).
* `paintRingsBehind` only draws segments with $Z_{\text{segment}} < Z_{\text{planet\_center}}$.
* `paintRingsFront` only draws segments with $Z_{\text{segment}} \ge Z_{\text{planet\_center}}$.
* By drawing the planet body between these two calls, the rings wrap around the sphere.

### Asteroid Belt Front/Back Splitting
The asteroid belt surrounds the Sun in a wide ring between Mars and Jupiter:
* In [solar_system_canvas.dart](file:///Users/shouryasonu/Development/solar_system/lib/features/solar_system/widgets/solar_system_canvas.dart), the belt is drawn using two separate `CustomPaint` layers: `AsteroidBeltPainter(drawFront: false)` and `AsteroidBeltPainter(drawFront: true)`.
* The back belt is painted before the planets layer, and the front belt is painted after the planets layer, preventing planets from clipping awkwardly through the belt.

---

## 4. State Management & Interaction System

The state is entirely managed using **Riverpod** with an immutable architecture.

### Notifier Provider (`SolarSystemController`)
The [SolarSystemController](file:///Users/shouryasonu/Development/solar_system/lib/features/solar_system/controllers/solar_system_controller.dart) holds [SolarSystemState](file:///Users/shouryasonu/Development/solar_system/lib/features/solar_system/models/solar_system_state.dart) and updates it via state duplication (`copyWith`). Actions include adding planets, toggling play/pause state, speed adjustment, cinematic mode navigation, and resetting the scene.

### Drag & Drop Mechanics
* **Toolbox**: Uses `Draggable<PlanetModel>` to package a planet catalog card.
* **Canvas**: Wrapped with `DragTarget<PlanetModel>` to intercept drops and call `controller.addPlanet` with the active timestamp to calculate orbital progress.

### Orbit Camera Gestures
The camera is controlled using a custom event listener in [solar_system_canvas.dart](file:///Users/shouryasonu/Development/solar_system/lib/features/solar_system/widgets/solar_system_canvas.dart):
* **Drag to Rotate (1 Finger)**: Listens to `onScaleUpdate` and checks `details.pointerCount == 1`. It updates `_targetAzimuth` and `_targetElevation` using coordinate deltas (`focalPointDelta`), keeping the zoom locked.
* **Pinch to Zoom (2 Fingers)**: Tracks pinch ratios by computing frame-to-frame delta multipliers (`details.scale / _prevScale`) and checks `details.pointerCount >= 2` to prevent scale jitter.
* **Trackpad/Mouse Scroll (Wheel)**: An outer `Listener` intercepts `PointerScrollEvent` and maps scrolling directly to `_targetZoom`.
* **Click to Deselect**: Tapping empty space (`hit == null`) deselects the planet, stops camera tracking, and centers/zooms back out to the Sun.

---

## 5. Mock Interview Questions & Answers

### Q1: How did you implement 3D orbital mechanics in this Flutter app without using packages like `three_3d` or `flutter_cube`?
**Answer:**
I built a custom 3D vector-projection pipeline in Dart. In [orbital_engine.dart](file:///Users/shouryasonu/Development/solar_system/lib/core/math/orbital_engine.dart), the orbital paths are represented in 3D space using coordinates in the horizontal X-Z plane ($X = R\cos\theta$, $Y = 0.0$, $Z = R\sin\theta$). 
I created a `Projector3D` class that translates the coordinates relative to the camera target, performs rotations around the Y-axis (azimuth/yaw) and X-axis (elevation/pitch) using trigonometry, and applies a standard perspective projection using a focal depth constant ($d = 1600.0$):
$$\text{Scale} = \frac{d}{d - z}$$
This scale is multiplied by the screen size, zoom, and coordinate offsets, projecting them into 2D viewport space. This avoided heavy external engine overhead and allowed customized sorting, lighting, and ring segmentation in Vanilla Flutter.

---

### Q2: Why does the Sun look like it's rotating or moving when a planet is selected? How did you fix it?
**Answer:**
When a planet was focused, the camera target (`_targetTarget`) updated to follow the planet's orbital coordinate in real-time. Since the camera viewport remained locked onto the moving planet, the Sun (which is fixed at $(0,0,0)$) appeared to orbit in the opposite direction. 
To keep the Sun static in the center of the viewport at all times, I updated the camera target behavior. In [solar_system_canvas.dart](file:///Users/shouryasonu/Development/solar_system/lib/features/solar_system/widgets/solar_system_canvas.dart), I modified the `_focusPlanet` method to keep the camera target centered on the Sun `(0, 0, 0)` instead of tracking the planet. Tapping a planet still triggers the selection highlight and sidebar details, but the Sun never moves off-center.

---

### Q3: How does depth sorting work for the orbital paths, planets, and the Sun to prevent rendering conflicts?
**Answer:**
I implemented the Painter's Algorithm in [planet_layer_painter.dart](file:///Users/shouryasonu/Development/solar_system/lib/features/solar_system/painters/planet_layer_painter.dart). Instead of painting the Sun and planets in a static index sequence, I project their 3D positions into camera-space. I sort them in a flat list based on their depth ($Z_2$ coordinate relative to the camera). 
The rendering iterates through this sorted list from furthest to closest. This guarantees that when a planet's orbit takes it to the far side of the Sun, its depth is larger, so it is painted first and gets covered by the Sun. When it orbits to the near side, it has a smaller depth, is painted last, and sits on top of the Sun.

---

### Q4: How did you implement Saturn's rings in 3D so they render behind and in front of the planet body correctly?
**Answer:**
Rings cannot be drawn as a single 2D oval path because they must overlap the sphere in front and behind. In [planet_surface_painter.dart](file:///Users/shouryasonu/Development/solar_system/lib/features/solar_system/painters/planet_surface_painter.dart), I project the ring in 3D space by calculating 120 points in a circle tilted by Saturn's axial tilt ($26.7^\circ$). 
I split the ring drawing into two distinct phases relative to the planet center depth ($Z_{\text{planet}}$):
1. **`paintRingsBehind`**: Iterates through the ring points and draws only segments where $Z_{\text{point}} < Z_{\text{planet}}$.
2. **Planet Body Painting**: Draws the solid planet sphere with lighting gradients.
3. **`paintRingsFront`**: Iterates and draws only segments where $Z_{\text{point}} \ge Z_{\text{planet}}$.
This segment-level splitting ensures a mathematically correct overlap effect without path clipping bugs.

---

### Q5: How do you optimize custom painting performance in a Flutter app that runs an active simulation loop?
**Answer:**
Since the canvas repaints on every tick, optimization is critical to maintain 60/120 FPS:
1. **`RepaintBoundary`**: In [solar_system_canvas.dart](file:///Users/shouryasonu/Development/solar_system/lib/features/solar_system/widgets/solar_system_canvas.dart), I isolated the painters (StarField, Orbits, Trails, Asteroids, Planets) inside separate `RepaintBoundary` widgets. This prevents UI updates in the sidebars and panels from forcing canvas repaints.
2. **Separated CustomPainters**: I split rendering into dedicated custom painters (e.g. StarField, AsteroidBelt, Orbits) so that static elements (like background stars) are not redrawn when the planets move.
3. **Avoid Object Allocations in `paint`**: All paints, paths, and gradients are instantiated outside loop iterations or cached where possible.
4. **`shouldRepaint` checks**: I implemented detailed equality checks on `shouldRepaint` methods to avoid redrawing if the camera parameters (azimuth, elevation, zoom, target) or planet lists have not changed.

---

### Q6: How does the Comet's tail behave, and how is it rendered in 3D?
**Answer:**
The Comet has a highly elliptical orbit and leaves a glowing tail pointing away from the Sun. In [planet_surface_painter.dart](file:///Users/shouryasonu/Development/solar_system/lib/features/solar_system/painters/planet_surface_painter.dart#L24-L54), the tail is painted as an oval stretched away from the Sun center:
1. It calculates the vector direction from the Sun center to the Comet center.
2. It projects this vector to calculate a point on the opposite side of the Sun.
3. It draws a path with a linear gradient (fading to transparent) aligned along this offset vector, making the tail dynamically orient away from the Sun as the Comet orbits.
4. The tail size and opacity scale dynamically based on the Comet's distance to the Sun (comet activity).

---

### Q7: Why did you use `GestureDetector.onScaleUpdate` instead of separate drag and pinch handlers, and how did you prevent gestures from conflicting?
**Answer:**
Flutter's `GestureDetector` overrides drag gestures when scale gestures are active, meaning `onPanUpdate` and `onScaleUpdate` cannot run simultaneously on the same widget. Therefore, I consolidated all touch interactions into `onScaleStart` and `onScaleUpdate`.
To prevent conflicts:
* **Single Finger Drag (Rotate)**: In `onScaleUpdate`, I check if `details.pointerCount == 1`. If so, I ignore scale changes and only apply `details.focalPointDelta` to modify azimuth and elevation.
* **Two Finger Pinch (Zoom)**: I check if `details.pointerCount >= 2` and calculate zoom changes. To prevent jumps, I track frame-to-frame delta scale multipliers (`details.scale / _prevScale`) and reset the baseline scale to `1.0` when the gesture starts or changes pointer count.

---

### Q8: How is Riverpod integrated into the custom painting loop?
**Answer:**
The rendering canvas watches `solarSystemControllerProvider` using `ref.watch` in its `build` method. However, since the planet orbits update continuously, running a full state rebuild on every frame via Riverpod would be extremely expensive. 
Instead, we run a local tick loop:
1. `SolarSystemCanvas` uses a single `AnimationController` (`_renderClock`) that repeats infinitely to trigger repaints (`setState`).
2. The controller's time speed is read from the Riverpod state on tick, updating a local variable `_simulationSeconds += dt * state.timeSpeed`.
3. The custom painters project the planetary coordinates using this local `_simulationSeconds` value.
This keeps Riverpod state updates reserved for infrequent events (play/pause, planet drops, sidebar selections), while the high-frequency animation runs efficiently via local state.

---

### Q9: How do you handle mouse/trackpad scrolling for zooming in the iOS Simulator on macOS?
**Answer:**
To support zooming on a Mac trackpad (or mouse wheel), I wrapped the canvas's `GestureDetector` with a `Listener` widget and listened to `onPointerSignal`. 
When a `PointerScrollEvent` is captured, I extract the vertical offset (`pointerSignal.scrollDelta.dy`), calculate a zoom multiplier (`1.0 - dy * scrollSensitivity`), apply it to `_targetZoom`, and call `setState` to repaint. This provides smooth trackpad zooming inside the simulator.

---

### Q10: How does the application handle responsive layouts on mobile phones vs tablets?
**Answer:**
Layout responsiveness is handled in [solar_system_screen.dart](file:///Users/shouryasonu/Development/solar_system/lib/features/solar_system/presentation/solar_system_screen.dart) and [solar_system_canvas.dart](file:///Users/shouryasonu/Development/solar_system/lib/features/solar_system/widgets/solar_system_canvas.dart):
1. **Orientation Check**: If the layout height is greater than its width (portrait), it renders an `_OrientationPrompt` asking the user to rotate their screen to landscape, as the lab relies on a wide split-screen layout.
2. **Collapsible Sidebars**: Both sidebars (Planet Info and Controls Panel) are wrapped in custom `CollapsibleSidePanel` widgets, allowing the user to hide them and maximize canvas space.
3. **Viewport Scale Adjustments**: In `SolarSystemCanvas`, we use `LayoutBuilder` to monitor size. If the viewport height is less than 360px (mobile landscape), we scale the rendering down using a scale factor (`_phoneSceneScale = 0.72`) inside `Projector3D` to ensure orbits are not clipped on small screens.
