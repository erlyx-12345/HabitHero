import '../services/database_helper.dart';
import '../services/habit_service.dart'; // Import the new service
import '../models/habit_model.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter/material.dart'; // Add this line

class TargetController {
  final dbHelper = DatabaseHelper.instance;
  final habitService = HabitService(); // Initialize the service

  Future<bool> saveSelectedTargets(List<String> selectedTargetNames) async {
    try {
      final db = await dbHelper.database;
      
      // 1. Fetch all focus areas from our JSON
      List<FocusArea> allFocusAreas = await habitService.getFocusAreas();

      await db.transaction((txn) async {
        for (String targetName in selectedTargetNames) {
          // 2. Save the Target (Focus Area) to DB
          await txn.insert(
            'targets',
            {'title': targetName},
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );

          // 3. Find the matching FocusArea object from our JSON data
          final matchingArea = allFocusAreas.firstWhere(
            (area) => area.name == targetName,
            orElse: () => FocusArea(name: '', icon: Icons.help, habits: []),
          );

          // 4. Save the habits associated with this focus area
          if (matchingArea.name.isNotEmpty) {
            for (var habit in matchingArea.habits) {
              await txn.insert('habits', {
                'focusArea': targetName,
                'title': habit.title,
                // Since your JSON version is simpler, we set defaults for the tiers
                'hardVersion': habit.title, 
                'mediumVersion': habit.title,
                'easyVersion': habit.title,
                'currentTier': 2, // Start at Hard
                'resistance': 50,
                'streak': 0,
              });
            }
          }
        }
      });
      return true;
    } catch (e) {
      print("Error saving targets and habits from JSON: $e");
      return false;
    }
  }
}