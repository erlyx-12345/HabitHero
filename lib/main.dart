import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';

import 'screens/welcome_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/labs_screen.dart';
import 'screens/streaks_screen.dart'; 

import 'services/database_helper.dart';
import 'services/notification_service.dart';

void main() async {
  // 1. Critical for any background service or database access
  WidgetsFlutterBinding.ensureInitialized();

  String? userName;
  Widget initialScreen = const WelcomeScreen();

  try {
    // 2. Initialize Services in parallel or sequence with safety
    await AndroidAlarmManager.initialize();
    
    final notificationService = NotificationService();
    await notificationService.init();
    
    // Note: On some Android 14+ devices, requestPermissions() can hang the UI 
    // if not handled properly. Wrapped in try-catch to be safe.
    await notificationService.requestPermissions();

    // 3. Database Check
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> user = await db.query('users', limit: 1);

    if (user.isNotEmpty) {
      userName = user.first['name'] ?? "Hero";
      initialScreen = DashboardScreen(userName: userName!);
    }
  } catch (e) {
    // If anything fails, we log it and default to WelcomeScreen instead of a black screen
    debugPrint("HabitHero Init Error: $e");
  }

  runApp(
    HabitHeroApp(
      startScreen: initialScreen,
      userName: userName,
    ),
  );
}

class HabitHeroApp extends StatelessWidget {
  final Widget startScreen;
  final String? userName;

  const HabitHeroApp({
    super.key,
    required this.startScreen,
    this.userName,
  });

  @override
  Widget build(BuildContext context) {
    final String currentUserName = userName ?? "Hero";

    return MaterialApp(
      title: 'HabitHero',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1DB97F),
          primary: const Color(0xFF1DB97F),
        ),
        // Important: Specify the theme context correctly for Google Fonts
        textTheme: GoogleFonts.poppinsTextTheme(ThemeData.light().textTheme),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF8FAFB),
      ),
      home: startScreen,
      routes: {
        '/dashboard': (context) => DashboardScreen(userName: currentUserName),
        '/streaks': (context) => const StreaksScreen(), 
        '/labs': (context) => const LabScreen(),
      },
    );
  }
}