import '../services/database_helper.dart';
import '../models/habit_model.dart';
import 'package:intl/intl.dart';

class LabController {
  final dbHelper = DatabaseHelper.instance;

  // Helper to get local date strings for SQLite
  String _getDateString(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

  /// --- STREAK VALIDATION ENGINE ---
  /// This checks if the user missed yesterday. If they did, the streak is reset to 0.
  /// This is called before fetching 'Elite Habits' to ensure data integrity.
Future<void> syncStreaks() async {
  final db = await dbHelper.database;
  final now = DateTime.now();
  final String todayStr = _getDateString(now);
  final String yesterdayStr = _getDateString(now.subtract(const Duration(days: 1)));
  final int currentHour = now.hour;

  // 1. Get all habits
  final List<Map<String, dynamic>> habits = await db.query('habits');

  for (var habit in habits) {
    final int habitId = habit['id'];
    final String timeCategory = (habit['timeOfDay'] ?? "Anytime").toString().toLowerCase();

    // --- NEW: RETIREMENT CHECK ---
    // If the habit has an endDate and today is past that date, stop processing it.
    if (habit['endDate'] != null && habit['endDate'].toString().isNotEmpty) {
      if (todayStr.compareTo(habit['endDate'].toString()) > 0) {
        continue; 
      }
    }

    // --- STEP 1: RECORD MISSES FOR TODAY ---
    // Only record a miss if the time window (Morning/Afternoon) has actually passed.
    final List<Map<String, dynamic>> todayLogs = await db.query(
      'daily_logs',
      where: 'habitId = ? AND date = ?',
      whereArgs: [habitId, todayStr],
    );

    if (todayLogs.isEmpty) {
      bool isMissed = false;
      if (timeCategory == 'morning' && currentHour >= 12) isMissed = true;
      else if (timeCategory == 'afternoon' && currentHour >= 18) isMissed = true;

      if (isMissed) {
        await db.insert('daily_logs', {
          'habitId': habitId,
          'date': todayStr,
          'isCompleted': 0,
        });
      }
    }

    // --- STEP 2: RECALCULATE ACTUAL STREAK FROM LOGS ---
    // Fetch only completed logs for this habit, newest first.
    final List<Map<String, dynamic>> logs = await db.query(
      'daily_logs',
      where: 'habitId = ? AND isCompleted = 1',
      orderBy: 'date DESC',
    );

    int calculatedStreak = 0;
    if (logs.isNotEmpty) {
      String lastCompStr = logs.first['date'];
      DateTime lastCompletionDate = DateTime.parse(lastCompStr);
      
      bool isLastCompletedToday = (lastCompStr == todayStr);
      bool isLastCompletedYesterday = (lastCompStr == yesterdayStr);

      // Determine if the habit is "Missed" right now based on the current hour
      bool isCurrentlyMissedToday = false;
      if (timeCategory == 'morning' && currentHour >= 12) isCurrentlyMissedToday = true;
      else if (timeCategory == 'afternoon' && currentHour >= 18) isCurrentlyMissedToday = true;

      // STREAK IS VALID IF:
      // 1. It was finished today.
      // 2. It was finished yesterday AND the time window to do it today hasn't closed yet.
      if (isLastCompletedToday || (isLastCompletedYesterday && !isCurrentlyMissedToday)) {
        String dateToFind = lastCompStr;
        DateTime tempDate = lastCompletionDate;

        for (var log in logs) {
          if (log['date'] == dateToFind) {
            calculatedStreak++;
            tempDate = tempDate.subtract(const Duration(days: 1));
            dateToFind = _getDateString(tempDate);
          } else {
            break; // Gap found in completion dates
          }
        }
      } else {
        // If it wasn't done today/yesterday or the today's window expired, streak is 0.
        calculatedStreak = 0;
      }
    }

    await db.update(
      'habits',
      {'streak': calculatedStreak},
      where: 'id = ?',
      whereArgs: [habitId],
    );
  }
}
  // 1. Filtered Chart Data - Accurate 7-Day Window
  Future<List<Map<String, dynamic>>> getFilteredChartData(String timeframe) async {
    final db = await dbHelper.database;
    List<Map<String, dynamic>> chartData = [];
    
    for (int i = 6; i >= 0; i--) {
      DateTime date = DateTime.now().subtract(Duration(days: i));
      String formattedDate = _getDateString(date);
      
      String query;
      List<dynamic> params;
      
      if (timeframe == "Overall") {
        query = 'SELECT COUNT(id) as total, SUM(CASE WHEN isCompleted = 1 THEN 1 ELSE 0 END) as completed FROM daily_logs WHERE date = ?';
        params = [formattedDate];
      } else {
        query = '''
          SELECT COUNT(l.id) as total, SUM(CASE WHEN l.isCompleted = 1 THEN 1 ELSE 0 END) as completed 
          FROM habits h JOIN daily_logs l ON h.id = l.habitId
          WHERE l.date = ? AND h.timeOfDay = ?
        ''';
        params = [formattedDate, timeframe];
      }
      
      final List<Map<String, dynamic>> result = await db.rawQuery(query, params);
      
      int total = (result.isNotEmpty && result[0]['total'] != null) ? result[0]['total'] as int : 0;
      int completed = (result.isNotEmpty && result[0]['completed'] != null) ? result[0]['completed'] as int : 0;
      
      chartData.add({
        'day': DateFormat('E').format(date).substring(0, 1), 
        'rate': total > 0 ? (completed / total) : 0.0
      });
    }
    return chartData;
  }

  // 2. Completion Rate - Last 30 Days
  Future<double> getCompletionRate() async {
    final db = await dbHelper.database;
    final String thirtyDaysAgo = _getDateString(DateTime.now().subtract(const Duration(days: 30)));
    
    final List<Map<String, dynamic>> result = await db.rawQuery(
      'SELECT COUNT(*) as total, SUM(CASE WHEN isCompleted = 1 THEN 1 ELSE 0 END) as completed FROM daily_logs WHERE date >= ?',
      [thirtyDaysAgo]
    );
    
    int total = (result.isNotEmpty && result[0]['total'] != null) ? result[0]['total'] as int : 0;
    int completed = (result.isNotEmpty && result[0]['completed'] != null) ? result[0]['completed'] as int : 0;
    
    return total > 0 ? (completed / total) : 0.0;
  }

 // 3. Habit Difficulty Index - Accuracy Update
Future<List<Map<String, dynamic>>> getHabitDifficulty() async {
  final db = await dbHelper.database;
  return await db.rawQuery('''
    SELECT 
      h.id,
      h.title, 
      h.colorHex,
      COALESCE(SUM(CASE WHEN l.isCompleted = 1 THEN 1 ELSE 0 END), 0) as completedCount,
      -- totalLogs only counts actual entries (1 or 0)
      CAST(COUNT(l.id) AS FLOAT) as totalLogs,
      CASE 
        WHEN COUNT(l.id) > 0 
        THEN (CAST(SUM(CASE WHEN l.isCompleted = 1 THEN 1 ELSE 0 END) AS FLOAT) / COUNT(l.id)) * 100 
        ELSE 0.0 
      END as successRate
    FROM habits h 
    LEFT JOIN daily_logs l ON h.id = l.habitId 
    GROUP BY h.id 
    ORDER BY successRate ASC 
    LIMIT 3
  ''');
}

  // 4. Time of Day Comparison
  Future<Map<String, double>> getTimeOfDayComparison() async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> res = await db.rawQuery('''
      SELECT h.timeOfDay, 
      AVG(CAST(l.isCompleted AS REAL)) as rate
      FROM habits h JOIN daily_logs l ON h.id = l.habitId
      GROUP BY h.timeOfDay
    ''');
    
    Map<String, double> categories = {"Morning": 0.0, "Afternoon": 0.0, "Evening": 0.0, "Anytime": 0.0};
    for (var item in res) {
      if (item['timeOfDay'] != null) {
        categories[item['timeOfDay'].toString()] = (item['rate'] as double? ?? 0.0);
      }
    }
    return categories;
  }

  // 5. Momentum Score
  Future<double> getMomentumScore() async {
    final db = await dbHelper.database;
    final DateTime now = DateTime.now();
    final String today = _getDateString(now);
    final String sevenDaysAgo = _getDateString(now.subtract(const Duration(days: 7)));
    final String fourteenDaysAgo = _getDateString(now.subtract(const Duration(days: 14)));

    var currentRes = await db.rawQuery(
      'SELECT AVG(CAST(isCompleted AS REAL)) as avg FROM daily_logs WHERE date >= ? AND date < ?', 
      [sevenDaysAgo, today]
    );
    
    var prevRes = await db.rawQuery(
      'SELECT AVG(CAST(isCompleted AS REAL)) as avg FROM daily_logs WHERE date >= ? AND date < ?', 
      [fourteenDaysAgo, sevenDaysAgo]
    );
    
    double current = (currentRes.first['avg'] as num? ?? 0.0).toDouble();
    double previous = (prevRes.first['avg'] as num? ?? 0.0).toDouble();
    
    if (previous == 0) return current; 
    return current - previous; 
  }

  // 6. Drop-off Detection
  Future<List<String>> getDropOffs() async {
    final db = await dbHelper.database;
    final String fiveDaysAgo = _getDateString(DateTime.now().subtract(const Duration(days: 5)));
    
    final res = await db.rawQuery('''
      SELECT h.title FROM habits h JOIN daily_logs l ON h.id = l.habitId
      WHERE l.date >= ?
      GROUP BY h.id 
      HAVING COUNT(l.id) >= 5 AND SUM(l.isCompleted) = 0
    ''', [fiveDaysAgo]);
    
    return res.map((e) => e['title'].toString()).toList();
  }

  // 8. Habit Failure Analysis (The "Why")
  Future<Map<String, dynamic>> getHabitAnalysis(int habitId) async {
    final db = await dbHelper.database;
    final String thirtyDaysAgo = _getDateString(DateTime.now().subtract(const Duration(days: 30)));

    final List<Map<String, dynamic>> logs = await db.rawQuery('''
      SELECT date, isCompleted FROM daily_logs 
      WHERE habitId = ? AND date >= ?
      ORDER BY date ASC
    ''', [habitId, thirtyDaysAgo]);

    if (logs.isEmpty) return {"reason": "Not enough data for analysis."};

    int total = logs.length;
    int missed = logs.where((l) => l['isCompleted'] == 0).length;
    
    // Pattern 1: Weekend vs Weekday
    int weekendMissed = 0;
    int weekdayMissed = 0;
    for (var log in logs) {
      DateTime date = DateTime.parse(log['date']);
      if (log['isCompleted'] == 0) {
        if (date.weekday == DateTime.saturday || date.weekday == DateTime.sunday) {
          weekendMissed++;
        } else {
          weekdayMissed++;
        }
      }
    }

    // Determine primary friction point
    String frictionPoint = "General Consistency";
    String advice = "Try setting a more specific trigger for this habit.";

    if (weekendMissed > weekdayMissed && weekendMissed > 0) {
      frictionPoint = "Weekend Regression";
      advice = "Your routine breaks on Saturdays/Sundays. Try a 'Weekend Mode' reminder.";
    } else if (missed > (total * 0.5)) {
      frictionPoint = "High Friction";
      advice = "This habit might be too ambitious. Try scaling it down to a 2-minute version.";
    } else if (weekdayMissed > weekendMissed) {
      frictionPoint = "Weekday Stress";
      advice = "Workday fatigue is impacting this habit. Try moving it to your morning.";
    }

    return {
      "missedCount": missed,
      "totalCount": total,
      "frictionPoint": frictionPoint,
      "advice": advice,
      "completionRate": ((total - missed) / total) * 100,
    };
  }
  // 7. Elite Habits (Now synced)
  Future<List<Habit>> getEliteHabits() async {
    final db = await dbHelper.database;
    // We fetch habits with the highest streaks. 
    // Since syncStreaks() is called before this in the UI, this list will be accurate.
    final maps = await db.query('habits', orderBy: 'streak DESC', limit: 3);
    return maps.map((h) => Habit.fromMap(h)).toList();
  }
}