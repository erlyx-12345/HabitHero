import 'package:flutter/material.dart';
import 'screens/welcome_screen.dart';

void main() {
  runApp(const HabitHeroApp());
}

class HabitHeroApp extends StatelessWidget {
  const HabitHeroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HabitHero',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0F5A42)),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF6F6F6),
      ),
      home: const WelcomeScreen(),
    );
  }
}