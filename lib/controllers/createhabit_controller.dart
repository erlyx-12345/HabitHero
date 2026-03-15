import 'package:intl/intl.dart';
import '../models/habit_model.dart';
import '../services/habit_service.dart';
import '../services/database_helper.dart';
import '../services/notification_service.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter/material.dart';

class CreateHabitController {
  final HabitService _service = HabitService();
  final dbHelper = DatabaseHelper.instance;
  final NotificationService _notificationService = NotificationService();

  Future<List<FocusArea>> fetchFocusAreas() async {
    return await _service.getFocusAreas();
  }


 // Change your method to this:
Future<void> createCustomCategory(String name, int iconCode, int colorHex) async {
  // Pass all THREE arguments to the dbHelper
  await dbHelper.insertCustomFocusArea(name, iconCode, colorHex);
}

Future<void> _syncNotification(
  int id,
  String title,
  int reminderActive,
  String? timeStr,
) async {

  if (reminderActive == 1 && timeStr != null && timeStr.isNotEmpty) {

    try {

      final parts = timeStr.split(':');

      final int hour = int.parse(parts[0]);
      final int minute = int.parse(parts[1]);

      await _notificationService.scheduleHabitReminder(
        id,
        title,
        hour,
        minute,
      );

    } catch (e) {
      print("Notification Sync Error: $e");
    }

  } else {

    await _notificationService.cancelReminder(id);

  }
}

  Future<int> addCustomizedHabit({
    required String title,
    required String focusArea,
    required String timeOfDay,
    required int iconCode,
    required int colorHex,
    required int reminder,
    String? reminderTime,
    String? endDate,
  }) async {
    final db = await dbHelper.database;

    final int habitId = await db.insert('habits', {
      'focusArea': focusArea,
      'title': title,
      'timeOfDay': timeOfDay,
      'iconCode': iconCode,
      'colorHex': colorHex,
      'reminder': reminder,
      'reminderTime': reminderTime,
      'endDate': endDate,
      'currentTier': 1,
      'streak': 0,
      'resistance': 50,
    });

    // --- TRIGGER NOTIFICATION HERE ---
    _syncNotification(habitId, title, reminder, reminderTime);

    if (_isTimeSlotPassed(timeOfDay)) {
      final String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      await db.insert('daily_logs', {
        'habitId': habitId,
        'date': today,
        'isCompleted': -1,
      });
    }
    
    return habitId;
  }

  Future<int> updateHabit({
    required int id,
    required String title,
    required String focusArea,
    required String timeOfDay,
    required int iconCode,
    required int colorHex,
    required int reminder,
    String? reminderTime,
    String? endDate,
  }) async {
    final db = await dbHelper.database;
    
    int count = await db.update(
      'habits',
      {
        'title': title,
        'focusArea': focusArea,
        'timeOfDay': timeOfDay,
        'iconCode': iconCode,
        'colorHex': colorHex,
        'reminder': reminder,
        'reminderTime': reminderTime,
        'endDate': endDate,
      },
      where: 'id = ?',
      whereArgs: [id],
    );

    // --- TRIGGER NOTIFICATION UPDATE HERE ---
    // We cancel the old one and set the new one automatically
    _syncNotification(id, title, reminder, reminderTime);

    return count;
  }

  Future<void> deleteHabit(int habitId) async {
    final db = await dbHelper.database;
    
    // Cancel the notification first so it doesn't fire for a deleted habit
    await _notificationService.cancelReminder(habitId);
    
    await db.transaction((txn) async {
      await txn.delete('daily_logs', where: 'habitId = ?', whereArgs: [habitId]);
      await txn.delete('habits', where: 'id = ?', whereArgs: [habitId]);
    });
  }

  bool _isTimeSlotPassed(String timeOfDay) {
    final now = DateTime.now();
    final hour = now.hour;
    switch (timeOfDay.toLowerCase()) {
      case 'morning': return hour >= 12;
      case 'afternoon': return hour >= 17;
      case 'evening': return hour >= 22;
      default: return false;
    }
  }

  Future<bool> doesHabitExist(String title, String timeOfDay) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> result = await db.query(
      'habits',
      where: 'LOWER(TRIM(title)) = ? AND LOWER(TRIM(timeOfDay)) = ?',
      whereArgs: [title.trim().toLowerCase(), timeOfDay.trim().toLowerCase()],
    );
    return result.isNotEmpty;
  }
}