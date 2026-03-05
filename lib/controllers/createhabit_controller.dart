import 'package:intl/intl.dart';
import '../models/habit_model.dart';
import '../services/habit_service.dart';
import '../services/database_helper.dart';

class CreateHabitController {
  final HabitService _service = HabitService();
  final dbHelper = DatabaseHelper.instance;

  // Fetches the categorized habit templates
  Future<List<FocusArea>> fetchFocusAreas() async {
    return await _service.getFocusAreas();
  }

  /// Checks if the selected time slot for today is already over.
  bool _isTimeSlotPassed(String timeOfDay) {
    final now = DateTime.now();
    final hour = now.hour;

    switch (timeOfDay.toLowerCase()) {
      case 'morning':
        return hour >= 12; // Passed if it's 12 PM or later
      case 'afternoon':
        return hour >= 17; // Passed if it's 5 PM or later
      case 'evening':
        return hour >= 22; // Passed if it's 10 PM or later
      default:
        return false; // "Anytime" is never late
    }
  }

  Future<void> addCustomizedHabit({
    required String title,
    required String focusArea,
    required String timeOfDay,
    required int iconCode,
    required int colorHex,
    required int reminder,
    String? endDate,
  }) async {
    final db = await dbHelper.database;

    // 1. Insert the new habit
    final int habitId = await db.insert('habits', {
      'focusArea': focusArea,
      'title': title,
      'timeOfDay': timeOfDay,
      'iconCode': iconCode,
      'colorHex': colorHex,
      'reminder': reminder,
      'endDate': endDate,
      'currentTier': 1,
      'streak': 0,
      'resistance': 50,
    });

    // 2. Adjust for Late Creation: 
    // If user creates a "Morning" habit in the afternoon, 
    // we mark it as "hidden/skipped" for today so it starts tomorrow.
    if (_isTimeSlotPassed(timeOfDay)) {
      final String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      await db.insert('daily_logs', {
        'habitId': habitId,
        'date': today,
        'isCompleted': -1, // -1 acts as the "Hidden" or "Removed" status
      });
    }
  }

  // Add this method to your CreateHabitController class
Future<void> deleteHabit(int habitId) async {
  final db = await dbHelper.database;
  
  // Start a transaction to ensure both deletions happen together
  await db.transaction((txn) async {
    // 1. Delete all daily progress logs for this habit
    await txn.delete(
      'daily_logs',
      where: 'habitId = ?',
      whereArgs: [habitId],
    );
    
    // 2. Delete the habit definition itself
    await txn.delete(
      'habits',
      where: 'id = ?',
      whereArgs: [habitId],
    );
  });
}

  Future<int> updateHabit({
    required int id,
    required String title,
    required String focusArea,
    required String timeOfDay,
    required int iconCode,
    required int colorHex,
    required int reminder,
    String? endDate,
  }) async {
    final db = await dbHelper.database;
    
    return await db.update(
      'habits',
      {
        'title': title,
        'focusArea': focusArea,
        'timeOfDay': timeOfDay,
        'iconCode': iconCode,
        'colorHex': colorHex,
        'reminder': reminder,
        'endDate': endDate,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}