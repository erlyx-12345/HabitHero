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
 /// Main data fetch: Retrieves habits and their log status (Completed vs Skipped)
 // inside dashboard_controller.dart

Future<List<Map<String, dynamic>>> getHabitsWithLogs({DateTime? date}) async {
  final db = await dbHelper.database;
  DateTime targetDate = date ?? DateTime.now(); 
  String dateStr = DateFormat('yyyy-MM-dd').format(targetDate);

  final List<Map<String, dynamic>> habitsData = await db.rawQuery('''
    SELECT h.*, l.isCompleted, l.isSkipped
    FROM habits h
    LEFT JOIN daily_logs l ON h.id = l.habitId AND l.date = ?
    WHERE (h.endDate IS NULL OR h.endDate = '' OR date(h.endDate) >= date(?))
    AND (h.startDate IS NULL OR h.startDate = '' OR date(h.startDate) <= date(?))
  ''', [dateStr, dateStr, dateStr]); 

  List<Map<String, dynamic>> processedHabits = habitsData.map((habit) {
    // FIX: Explicitly handle null values from the LEFT JOIN
    // If there is no log, habit['isCompleted'] is NULL, not 0.
    final bool isDone = (habit['isCompleted'] ?? 0) == 1;
    final bool isSkipped = (habit['isSkipped'] ?? 0) == 1; 
    
    final String habitTime = habit['timeOfDay'] ?? "Morning";
    
    // If isSkipped is true, isMissed should be false
    bool isMissed = !isSkipped && _calculateIsMissed(isDone, habitTime, targetDate);

    return {
      ...habit,
      'isCompleted': isDone,
      'isSkipped': isSkipped, 
      'isMissed': isMissed,
      'isFinished': isDone || isMissed || isSkipped,
    };
  }).toList();

  // Sorting logic remains the same...
  processedHabits.sort((a, b) {
    int aStatus = a['isFinished'] ? 1 : 0;
    int bStatus = b['isFinished'] ? 1 : 0;
    if (aStatus != bStatus) return aStatus.compareTo(bStatus);
    return (a['id'] as int).compareTo(b['id'] as int);
  });

  return processedHabits;
}

  /// Updated to use the new isSkipped column instead of using -1 in isCompleted
  Future<void> deleteHabitForDate(int habitId, DateTime selectedDate) async {
    final db = await dbHelper.database;
    final String dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);

    await db.insert('daily_logs', {
      'habitId': habitId,
      'date': dateStr,
      'isCompleted': 0, 
      'isSkipped': 1, // Correctly using the new column
    }, conflictAlgorithm: ConflictAlgorithm.replace);
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