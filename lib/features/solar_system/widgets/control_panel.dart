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
      decoration: const BoxDecoration(color: Color(0x22020711)),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact =
              constraints.maxHeight < 430 || constraints.maxWidth < 90;
          final buttonSize = compact ? const Size(46, 40) : const Size(58, 50);
          final speedSize = compact ? const Size(48, 44) : const Size(72, 58);
          final iconSize = compact ? 20.0 : 24.0;
          final gap = compact ? 2.0 : 4.0;

          final controls = [
            _ControlButton(
              icon: Icons.play_arrow,
              label: 'Play',
              isActive: state.isPlaying,
              size: buttonSize,
              iconSize: iconSize,
              gap: gap,
              onPressed: controller.play,
            ),
            _ControlButton(
              icon: Icons.pause,
              label: 'Pause',
              isActive: !state.isPlaying,
              size: buttonSize,
              iconSize: iconSize,
              gap: gap,
              onPressed: controller.pause,
            ),
            _ControlButton(
              icon: Icons.restart_alt,
              label: 'Reset',
              size: buttonSize,
              iconSize: iconSize,
              gap: gap,
              onPressed: controller.resetScene,
            ),
            _SpeedButton(speed: state.timeSpeed, size: speedSize, gap: gap),
            _ControlButton(
              icon: Icons.movie_creation_outlined,
              label: 'Cinematic',
              isActive: state.cinematicModeEnabled,
              size: buttonSize,
              iconSize: iconSize,
              gap: gap,
              onPressed: () => controller.toggleCinematicMode(0),
            ),
            _ControlButton(
              icon: Icons.label,
              label: 'Labels',
              isActive: state.showOrbitLabels,
              size: buttonSize,
              iconSize: iconSize,
              gap: gap,
              onPressed: controller.toggleOrbitLabels,
            ),
            _ControlButton(
              icon: Icons.auto_awesome,
              label: 'Stars',
              isActive: state.showStars,
              size: buttonSize,
              iconSize: iconSize,
              gap: gap,
              onPressed: controller.toggleStars,
            ),
            _ControlButton(
              icon: Icons.center_focus_strong,
              label: 'Camera',
              size: buttonSize,
              iconSize: iconSize,
              gap: gap,
              onPressed: controller.resetCamera,
            ),
          ];

          return Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(vertical: compact ? 4 : 0),
              child: GlassPanel(
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 4 : 8,
                  vertical: compact ? 6 : 12,
                ),
                margin: EdgeInsets.all(compact ? 4 : 8),
                child: Column(children: controls),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SpeedButton extends ConsumerWidget {
  const _SpeedButton({
    required this.speed,
    required this.size,
    required this.gap,
  });

  final double speed;
  final Size size;
  final double gap;
  static const _speeds = [1.0, 10.0, 100.0, 1000.0];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = _speeds.indexOf(speed);
    final nextSpeed = _speeds[(currentIndex + 1) % _speeds.length];

    return Padding(
      padding: EdgeInsets.symmetric(vertical: gap),
      child: Tooltip(
        message: 'Time Speed',
        child: TextButton(
          onPressed: () {
            ref
                .read(solarSystemControllerProvider.notifier)
                .setTimeSpeed(nextSpeed);
          },
          style: TextButton.styleFrom(
            fixedSize: size,
            backgroundColor: const Color(0xFF0C1B2B),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: const BorderSide(color: Color(0xFF274F73)),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: size.height < 50
                ? [
                    Text(
                      '${speed.toStringAsFixed(0)}x',
                      style: const TextStyle(
                        color: Color(0xFF62C9FF),
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        letterSpacing: 0,
                      ),
                    ),
                  ]
                : [
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
    required this.size,
    required this.iconSize,
    required this.gap,
    this.isActive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Size size;
  final double iconSize;
  final double gap;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: gap),
      child: Tooltip(
        message: label,
        child: IconButton.filledTonal(
          onPressed: onPressed,
          icon: Icon(icon, size: iconSize),
          color: isActive ? const Color(0xFF62C9FF) : Colors.white,
          style: IconButton.styleFrom(
            fixedSize: size,
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
