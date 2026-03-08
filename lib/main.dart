import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/welcome_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/labs_screen.dart'; 
import 'services/database_helper.dart';
import 'services/notification_service.dart';

void main() async {
  // Ensure Flutter is fully initialized before async calls
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize Notification Service
  final notificationService = NotificationService();
  await notificationService.init();

  // 2. Request Permissions (This shows the pop-up on first launch)
  await notificationService.requestPermissions();

  final db = await DatabaseHelper.instance.database;
  
  // Check if a user exists in the 'users' table
  final List<Map<String, dynamic>> user = await db.query('users', limit: 1);
  
  String? userName;
  Widget initialScreen;
  
  if (user.isNotEmpty) {
    // User found - set up for Dashboard entry
    userName = user.first['name'] ?? "Hero";
    initialScreen = DashboardScreen(
      userName: userName!, 
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
        textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1DB97F)),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF8FAFB),
      ),
      home: startScreen,
      routes: {
        '/dashboard': (context) => DashboardScreen(
              userName: userName ?? "Hero", 
            ),
        '/labs': (context) => const LabScreen(),
      },
    );
  }
}