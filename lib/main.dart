import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const HabitHeroApp());
}

class HabitHeroApp extends StatelessWidget {
  const HabitHeroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HabitHero',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomeScreen(),
    );
  }
}
