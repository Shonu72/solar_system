import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/solar_system_controller.dart';
import 'glass_panel.dart';

class PlanetInfoPanel extends ConsumerWidget {
  const PlanetInfoPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(solarSystemControllerProvider);
    final selected = state.selectedPlanet;

    return DecoratedBox(
      decoration: const BoxDecoration(color: Color(0x22020711)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 4),
            child: Text(
              'SOLAR SYSTEM LAB',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: const Color(0xFFE9F6FF),
                height: 1.05,
                letterSpacing: 0,
              ),
            ),
          ),
          GlassPanel(
            child: Text(
              'Drag & drop planets into the solar system.',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
                height: 1.25,
                letterSpacing: 0,
              ),
            ),
          ),
          Expanded(
            child: GlassPanel(
              margin: const EdgeInsets.fromLTRB(10, 4, 10, 10),
              child: selected == null
                  ? const _EmptySelection()
                  : _SelectedPlanetDetails(name: selected.name),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptySelection extends StatelessWidget {
  const _EmptySelection();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SELECTED PLANET',
          style: TextStyle(
            color: Color(0xFF62C9FF),
            fontWeight: FontWeight.w700,
            fontSize: 12,
            letterSpacing: 0,
          ),
        ),
        Spacer(),
        Icon(Icons.public, color: Color(0xFF314B68), size: 52),
        SizedBox(height: 14),
        Text(
          'Drop a planet, then tap it to inspect mission data.',
          style: TextStyle(
            color: Color(0xFF9EB7D1),
            height: 1.35,
            letterSpacing: 0,
          ),
        ),
        Spacer(),
      ],
    );
  }
}

class _SelectedPlanetDetails extends ConsumerWidget {
  const _SelectedPlanetDetails({required this.name});

  final String name;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planet = ref
        .watch(solarSystemControllerProvider)
        .availablePlanets
        .firstWhere((item) => item.name == name);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SELECTED PLANET',
            style: TextStyle(
              color: Color(0xFF62C9FF),
              fontWeight: FontWeight.w700,
              fontSize: 12,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: planet.colors),
                ),
                child: const SizedBox(width: 50, height: 50),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  planet.name,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _Metric(label: 'Radius', value: planet.radiusLabel),
          _Metric(label: 'Distance', value: planet.distanceLabel),
          _Metric(label: 'Orbital speed', value: planet.orbitalSpeedLabel),
          _Metric(label: 'Rotation', value: planet.rotationPeriodLabel),
          const SizedBox(height: 14),
          for (final fact in planet.facts)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.circle, size: 6, color: Color(0xFF62C9FF)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      fact,
                      style: const TextStyle(
                        color: Color(0xFFC3D5E8),
                        height: 1.25,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF92A6BC),
                letterSpacing: 0,
              ),
            ),
          ),
          Flexible(
            flex: 2,
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFFE9F6FF),
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
