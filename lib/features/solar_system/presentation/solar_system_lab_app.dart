import 'package:flutter/material.dart';

import 'solar_system_screen.dart';

class SolarSystemLabApp extends StatelessWidget {
  const SolarSystemLabApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Solar System Lab',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4DB7FF),
          brightness: Brightness.dark,
          surface: const Color(0xFF07111F),
        ),
        scaffoldBackgroundColor: const Color(0xFF020611),
        fontFamily: 'Arial',
      ),
      home: const SolarSystemScreen(),
    );
  }
}
