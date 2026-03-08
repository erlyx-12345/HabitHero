import 'package:intl/intl.dart';
import '../models/habit_model.dart';
import '../services/habit_service.dart';
import '../services/database_helper.dart';

class CreateHabitController {
  final HabitService _service = HabitService();
  final dbHelper = DatabaseHelper.instance;

  Future<List<FocusArea>> fetchFocusAreas() async {
    return await _service.getFocusAreas();
  }

  bool _isTimeSlotPassed(String timeOfDay) {
    final now = DateTime.now();
    final hour = now.hour;

    switch (timeOfDay.toLowerCase()) {
      case 'morning':
        return hour >= 12;
      case 'afternoon':
        return hour >= 17;
      case 'evening':
        return hour >= 22;
      default:
        return false;
    }
  }

  // Updated to return Future<int> so we can get the ID for notifications
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
    
    return await db.update(
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

  Future<void> deleteHabit(int habitId) async {
    final db = await dbHelper.database;
    await db.transaction((txn) async {
      await txn.delete('daily_logs', where: 'habitId = ?', whereArgs: [habitId]);
      await txn.delete('habits', where: 'id = ?', whereArgs: [habitId]);
    });
  }
}