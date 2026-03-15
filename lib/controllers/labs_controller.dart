import '../services/database_helper.dart';
import '../models/habit_model.dart';
import 'package:intl/intl.dart';

class LabController {
  final dbHelper = DatabaseHelper.instance;

  String _getDateString(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

  /// --- STREAK VALIDATION ENGINE ---
  Future<void> syncStreaks() async {
    final db = await dbHelper.database;
    final now = DateTime.now();
    final String todayStr = _getDateString(now);
    final String yesterdayStr = _getDateString(now.subtract(const Duration(days: 1)));
    final int currentHour = now.hour;

    final List<Map<String, dynamic>> habits = await db.query('habits');

    for (var habit in habits) {
      final int habitId = habit['id'];
      final String timeCategory = (habit['timeOfDay'] ?? "Anytime").toString().toLowerCase();

      if (habit['startDate'] != null && habit['startDate'].toString().isNotEmpty) {
        if (todayStr.compareTo(habit['startDate'].toString()) < 0) continue;
      }
      if (habit['endDate'] != null && habit['endDate'].toString().isNotEmpty) {
        if (todayStr.compareTo(habit['endDate'].toString()) > 0) continue; 
      }

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

        bool isCurrentlyMissedToday = false;
        if (timeCategory == 'morning' && currentHour >= 12) isCurrentlyMissedToday = true;
        else if (timeCategory == 'afternoon' && currentHour >= 18) isCurrentlyMissedToday = true;

        if (isLastCompletedToday || (isLastCompletedYesterday && !isCurrentlyMissedToday)) {
          String dateToFind = lastCompStr;
          DateTime tempDate = lastCompletionDate;

          for (var log in logs) {
            if (log['date'] == dateToFind) {
              calculatedStreak++;
              tempDate = tempDate.subtract(const Duration(days: 1));
              dateToFind = _getDateString(tempDate);
            } else {
              break; 
            }
          }
        } else {
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

  // 1. Filtered Chart Data
  Future<List<Map<String, dynamic>>> getFilteredChartData(String timeframe) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> allHabits = await db.query('habits');
    List<Map<String, dynamic>> chartData = [];
    
    for (int i = 6; i >= 0; i--) {
      DateTime targetDate = DateTime.now().subtract(Duration(days: i));
      String targetDateStr = _getDateString(targetDate);
      int totalActiveOnThisDay = 0;
      int completedOnThisDay = 0;

      for (var habit in allHabits) {
        if (timeframe != "Overall" && habit['timeOfDay'] != timeframe) continue;
        if (habit['startDate'] != null && habit['startDate'].toString().isNotEmpty) {
          if (targetDateStr.compareTo(habit['startDate'].toString()) < 0) continue;
        }
        if (habit['endDate'] != null && habit['endDate'].toString().isNotEmpty) {
          if (targetDateStr.compareTo(habit['endDate'].toString()) > 0) continue;
        }
        totalActiveOnThisDay++;
        final List<Map<String, dynamic>> log = await db.query(
          'daily_logs',
          where: 'habitId = ? AND date = ? AND isCompleted = 1',
          whereArgs: [habit['id'], targetDateStr],
        );
        if (log.isNotEmpty) completedOnThisDay++;
      }
      chartData.add({
        'day': DateFormat('E').format(targetDate).substring(0, 1), 
        'rate': totalActiveOnThisDay > 0 ? (completedOnThisDay / totalActiveOnThisDay) : 0.0
      });
    }
    return chartData;
  }

  // 2. Cumulative Completion Rate (Consistency Rating)
  Future<double> getCompletionRate() async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> allHabits = await db.query('habits');
    final DateTime now = DateTime.now();
    int totalExpected = 0;
    int totalDone = 0;

    for (int i = 0; i < 30; i++) {
      DateTime targetDate = now.subtract(Duration(days: i));
      String targetDateStr = _getDateString(targetDate);
      for (var habit in allHabits) {
        if (habit['startDate'] != null && habit['startDate'].toString().isNotEmpty) {
          if (targetDateStr.compareTo(habit['startDate'].toString()) < 0) continue;
        }
        if (habit['endDate'] != null && habit['endDate'].toString().isNotEmpty) {
          if (targetDateStr.compareTo(habit['endDate'].toString()) > 0) continue;
        }
        totalExpected++;
        final List<Map<String, dynamic>> log = await db.query(
          'daily_logs',
          where: 'habitId = ? AND date = ? AND isCompleted = 1',
          whereArgs: [habit['id'], targetDateStr],
        );
        if (log.isNotEmpty) totalDone++;
      }
    }
    return totalExpected > 0 ? (totalDone / totalExpected) : 0.0;
  }

  // 3. Habit Difficulty Index - REVERSED Formula
  // This now calculates (Missed / Total) to show which habits are hardest for you.
 Future<List<Map<String, dynamic>>> getHabitDifficulty() async {
    final db = await dbHelper.database;
    return await db.rawQuery('''
      SELECT 
        h.id, 
        h.title, 
        h.colorHex,
        SUM(CASE WHEN l.isCompleted = 1 THEN 1 ELSE 0 END) as completedCount,
        COUNT(l.id) as totalLogs,
        CASE 
          WHEN COUNT(l.id) > 0 
          THEN (CAST(SUM(CASE WHEN l.isCompleted = 0 OR l.isCompleted = -1 THEN 1 ELSE 0 END) AS FLOAT) / COUNT(l.id)) * 100 
          ELSE 0.0 
        END as failureRate
      FROM habits h 
      INNER JOIN daily_logs l ON h.id = l.habitId 
      WHERE h.title IS NOT NULL 
      GROUP BY h.id 
      HAVING totalLogs > 0
      ORDER BY failureRate DESC 
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
    return previous == 0 ? current : current - previous; 
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

  // 7. Elite Habits
  Future<List<Habit>> getEliteHabits() async {
    final db = await dbHelper.database;
    final maps = await db.query('habits', orderBy: 'streak DESC', limit: 3);
    return maps.map((h) => Habit.fromMap(h)).toList();
  }

  // 8. Habit Failure Analysis (Updated with Dashboard logic)
  Future<Map<String, dynamic>> getHabitAnalysis(int habitId) async {
    final db = await dbHelper.database;
    final allHabits = await db.query('habits', where: 'id = ?', whereArgs: [habitId]);
    if (allHabits.isEmpty) return {"reason": "Habit not found."};
    
    final habitData = allHabits.first;
    final String? startDateStr = habitData['startDate'].toString();
    final String thirtyDaysAgo = _getDateString(DateTime.now().subtract(const Duration(days: 30)));

    final List<Map<String, dynamic>> logs = await db.rawQuery('''
      SELECT date, isCompleted FROM daily_logs 
      WHERE habitId = ? AND date >= ?
      ORDER BY date ASC
    ''', [habitId, thirtyDaysAgo]);

    if (logs.isEmpty) return {"reason": "Not enough data."};

    // Filter logs to only count days the habit was actually supposed to be active
    List<Map<String, dynamic>> validLogs = logs.where((log) {
      if (startDateStr != null && startDateStr.isNotEmpty) {
        return log['date'].toString().compareTo(startDateStr) >= 0;
      }
      return true;
    }).toList();

    int total = validLogs.length;
    int missed = validLogs.where((l) => l['isCompleted'] == 0 || l['isCompleted'] == -1).length;
    
    int weekendMissed = 0;
    int weekdayMissed = 0;
    for (var log in validLogs) {
      DateTime date = DateTime.parse(log['date']);
      if (log['isCompleted'] == 0 || log['isCompleted'] == -1) {
        if (date.weekday == DateTime.saturday || date.weekday == DateTime.sunday) {
          weekendMissed++;
        } else {
          weekdayMissed++;
        }
      }
    }

    String frictionPoint = "General Consistency";
    String advice = "Try setting a more specific trigger for this habit.";

    if (weekendMissed > weekdayMissed && weekendMissed > 0) {
      frictionPoint = "Weekend Regression";
      advice = "Routine breaks on weekends. Try a 'Weekend Mode' reminder.";
    } else if (missed > (total * 0.5)) {
      frictionPoint = "High Friction";
      advice = "Scale it down to a 2-minute version.";
    } else if (weekdayMissed > weekendMissed) {
      frictionPoint = "Weekday Stress";
      advice = "Workday fatigue is a factor. Try moving it to your morning.";
    }

    return {
      "missedCount": missed,
      "totalCount": total,
      "frictionPoint": frictionPoint,
      "advice": advice,
      "completionRate": total == 0 ? 0 : ((total - missed) / total) * 100,
    };
  }
}