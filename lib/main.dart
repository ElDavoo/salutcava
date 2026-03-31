import 'package:flutter/material.dart';

import 'features/simulation/presentation/simulation_page.dart';

void main() {
  runApp(const SalutCaVaApp());
}

class SalutCaVaApp extends StatelessWidget {
  const SalutCaVaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Salut, ca va?',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F766E),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const SimulationPage(),
    );
  }
}
