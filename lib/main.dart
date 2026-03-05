import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/welcome_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/labs_screen.dart'; // Ensure this matches your filename
import 'services/database_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final db = await DatabaseHelper.instance.database;
  
  // 1. Check if a user exists in the 'users' table
  final List<Map<String, dynamic>> user = await db.query('users', limit: 1);
  
  String? userName;
  Widget initialScreen;
  
  if (user.isNotEmpty) {
    // User found - set up for Dashboard entry
    userName = user.first['name'] ?? "Hero";
    initialScreen = DashboardScreen(
      userName: userName!, 
      selectedTargets: const [], 
    );
  } else {
    // New user - show onboarding
    initialScreen = const WelcomeScreen();
  }

  runApp(HabitHeroApp(startScreen: initialScreen, userName: userName));
}

class HabitHeroApp extends StatelessWidget {
  final Widget startScreen;
  final String? userName;

  const HabitHeroApp({super.key, required this.startScreen, this.userName});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HabitHero',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Global Poppins Typography
        textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1DB97F)),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF8FAFB),
      ),
      // Entry point determined by DB check in main()
      home: startScreen,
      
      // Centralized Routing System
      routes: {
        '/dashboard': (context) => DashboardScreen(
              userName: userName ?? "Hero", 
              selectedTargets: const [],
            ),
        '/labs': (context) => const LabScreen(), // Updated route name to /lab
        
        // Placeholders for future modules
        // '/circles': (context) => const CirclesScreen(),
        // '/setup': (context) => const SetupScreen(),
      },
    );
  }
}