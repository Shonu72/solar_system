import 'package:flutter/material.dart';

import '../widgets/control_panel.dart';
import '../widgets/planet_info_panel.dart';
import '../widgets/planet_toolbox.dart';
import '../widgets/solar_system_canvas.dart';

class SolarSystemScreen extends StatelessWidget {
  const SolarSystemScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isPortrait = constraints.maxHeight > constraints.maxWidth;
            if (isPortrait) {
              return const _OrientationPrompt();
            }

            final compact = constraints.maxWidth < 980;
            final leftWidth = compact ? 210.0 : 278.0;
            final rightWidth = compact ? 88.0 : 118.0;
            final toolboxHeight = compact ? 126.0 : 154.0;

            return Column(
              children: [
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        width: leftWidth,
                        child: const PlanetInfoPanel(),
                      ),
                      const Expanded(child: SolarSystemCanvas()),
                      SizedBox(width: rightWidth, child: const ControlPanel()),
                    ],
                  ),
                ),
                SizedBox(height: toolboxHeight, child: const PlanetToolbox()),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _OrientationPrompt extends StatelessWidget {
  const _OrientationPrompt();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF020611), Color(0xFF0B2136)],
        ),
      ),
      child: const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.screen_rotation, color: Color(0xFF62C9FF), size: 44),
              SizedBox(height: 18),
              Text(
                'Rotate to landscape',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Solar System Lab uses a wide mission-control layout.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF9EB7D1), letterSpacing: 0),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
