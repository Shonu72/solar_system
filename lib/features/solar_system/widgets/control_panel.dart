import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/solar_system_controller.dart';
import 'glass_panel.dart';

class ControlPanel extends ConsumerWidget {
  const ControlPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(solarSystemControllerProvider);
    final controller = ref.read(solarSystemControllerProvider.notifier);

    return DecoratedBox(
      decoration: const BoxDecoration(color: Color(0xFF020711)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GlassPanel(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            margin: const EdgeInsets.all(8),
            child: Column(
              children: [
                _ControlButton(
                  icon: Icons.play_arrow,
                  label: 'Play',
                  isActive: state.isPlaying,
                  onPressed: controller.play,
                ),
                _ControlButton(
                  icon: Icons.pause,
                  label: 'Pause',
                  isActive: !state.isPlaying,
                  onPressed: controller.pause,
                ),
                _ControlButton(
                  icon: Icons.restart_alt,
                  label: 'Reset',
                  onPressed: controller.resetScene,
                ),
                _SpeedButton(speed: state.timeSpeed),
                _ControlButton(
                  icon: Icons.movie_creation_outlined,
                  label: 'Cinematic',
                  isActive: state.cinematicModeEnabled,
                  onPressed: () => controller.toggleCinematicMode(0),
                ),
                _ControlButton(
                  icon: Icons.label,
                  label: 'Labels',
                  isActive: state.showOrbitLabels,
                  onPressed: controller.toggleOrbitLabels,
                ),
                _ControlButton(
                  icon: Icons.auto_awesome,
                  label: 'Stars',
                  isActive: state.showStars,
                  onPressed: controller.toggleStars,
                ),
                _ControlButton(
                  icon: Icons.center_focus_strong,
                  label: 'Camera',
                  onPressed: controller.resetCamera,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SpeedButton extends ConsumerWidget {
  const _SpeedButton({required this.speed});

  final double speed;
  static const _speeds = [1.0, 10.0, 100.0, 1000.0];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = _speeds.indexOf(speed);
    final nextSpeed = _speeds[(currentIndex + 1) % _speeds.length];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Tooltip(
        message: 'Time Speed',
        child: TextButton(
          onPressed: () {
            ref
                .read(solarSystemControllerProvider.notifier)
                .setTimeSpeed(nextSpeed);
          },
          style: TextButton.styleFrom(
            fixedSize: const Size(72, 58),
            backgroundColor: const Color(0xFF0C1B2B),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: const BorderSide(color: Color(0xFF274F73)),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.speed, color: Colors.white, size: 22),
              Text(
                '${speed.toStringAsFixed(0)}x',
                style: const TextStyle(
                  color: Color(0xFF62C9FF),
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.isActive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Tooltip(
        message: label,
        child: IconButton.filledTonal(
          onPressed: onPressed,
          icon: Icon(icon),
          color: isActive ? const Color(0xFF62C9FF) : Colors.white,
          style: IconButton.styleFrom(
            fixedSize: const Size(58, 50),
            backgroundColor: isActive
                ? const Color(0xFF12385A)
                : const Color(0xFF0C1B2B),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
    );
  }
}
