import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/math/orbital_engine.dart';
import '../../../core/models/planet_model.dart';
import '../controllers/solar_system_controller.dart';
import '../models/solar_system_state.dart';
import '../painters/asteroid_belt_painter.dart';
import '../painters/orbit_paths_painter.dart';
import '../painters/orbit_trail_painter.dart';
import '../painters/planet_layer_painter.dart';
import '../painters/star_field_painter.dart';

class SolarSystemCanvas extends ConsumerStatefulWidget {
  const SolarSystemCanvas({super.key});

  @override
  ConsumerState<SolarSystemCanvas> createState() => _SolarSystemCanvasState();
}

class _SolarSystemCanvasState extends ConsumerState<SolarSystemCanvas>
    with TickerProviderStateMixin {
  static const _phoneSceneScale = 0.72;

  // Active camera values used for rendering (interpolated)
  double _activeAzimuth = 0.0;
  double _activeElevation = 0.6;
  double _activeZoom = 1.0;
  Vector3d _activeTarget = const Vector3d(0, 0, 0);

  // Target camera values towards which the active values glide
  double _targetAzimuth = 0.0;
  double _targetElevation = 0.6;
  double _targetZoom = 1.0;
  Vector3d _targetTarget = const Vector3d(0, 0, 0);

  // Tracked planet ID, if any (follows the planet in orbit)
  String? _trackedPlanetId;

  late final AnimationController _renderClock;
  Size _viewportSize = Size.zero;
  Duration? _lastTick;
  Duration? _lastCinematicStep;
  double _simulationSeconds = 0;
  double _sceneScale = 1;

  @override
  void initState() {
    super.initState();
    _renderClock = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )
      ..addListener(_tick)
      ..repeat();
  }

  @override
  void dispose() {
    _renderClock
      ..removeListener(_tick)
      ..dispose();
    super.dispose();
  }

  void _tick() {
    final now = _renderClock.lastElapsedDuration ?? Duration.zero;
    final previous = _lastTick;
    _lastTick = now;
    if (previous == null) {
      return;
    }

    final state = ref.read(solarSystemControllerProvider);
    final delta = now - previous;
    final dt = delta.inMicroseconds / Duration.microsecondsPerSecond;

    if (state.isPlaying) {
      _simulationSeconds += dt * state.timeSpeed;
    }

    // Update smooth camera transitions
    _updateCamera(dt);

    // Call setState to trigger a repaint with updated coordinates
    setState(() {});

    if (state.cinematicModeEnabled &&
        (_lastCinematicStep == null ||
            now - _lastCinematicStep! > const Duration(seconds: 3))) {
      _lastCinematicStep = now;
      ref
          .read(solarSystemControllerProvider.notifier)
          .nextCinematicStep(_simulationSeconds);
    }
  }

  void _updateCamera(double dt) {
    final state = ref.read(solarSystemControllerProvider);

    // Update target coordinates if tracking a planet
    if (_trackedPlanetId != null) {
      final placed = state.placedPlanets.where((p) => p.id == _trackedPlanetId);
      if (placed.isNotEmpty) {
        final planet = placed.first;
        final t = _simulationSeconds - planet.createdAtSeconds;
        final angle = planet.startAngle + t * planet.planet.orbitalSpeed;
        final x = planet.planet.orbitRadius * math.cos(angle);
        final z = planet.planet.orbitRadius * math.sin(angle);
        _targetTarget = Vector3d(x, 0, z);
      }
    }

    if (state.cinematicModeEnabled) {
      // Slowly spin the camera and gently weave elevation for a premium look
      _targetAzimuth += dt * 0.05;
      _targetElevation = 0.5 + math.sin(_simulationSeconds * 0.1) * 0.22;
    }

    // Frame-rate independent exponential interpolation
    const k = 10.0;
    final tFactor = (1.0 - math.exp(-k * dt)).clamp(0.0, 1.0);

    _activeAzimuth += (_targetAzimuth - _activeAzimuth) * tFactor;
    _activeElevation += (_targetElevation - _activeElevation) * tFactor;
    _activeZoom += (_targetZoom - _activeZoom) * tFactor;
    _activeTarget = Vector3d(
      _activeTarget.x + (_targetTarget.x - _activeTarget.x) * tFactor,
      _activeTarget.y + (_targetTarget.y - _activeTarget.y) * tFactor,
      _activeTarget.z + (_targetTarget.z - _activeTarget.z) * tFactor,
    );
  }

  double _prevScale = 1.0;

  void _handleScaleStart(ScaleStartDetails details) {
    _prevScale = 1.0;
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    setState(() {
      // Calculate frame-to-frame delta scale factor
      double deltaScale = 1.0;
      if (details.scale == 1.0) {
        _prevScale = 1.0;
      } else if (_prevScale != 0.0) {
        deltaScale = details.scale / _prevScale;
      }
      _prevScale = details.scale;

      // Apply zoom changes smoothly only if there are at least 2 fingers on screen
      if (details.pointerCount >= 2 && deltaScale != 1.0) {
        _targetZoom = (_targetZoom * deltaScale).clamp(0.18, 5.0);
      }

      // Rotate camera yaw & pitch by accumulating focal point movement
      const rotateSensitivity = 0.006;
      _targetAzimuth -= details.focalPointDelta.dx * rotateSensitivity;
      _targetElevation = (_targetElevation + details.focalPointDelta.dy * rotateSensitivity)
          .clamp(-math.pi / 2 + 0.05, math.pi / 2 - 0.05);

      // Sync active parameters immediately during active gestures for responsiveness
      _activeAzimuth = _targetAzimuth;
      _activeElevation = _targetElevation;
      _activeZoom = _targetZoom;
      _activeTarget = _targetTarget;
    });
  }

  void _handleFocusRequest(SolarSystemState state) {
    switch (state.cameraFocusRequest.targetType) {
      case CameraFocusTargetType.sun:
        _trackedPlanetId = null;
        _targetTarget = const Vector3d(0, 0, 0);
        _targetZoom = 1.05;
        _targetAzimuth = 0.0;
        _targetElevation = 0.6;
        break;
      case CameraFocusTargetType.selectedPlanet:
        final selectedId = state.selectedPlanetId;
        if (selectedId != null) {
          _focusPlanet(selectedId, state);
        }
        break;
      case CameraFocusTargetType.planetName:
        final planetName = state.cameraFocusRequest.planetName;
        if (planetName == null) {
          return;
        }
        for (final placed in state.placedPlanets) {
          if (placed.planet.name == planetName) {
            _focusPlanet(placed.id, state);
            return;
          }
        }
        break;
    }
  }

  void _focusPlanet(String id, SolarSystemState state) {
    // Keep camera focused on the Sun (0, 0, 0) at all times so it doesn't move off-center.
  }

  String? _hitTestPlanet(Offset localPosition, SolarSystemState state, Projector3D projector) {
    final elapsed = _simulationSeconds;
    final sortedPlanets = [...state.placedPlanets];

    final projectedList = sortedPlanets.map((placed) {
      final t = elapsed - placed.createdAtSeconds;
      final angle = placed.startAngle + t * placed.planet.orbitalSpeed;
      final x = placed.planet.orbitRadius * math.cos(angle);
      final z = placed.planet.orbitRadius * math.sin(angle);
      const y = 0.0;
      final proj = projector.project(x, y, z);
      final visualSize = placed.planet.size * _sceneScale * projector.zoom * proj.scale;
      return (id: placed.id, proj: proj, visualSize: visualSize);
    }).toList();

    // Sort descending (closest first)
    projectedList.sort((a, b) => b.proj.z.compareTo(a.proj.z));

    for (final item in projectedList) {
      final planetCenter = Offset(item.proj.x, item.proj.y);
      final hitRadius = math.max(24.0, item.visualSize / 2 + 10);
      if ((localPosition - planetCenter).distance <= hitRadius) {
        return item.id;
      }
    }

    final sunProj = projector.project(0, 0, 0);
    final sunCenter = Offset(sunProj.x, sunProj.y);
    final sunSize = 46.0 * _sceneScale * projector.zoom * sunProj.scale;
    final sunHitRadius = math.max(32.0, sunSize + 10);
    if ((localPosition - sunCenter).distance <= sunHitRadius) {
      return 'sun';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(solarSystemControllerProvider);
    final controller = ref.read(solarSystemControllerProvider.notifier);

    ref.listen<int>(
      solarSystemControllerProvider.select((value) => value.cameraResetToken),
      (previous, next) {
        if (previous != null && previous != next) {
          _simulationSeconds = 0;
          _lastCinematicStep = null;
          _trackedPlanetId = null;
          _targetTarget = const Vector3d(0, 0, 0);
          _targetZoom = 1.0;
          _targetAzimuth = 0.0;
          _targetElevation = 0.6;
        }
      },
    );

    ref.listen<int>(
      solarSystemControllerProvider.select(
        (value) => value.cameraFocusRequest.token,
      ),
      (previous, next) {
        if (previous != next) {
          _handleFocusRequest(ref.read(solarSystemControllerProvider));
        }
      },
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        _viewportSize = Size(constraints.maxWidth, constraints.maxHeight);
        _sceneScale = constraints.maxHeight < 360 ? _phoneSceneScale : 1;

        final projector = Projector3D(
          azimuth: _activeAzimuth,
          elevation: _activeElevation,
          zoom: _activeZoom,
          target: _activeTarget,
          viewportSize: _viewportSize,
          sceneScale: _sceneScale,
        );

        return DragTarget<PlanetModel>(
          onWillAcceptWithDetails: (_) {
            controller.setDropHighlight(true);
            return true;
          },
          onLeave: (_) => controller.setDropHighlight(false),
          onAcceptWithDetails: (details) {
            controller.addPlanet(details.data, _simulationSeconds);
          },
          builder: (context, candidateData, rejectedData) {
            return RepaintBoundary(
              child: Listener(
                onPointerSignal: (pointerSignal) {
                  if (pointerSignal is PointerScrollEvent) {
                    setState(() {
                      // Positive scroll delta dy zoom out, negative zoom in
                      const scrollSensitivity = 0.0015;
                      final zoomFactor = 1.0 - pointerSignal.scrollDelta.dy * scrollSensitivity;
                      _targetZoom = (_targetZoom * zoomFactor).clamp(0.18, 5.0);
                      _activeZoom = _targetZoom;
                    });
                  }
                },
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onScaleStart: _handleScaleStart,
                  onScaleUpdate: _handleScaleUpdate,
                  child: MouseRegion(
                    onHover: (event) {
                      final hit = _hitTestPlanet(event.localPosition, state, projector);
                      controller.hoverPlanet(hit == 'sun' ? null : hit);
                    },
                    onExit: (_) => controller.hoverPlanet(null),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapDown: (details) {
                        final hit = _hitTestPlanet(
                          details.localPosition,
                          state,
                          projector,
                        );
                        if (hit == 'sun' || hit == null) {
                          controller.selectPlanet(null);
                          _trackedPlanetId = null;
                          _targetTarget = const Vector3d(0, 0, 0);
                          _targetZoom = 1.05;
                        } else {
                          controller.selectPlanet(hit);
                          _focusPlanet(hit, state);
                        }
                      },
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          RepaintBoundary(
                            child: CustomPaint(
                              painter: StarFieldPainter(
                                showStars: state.showStars,
                              ),
                            ),
                          ),
                          RepaintBoundary(
                            child: CustomPaint(
                              painter: OrbitPathsPainter(
                                planets: state.availablePlanets,
                                showLabels: state.showOrbitLabels,
                                highlightOrbitIndex: state.highlightOrbitIndex,
                                sceneScale: _sceneScale,
                                projector: projector,
                              ),
                            ),
                          ),
                          RepaintBoundary(
                            child: CustomPaint(
                              painter: OrbitTrailPainter(
                                planets: state.placedPlanets,
                                elapsedSeconds: () => _simulationSeconds,
                                sceneScale: _sceneScale,
                                repaint: _renderClock,
                                projector: projector,
                              ),
                            ),
                          ),
                          RepaintBoundary(
                            child: CustomPaint(
                              painter: AsteroidBeltPainter(
                                sceneScale: _sceneScale,
                                projector: projector,
                                drawFront: false,
                              ),
                            ),
                          ),
                          RepaintBoundary(
                            child: CustomPaint(
                              painter: PlanetLayerPainter(
                                planets: state.placedPlanets,
                                elapsedSeconds: () => _simulationSeconds,
                                selectedPlanetId: state.selectedPlanetId,
                                hoveredPlanetId: state.hoveredPlanetId,
                                showLabels: state.showOrbitLabels,
                                sceneScale: _sceneScale,
                                repaint: _renderClock,
                                projector: projector,
                              ),
                            ),
                          ),
                          RepaintBoundary(
                            child: CustomPaint(
                              painter: AsteroidBeltPainter(
                                sceneScale: _sceneScale,
                                projector: projector,
                                drawFront: true,
                              ),
                            ),
                          ),
                          if (candidateData.isNotEmpty) const _DropOverlay(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _DropOverlay extends StatelessWidget {
  const _DropOverlay();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFF62C9FF), width: 2),
          color: const Color(0xFF0C75BD).withValues(alpha: 0.08),
        ),
        child: const Center(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Color(0xCC07111F),
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              child: Text(
                'Release to place in orbit',
                style: TextStyle(
                  color: Color(0xFFE9F6FF),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

