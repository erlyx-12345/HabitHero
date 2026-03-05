import '../services/database_helper.dart';
import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DashboardController {
  final dbHelper = DatabaseHelper.instance;

  Future<DateTime> getAppStartDate() async {
    final prefs = await SharedPreferences.getInstance();
    const String key = 'app_installation_date';
    String? storedDate = prefs.getString(key);
    
    if (storedDate != null) {
      return DateTime.parse(storedDate);
    } else {
      DateTime now = DateTime.now();
      DateTime dateOnly = DateTime(now.year, now.month, now.day);
      await prefs.setString(key, dateOnly.toIso8601String());
      return dateOnly;
    }
  }

  Future<String?> getUserName() async {
    final db = await dbHelper.database;
    final userData = await db.query('users', limit: 1);
    return userData.isNotEmpty ? userData.first['name'] as String : "Hero";
  }

  Future<List<Map<String, dynamic>>> getHabitsWithLogs({DateTime? date}) async {
    final db = await dbHelper.database;
    DateTime targetDate = date ?? DateTime.now();
    String dateStr = DateFormat('yyyy-MM-dd').format(targetDate);

    final List<Map<String, dynamic>> habitsData = await db.rawQuery('''
      SELECT h.*, l.isCompleted
      FROM habits h
      LEFT JOIN daily_logs l ON h.id = l.habitId AND l.date = ?
      WHERE (h.endDate IS NULL OR h.endDate = '' OR date(h.endDate) >= date(?))
      AND (l.isCompleted IS NULL OR l.isCompleted != -1)
      ORDER BY COALESCE(l.isCompleted, 0) ASC, h.resistance DESC
    ''', [dateStr, dateStr]);

    return habitsData.map((habit) {
      return {
        ...habit,
        'isCompleted': habit['isCompleted'] == 1,
      };
    }).toList();
  }

  Future<void> markHabitAsDone(int habitId, int currentStreak) async {
    final db = await dbHelper.database;
    final String today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    await db.transaction((txn) async {
      await txn.insert('daily_logs', {
        'habitId': habitId,
        'date': today,
        'isCompleted': 1,
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      await txn.update(
        'habits',
        {'streak': currentStreak + 1},
        where: 'id = ?',
        whereArgs: [habitId],
      );
    });
  }

  // OPTION A: Remove for a specific day only
  Future<void> deleteHabitForDate(int habitId, DateTime selectedDate) async {
    final db = await dbHelper.database;
    final String dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);

    await db.insert('daily_logs', {
      'habitId': habitId,
      'date': dateStr,
      'isCompleted': -1, 
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // OPTION B: Delete permanently from everywhere
  Future<void> stopHabitFromToday(int habitId, DateTime selectedDate) async {
    final db = await dbHelper.database;
    
    // We set the endDate to the day BEFORE the selected date.
    // This way, it's considered "expired" when viewed on the selectedDate and beyond.
    DateTime dayBefore = selectedDate.subtract(const Duration(days: 1));
    final String expiryDate = DateFormat('yyyy-MM-dd').format(dayBefore);

    await db.update(
      'habits',
      {'endDate': expiryDate},
      where: 'id = ?',
      whereArgs: [habitId],
    );
  }
  
  double calculateProgress(List<Map<String, dynamic>> habits) {
    if (habits.isEmpty) return 0.0;
    int completed = habits.where((h) => h['isCompleted'] == true).length;
    return completed / habits.length;
  }
}