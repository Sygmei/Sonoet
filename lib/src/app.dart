import 'package:flutter/material.dart';

import 'features/practice/presentation/practice_screen.dart';

class SonoetApp extends StatelessWidget {
  const SonoetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sonoet',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0E7C86),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF7F5EF),
        useMaterial3: true,
      ),
      home: const PracticeScreen(),
    );
  }
}
