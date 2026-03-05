import '../services/database_helper.dart';
import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DashboardController {
  final dbHelper = DatabaseHelper.instance;

  /// Retrieves the date the app was first opened
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

  /// Fetches user name for the header
  Future<String?> getUserName() async {
    final db = await dbHelper.database;
    final userData = await db.query('users', limit: 1);
    return userData.isNotEmpty ? userData.first['name'] as String : "Hero";
  }

  /// Main data fetch: Retrieves habits, calculates missed status, and sorts them
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
    ''', [dateStr, dateStr]);

    // 1. Process and calculate status flags
    List<Map<String, dynamic>> processedHabits = habitsData.map((habit) {
      final bool isDone = habit['isCompleted'] == 1;
      final String habitTime = habit['timeOfDay'] ?? "Morning";
      
      // Check if task is missed based on time of day
      bool isMissed = _calculateIsMissed(isDone, habitTime, targetDate);

      return {
        ...habit,
        'isCompleted': isDone,
        'isMissed': isMissed,
        'isFinished': isDone || isMissed, // Sorting helper
      };
    }).toList();

    // 2. Sorting Logic: Active tasks first, Finished/Missed tasks at the bottom
    processedHabits.sort((a, b) {
      int aStatus = a['isFinished'] ? 1 : 0;
      int bStatus = b['isFinished'] ? 1 : 0;
      
      if (aStatus != bStatus) {
        return aStatus.compareTo(bStatus);
      }
      
      // Secondary sort: Keep consistent order by ID if status is same
      return (a['id'] as int).compareTo(b['id'] as int);
    });

    return processedHabits;
  }

  /// Determines if a habit should be marked as 'Missed'
  bool _calculateIsMissed(bool isDone, String habitTime, DateTime targetDate) {
    if (isDone) return false;

    final now = DateTime.now();
    final DateTime todayDateOnly = DateTime(now.year, now.month, now.day);
    final DateTime targetDateOnly = DateTime(targetDate.year, targetDate.month, targetDate.day);

    // Case 1: Past date and not completed
    if (targetDateOnly.isBefore(todayDateOnly)) return true;

    // Case 2: Today, but the time window has passed
    if (targetDateOnly.isAtSameMomentAs(todayDateOnly)) {
      final String currentPeriod = _getCurrentTimeframe();
      if (currentPeriod == "Afternoon" && habitTime == "Morning") return true;
      if (currentPeriod == "Evening" && (habitTime == "Morning" || habitTime == "Afternoon")) return true;
      if (currentPeriod == "Night") return true;
    }

    return false;
  }

  /// Internal helper for time-of-day logic
  String _getCurrentTimeframe() {
    final hour = DateTime.now().hour;
    if (hour < 12) return "Morning";
    if (hour < 17) return "Afternoon";
    if (hour < 21) return "Evening";
    return "Night";
  }

  /// Marks a habit as completed and updates the streak
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

  /// Hide habit for a specific date
  Future<void> deleteHabitForDate(int habitId, DateTime selectedDate) async {
    final db = await dbHelper.database;
    final String dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);

    await db.insert('daily_logs', {
      'habitId': habitId,
      'date': dateStr,
      'isCompleted': -1, 
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Permanently stop a habit from appearing after a certain date
  Future<void> stopHabitFromToday(int habitId, DateTime selectedDate) async {
    final db = await dbHelper.database;
    DateTime dayBefore = selectedDate.subtract(const Duration(days: 1));
    final String expiryDate = DateFormat('yyyy-MM-dd').format(dayBefore);

    await db.update(
      'habits',
      {'endDate': expiryDate},
      where: 'id = ?',
      whereArgs: [habitId],
    );
  }
  
  /// Calculates percentage for the progress ring
  double calculateProgress(List<Map<String, dynamic>> habits) {
    if (habits.isEmpty) return 0.0;
    int completed = habits.where((h) => h['isCompleted'] == true).length;
    return completed / habits.length;
  }
}