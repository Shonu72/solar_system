# 🌌 Solar System Lab

An interactive, real-time 3D solar system simulation and orbital mechanics sandbox built with **Flutter** and **Riverpod**.

[![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Riverpod](https://img.shields.io/badge/Riverpod-00599C?style=for-the-badge&logo=flutter&logoColor=white)](https://riverpod.dev)
[![License](https://img.shields.io/badge/License-MIT-green.style=for-the-badge?style=for-the-badge)](LICENSE)

---

## 🎬 Demo Video

Watch the **Solar System Lab** in action: interactive planet drag-and-drop, 3D orbit rotation, smooth cinematic camera movements, dynamic time speed adjustments, and celestial body inspection.

<div align="center">
  <a href="https://res.cloudinary.com/dj6ej7myo/video/upload/v1786600772/solar_t5o3z5.mov">
    <video src="https://res.cloudinary.com/dj6ej7myo/video/upload/v1786600772/solar_t5o3z5.mov" width="100%" controls loop muted poster="https://res.cloudinary.com/dj6ej7myo/video/upload/v1786600772/solar_t5o3z5.jpg">
      Your browser does not support the video tag.
    </video>
  </a>
  <p>🎥 <strong><a href="https://res.cloudinary.com/dj6ej7myo/video/upload/v1786600772/solar_t5o3z5.mov">Click here to watch / download full video demo (.mov)</a></strong></p>
</div>

---

## ✨ Features

- 🪐 **Interactive Drag & Drop Sandbox**: Drag planets from the bottom celestial toolbox directly into solar orbit. Dimming & tooltips automatically inform when a planet is already placed.
- 📐 **Custom 3D Orbital & Projection Engine**: Custom matrix-free 3D math engine supporting Azimuth (yaw), Elevation (pitch), perspective depth scaling, and distance attenuation for realistic 3D space rendering.
- 🎥 **Cinematic Tour & Camera Focus**: Automated guided tour cycling from the Sun through Mercury to Neptune with smooth exponential camera interpolation and weaving camera elevation.
- 🎨 **Multi-Layer CustomPainter Graphics**: Highly optimized rendering architecture with separated custom painters:
  - `StarFieldPainter`: Procedural ambient background twinkling stars.
  - `OrbitPathsPainter`: Rendered elliptical/3D orbit planes with interactive trajectory highlights.
  - `AsteroidBeltPainter`: Dynamic dual-pass asteroid fields.
  - `OrbitTrailPainter`: Fading motion trails tracking orbital velocity.
  - `PlanetLayerPainter` & `PlanetSurfacePainter`: Custom shaders & procedural surfaces for gas giants, rocky terrain, ice giant cloud bands, Saturn/Uranus rings, and comets.
- 🔍 **Interactive Camera Controls**: Free rotation (drag), pinch-to-zoom (0.18x – 5.0x zoom scale), mouse-wheel zoom support, and tap-to-focus on any celestial object.
- ⚡ **Time Simulation Speed Controls**: Adjustable time acceleration from standard `1x` real-time up to `1000x` warp speed with instant pause/play toggles.
- 🛰️ **Glassmorphic Mission Control UI**: Responsive UI panels with glassmorphic styling, collapsible left/right sidebars, rotation orientation prompts for landscape views, and detailed telemetry for every planet (radius, distance, speed, rotation, facts).

---

## 🛰️ Celestial Catalog

| Celestial Body | Type | Radius | Orbit Radius | Rotation Period | Distinct Features |
| :--- | :--- | :--- | :--- | :--- | :--- |
| ☀️ **Sun** | Star | Center | 0 km | 27 days | Solar mass anchor, glowing corona |
| ☿️ **Mercury** | Rocky | 2,439 km | 57.9M km | 58.6 Earth days | Smallest planet, extreme temperatures |
| ♀️ **Venus** | Rocky / Cloudy | 6,051 km | 108.2M km | 243 Earth days | Retrograde rotation, runaway greenhouse |
| 🌎 **Earth** | Ocean / Terrestrial | 6,371 km | 149.6M km | 23.9 hours | Liquid water oceans, supports life |
| ♂️ **Mars** | Rocky / Ice Caps | 3,389 km | 227.9M km | 24.6 hours | Red dust, Olympus Mons volcano |
| ♃ **Jupiter** | Gas Giant | 69,911 km | 778.5M km | 9.9 hours | Great Red Spot, band atmospheric storms |
| ♄ **Saturn** | Gas Giant | 58,232 km | 1.43B km | 10.7 hours | Complex icy ring system, low density |
| ♅ **Uranus** | Ice Giant | 25,362 km | 2.87B km | 17.2 hours | Tilted 97.8° axis, vertical ring system |
| ♆ **Neptune** | Ice Giant | 24,622 km | 4.50B km | 16.1 hours | Fastest winds, deep blue methane clouds |
| 🌙 **Moon** | Satellite | 1,737 km | 384,400 km | 27.3 Earth days | Tidally locked, ocean tide influence |
| ☄️ **Comet** | Small Body | Variable | Elliptical | Irregular | Glowing gas tail pointing away from Sun |

---

## 🏗️ Architecture & Technical Design

### Data Flow

```text
[ User Interaction ] ──► [ SolarSystemController ] ──► [ SolarSystemState (Riverpod) ]
                                                                  │
                                                                  ▼
[ Repaint Loop (60/120 FPS) ] ──► [ Projector3D Engine ] ──► [ CustomPainter Layers ]
```

### Performance Optimization Strategy

1. **Frame-Decoupled Simulation Clock**: The continuous rendering loop (`AnimationController` tick) runs locally inside `SolarSystemCanvas` at 60–120 FPS without updating global Riverpod state on every frame.
2. **Discrete State Management**: Riverpod only handles high-level discrete state transitions (placing planets, selection, toggles, play/pause, time speed).
3. **Layered Painting with `RepaintBoundary`**: Render tree components (starfield background, orbit paths, asteroid belt, orbital trails, and planet surfaces) are isolated in separate `RepaintBoundary` nodes to prevent unnecessary visual invalidation.

---


## 🛠️ Built With

- **[Flutter](https://flutter.dev)** - Multi-platform UI Toolkit
- **[Dart](https://dart.dev)** - Language
- **[Flutter Riverpod](https://riverpod.dev)** - Reactive State Management
- **Custom Painter & Canvas API** - Hardware-accelerated 2D/3D graphics rendering

---


