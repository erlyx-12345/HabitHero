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

  Future<void> createCustomCategory(String name, int iconCode, int colorHex) async {
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
        debugPrint("Notification Sync Error: $e");
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
    DateTime? customStartDate,
  }) async {
    final db = await dbHelper.database;

    // Use the custom date if provided (e.g., from a calendar picker)
    // Otherwise, start with today's date
    DateTime startDateTime = customStartDate ?? DateTime.now();

    // LOGIC FIX: If the user creates a habit for a time slot that has already passed today,
    // move the start date to tomorrow so it isn't recorded as a "missed" habit.
    if (customStartDate == null && _isTimeSlotPassed(timeOfDay)) {
      startDateTime = startDateTime.add(const Duration(days: 1));
    }

    final String formattedStartDate = DateFormat('yyyy-MM-dd').format(startDateTime);

    final int habitId = await db.insert('habits', {
      'focusArea': focusArea,
      'title': title,
      'timeOfDay': timeOfDay,
      'iconCode': iconCode,
      'colorHex': colorHex,
      'reminder': reminder,
      'reminderTime': reminderTime,
      'endDate': endDate,
      'startDate': formattedStartDate,
      'currentTier': 1,
      'streak': 0,
      'resistance': 50,
    });

    _syncNotification(habitId, title, reminder, reminderTime);
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

    _syncNotification(id, title, reminder, reminderTime);
    return count;
  }

  Future<void> deleteHabit(int habitId) async {
    final db = await dbHelper.database;
    await _notificationService.cancelReminder(habitId);
    
    await db.transaction((txn) async {
      await txn.delete('daily_logs', where: 'habitId = ?', whereArgs: [habitId]);
      await txn.delete('habits', where: 'id = ?', whereArgs: [habitId]);
    });
  }

  /// Checks if the current time is past the deadline for the chosen time slot.
  bool _isTimeSlotPassed(String timeOfDay) {
    final now = DateTime.now();
    final hour = now.hour;
    
    switch (timeOfDay.toLowerCase()) {
      case 'morning': 
        // If it's 12:00 PM or later, the morning slot is gone.
        return hour >= 12;
      case 'afternoon': 
        // If it's 6:00 PM (18:00) or later, the afternoon slot is gone.
        return hour >= 18;
      case 'evening': 
        // If it's near midnight (e.g., 11 PM), the evening slot is gone.
        return hour >= 23;
      default: 
        return false;
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