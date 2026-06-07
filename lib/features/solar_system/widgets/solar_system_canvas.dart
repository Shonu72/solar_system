import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/math/orbital_engine.dart';
import '../../../core/models/planet_model.dart';
import '../controllers/solar_system_controller.dart';
import '../models/solar_system_state.dart';
import '../painters/orbit_paths_painter.dart';
import '../painters/planet_layer_painter.dart';
import '../painters/star_field_painter.dart';

class SolarSystemCanvas extends ConsumerStatefulWidget {
  const SolarSystemCanvas({super.key});

  @override
  ConsumerState<SolarSystemCanvas> createState() => _SolarSystemCanvasState();
}

class _SolarSystemCanvasState extends ConsumerState<SolarSystemCanvas>
    with TickerProviderStateMixin {
  static const _sceneSize = Size(1180, 690);

  final TransformationController _transformController =
      TransformationController();
  final OrbitalEngine _engine = const OrbitalEngine();

  late final AnimationController _renderClock;
  Animation<Matrix4>? _cameraAnimation;
  Size _viewportSize = Size.zero;
  Duration? _lastTick;
  double _simulationSeconds = 0;

  @override
  void initState() {
    super.initState();
    _renderClock =
        AnimationController(
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
    _transformController.dispose();
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
    if (!state.isPlaying) {
      return;
    }

    final delta = now - previous;
    _simulationSeconds +=
        delta.inMicroseconds / Duration.microsecondsPerSecond * state.timeSpeed;
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
          _animateCamera(Matrix4.identity());
        }
      },
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        _viewportSize = Size(constraints.maxWidth, constraints.maxHeight);
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
              child: InteractiveViewer(
                key: const ValueKey('solar-system-viewer'),
                transformationController: _transformController,
                minScale: 0.55,
                maxScale: 2.8,
                boundaryMargin: const EdgeInsets.all(560),
                constrained: false,
                child: SizedBox(
                  key: const ValueKey('solar-system-drop-zone'),
                  width: _sceneSize.width,
                  height: _sceneSize.height,
                  child: MouseRegion(
                    onHover: (event) {
                      final hit = _hitTestPlanet(event.localPosition, state);
                      controller.hoverPlanet(hit);
                    },
                    onExit: (_) => controller.hoverPlanet(null),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapDown: (details) {
                        final hit = _hitTestPlanet(
                          details.localPosition,
                          state,
                        );
                        controller.selectPlanet(hit);
                        if (hit != null) {
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
                                repaint: _renderClock,
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

  String? _hitTestPlanet(Offset localPosition, SolarSystemState state) {
    final center = Offset(_sceneSize.width / 2, _sceneSize.height / 2);
    final elapsed = _simulationSeconds;
    final sorted = _engine.sortByDepth(state.placedPlanets, elapsed).reversed;
    for (final placed in sorted) {
      final position = _engine.positionFor(
        planet: placed.planet,
        elapsedSeconds: elapsed - placed.createdAtSeconds,
        startAngle: placed.startAngle,
      );
      final planetCenter = Offset(
        center.dx + position.x,
        center.dy + position.y,
      );
      final hitRadius = math.max(
        22,
        placed.planet.size * position.scale / 2 + 10,
      );
      if ((localPosition - planetCenter).distance <= hitRadius) {
        return placed.id;
      }
    }
    return null;
  }

  void _focusPlanet(String id, SolarSystemState state) {
    final placed = state.placedPlanets.where((planet) => planet.id == id);
    if (placed.isEmpty || _viewportSize == Size.zero) {
      return;
    }

    final planet = placed.first;
    final center = Offset(_sceneSize.width / 2, _sceneSize.height / 2);
    final position = _engine.positionFor(
      planet: planet.planet,
      elapsedSeconds: _simulationSeconds - planet.createdAtSeconds,
      startAngle: planet.startAngle,
    );
    final point = Offset(center.dx + position.x, center.dy + position.y);
    const scale = 1.22;
    final target = Matrix4.identity()
      ..translateByDouble(
        _viewportSize.width / 2 - point.dx * scale,
        _viewportSize.height / 2 - point.dy * scale,
        0,
        1,
      )
      ..scaleByDouble(scale, scale, scale, 1);
    _animateCamera(target);
  }

  void _animateCamera(Matrix4 target) {
    final animation =
        Matrix4Tween(begin: _transformController.value, end: target).animate(
          CurvedAnimation(parent: _renderClock, curve: Curves.easeOutCubic),
        );

    _cameraAnimation?.removeListener(_applyCameraAnimation);
    _cameraAnimation = animation..addListener(_applyCameraAnimation);
    _renderClock.reset();
    _lastTick = null;
    _renderClock.repeat();
  }

  void _applyCameraAnimation() {
    final animation = _cameraAnimation;
    if (animation == null) {
      return;
    }
    _transformController.value = animation.value;
    if (_renderClock.value > 0.98) {
      animation.removeListener(_applyCameraAnimation);
      _cameraAnimation = null;
    }
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
