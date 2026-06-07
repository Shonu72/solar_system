import 'package:flutter/material.dart';

import '../painters/star_field_painter.dart';
import '../widgets/control_panel.dart';
import '../widgets/planet_info_panel.dart';
import '../widgets/planet_toolbox.dart';
import '../widgets/solar_system_canvas.dart';

class SolarSystemScreen extends StatefulWidget {
  const SolarSystemScreen({super.key});

  @override
  State<SolarSystemScreen> createState() => _SolarSystemScreenState();
}

class _SolarSystemScreenState extends State<SolarSystemScreen> {
  bool _isInfoExpanded = true;
  bool _areControlsExpanded = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RepaintBoundary(
          child: CustomPaint(
            painter: const StarFieldPainter(),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isPortrait = constraints.maxHeight > constraints.maxWidth;
                if (isPortrait) {
                  return const _OrientationPrompt();
                }

                final phoneLandscape = constraints.maxHeight < 520;
                final compact = constraints.maxWidth < 1024;
                final leftWidth = phoneLandscape
                    ? 180.0
                    : compact
                    ? 210.0
                    : 278.0;
                final rightWidth = phoneLandscape
                    ? 70.0
                    : compact
                    ? 88.0
                    : 118.0;
                final collapsedWidth = phoneLandscape ? 44.0 : 54.0;
                final toolboxHeight = phoneLandscape
                    ? 96.0
                    : compact
                    ? 126.0
                    : 154.0;
                final infoExpanded = phoneLandscape ? false : _isInfoExpanded;

                return Column(
                  children: [
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          CollapsibleSidePanel(
                            key: const ValueKey('info-sidebar'),
                            expandedWidth: leftWidth,
                            collapsedWidth: collapsedWidth,
                            isExpanded: infoExpanded,
                            side: SidebarSide.left,
                            label: 'Planet info',
                            expandedIcon: Icons.arrow_left_outlined,
                            collapsedIcon: Icons.arrow_right_outlined,
                            onToggle: () {
                              setState(() {
                                _isInfoExpanded = !_isInfoExpanded;
                              });
                            },
                            child: const PlanetInfoPanel(),
                          ),
                          const Expanded(child: SolarSystemCanvas()),
                          CollapsibleSidePanel(
                            key: const ValueKey('controls-sidebar'),
                            expandedWidth: rightWidth,
                            collapsedWidth: collapsedWidth,
                            isExpanded: _areControlsExpanded,
                            side: SidebarSide.right,
                            label: 'Controls',
                            expandedIcon: Icons.keyboard_tab,
                            collapsedIcon: Icons.arrow_left_outlined,
                            onToggle: () {
                              setState(() {
                                _areControlsExpanded = !_areControlsExpanded;
                              });
                            },
                            child: const ControlPanel(),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: toolboxHeight,
                      child: const PlanetToolbox(),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

enum SidebarSide { left, right }

class CollapsibleSidePanel extends StatelessWidget {
  const CollapsibleSidePanel({
    super.key,
    required this.expandedWidth,
    required this.collapsedWidth,
    required this.isExpanded,
    required this.side,
    required this.label,
    required this.expandedIcon,
    required this.collapsedIcon,
    required this.onToggle,
    required this.child,
  });

  final double expandedWidth;
  final double collapsedWidth;
  final bool isExpanded;
  final SidebarSide side;
  final String label;
  final IconData expandedIcon;
  final IconData collapsedIcon;
  final VoidCallback onToggle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: isExpanded ? expandedWidth : collapsedWidth,
      child: DecoratedBox(
        decoration: const BoxDecoration(color: Color(0x33020711)),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: ClipRect(
                child: isExpanded
                    ? AnimatedOpacity(
                        duration: const Duration(milliseconds: 160),
                        opacity: 1,
                        child: child,
                      )
                    : const SizedBox.shrink(),
              ),
            ),
            Align(
              alignment: side == SidebarSide.left
                  ? Alignment.topRight
                  : Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Tooltip(
                  message: isExpanded ? 'Collapse $label' : 'Expand $label',
                  child: IconButton.filledTonal(
                    key: ValueKey(
                      side == SidebarSide.left
                          ? 'toggle-info-sidebar'
                          : 'toggle-controls-sidebar',
                    ),
                    onPressed: onToggle,
                    icon: Icon(isExpanded ? expandedIcon : collapsedIcon),
                    color: const Color(0xFFE9F6FF),
                    style: IconButton.styleFrom(
                      fixedSize: const Size(42, 42),
                      backgroundColor: const Color(0xFF0C1B2B),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (!isExpanded)
              Center(
                child: RotatedBox(
                  quarterTurns: side == SidebarSide.left ? 3 : 1,
                  child: Text(
                    label.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF62C9FF),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ),
          ],
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
