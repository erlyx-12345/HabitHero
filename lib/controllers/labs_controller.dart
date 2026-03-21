import '../services/database_helper.dart';
import '../models/habit_model.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

class LabController {
  final dbHelper = DatabaseHelper.instance;

  String _getDateString(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

  /// --- STREAK VALIDATION ENGINE ---
  /// Logic: Skips (isSkipped = 1) do not add to the streak, but they do NOT break it.
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

      // Check date bounds
      if (habit['startDate'] != null && habit['startDate'].toString().isNotEmpty) {
        if (todayStr.compareTo(habit['startDate'].toString()) < 0) continue;
      }
      if (habit['endDate'] != null && habit['endDate'].toString().isNotEmpty) {
        if (todayStr.compareTo(habit['endDate'].toString()) > 0) continue; 
      }

      // 1. Auto-log misses based on time of day
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
            'isSkipped': 0,
          });
        }
      }

      // 2. Fetch logs to calculate streak
      final List<Map<String, dynamic>> logs = await db.query(
        'daily_logs',
        where: 'habitId = ?',
        orderBy: 'date DESC',
      );

      int calculatedStreak = 0;
      if (logs.isNotEmpty) {
        // A streak is active if the last log that wasn't a skip was successful
        // and that success happened today or yesterday (or is a skip today).
        for (var log in logs) {
          if (log['isCompleted'] == 1) {
            calculatedStreak++;
          } else if ((log['isSkipped'] ?? 0) == 1) {
            continue; // Skips are neutral: they don't add, but don't break.
          } else {
            // If it's today and not yet "missed", don't break the streak yet
            if (log['date'] == todayStr) continue;
            break; // A true miss (0 and 0) breaks it
          }
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

  // 1. Filtered Chart Data (Denominator ignores skips)
  Future<List<Map<String, dynamic>>> getFilteredChartData(String timeframe) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> allHabits = await db.query('habits');
    List<Map<String, dynamic>> chartData = [];
    
    for (int i = 6; i >= 0; i--) {
      DateTime targetDate = DateTime.now().subtract(Duration(days: i));
      String targetDateStr = _getDateString(targetDate);
      int totalAccountable = 0;
      int completedOnThisDay = 0;

      for (var habit in allHabits) {
        if (timeframe != "Overall" && habit['timeOfDay'] != timeframe) continue;
        
        // Ensure habit was active during this date
        if (habit['startDate'] != null && habit['startDate'].toString().isNotEmpty) {
          if (targetDateStr.compareTo(habit['startDate'].toString()) < 0) continue;
        }
        if (habit['endDate'] != null && habit['endDate'].toString().isNotEmpty) {
          if (targetDateStr.compareTo(habit['endDate'].toString()) > 0) continue;
        }

        final List<Map<String, dynamic>> log = await db.query(
          'daily_logs',
          where: 'habitId = ? AND date = ?',
          whereArgs: [habit['id'], targetDateStr],
        );

        if (log.isNotEmpty) {
          if ((log.first['isSkipped'] ?? 0) == 1) continue; // Ignore skips
          totalAccountable++;
          if (log.first['isCompleted'] == 1) completedOnThisDay++;
        }
      }
      chartData.add({
        'day': DateFormat('E').format(targetDate).substring(0, 1), 
        'rate': totalAccountable > 0 ? (completedOnThisDay / totalAccountable) : 0.0
      });
    }
    return chartData;
  }

  // 2. Cumulative Completion Rate (Ignores skips in denominator)
  // 2. Cumulative Completion Rate (Fixed: Accounts for "Ghost" Misses)
  Future<double> getCompletionRate() async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> allHabits = await db.query('habits');
    final DateTime now = DateTime.now();
    int totalAccountable = 0;
    int totalDone = 0;

    // Look back at the last 30 days
    for (int i = 0; i < 30; i++) {
      DateTime targetDate = now.subtract(Duration(days: i));
      String targetDateStr = _getDateString(targetDate);

      for (var habit in allHabits) {
        // RULE 1: Ignore habits that hadn't started yet on this specific target date
        if (habit['startDate'] != null && habit['startDate'].toString().isNotEmpty) {
          if (targetDateStr.compareTo(habit['startDate'].toString()) < 0) continue;
        }

        // RULE 2: Ignore habits that had already ended on this specific target date
        if (habit['endDate'] != null && habit['endDate'].toString().isNotEmpty) {
          if (targetDateStr.compareTo(habit['endDate'].toString()) > 0) continue;
        }

        final List<Map<String, dynamic>> log = await db.query(
          'daily_logs',
          where: 'habitId = ? AND date = ?',
          whereArgs: [habit['id'], targetDateStr],
        );

        if (log.isNotEmpty) {
          // RULE 3: If the user explicitly skipped, it is NOT accountable (Ignore in denominator)
          if ((log.first['isSkipped'] ?? 0) == 1) continue;

          // If there is a log and it's not a skip, it's accountable
          totalAccountable++;
          if (log.first['isCompleted'] == 1) {
            totalDone++;
          }
        } else {
          // RULE 4: If there is NO log entry at all, but the habit was active (passed date checks),
          // it counts as a "Missed" day. This makes the rate realistic.
          totalAccountable++; 
          // totalDone does not increment here.
        }
      }
    }

    // Standard percentage calculation
    return totalAccountable > 0 ? (totalDone / totalAccountable) : 0.0;
  }
  // 3. Habit Difficulty Index
  Future<List<Map<String, dynamic>>> getHabitDifficulty() async {
    final db = await dbHelper.database;
    return await db.rawQuery('''
      SELECT 
        h.id, 
        h.title, 
        h.colorHex,
        SUM(CASE WHEN l.isCompleted = 1 THEN 1 ELSE 0 END) as completedCount,
        SUM(CASE WHEN l.isCompleted = 0 AND (l.isSkipped = 0 OR l.isSkipped IS NULL) THEN 1 ELSE 0 END) as missedCount,
        SUM(CASE WHEN (l.isSkipped = 0 OR l.isSkipped IS NULL) THEN 1 ELSE 0 END) as accountableLogs,
        CASE 
          WHEN SUM(CASE WHEN (l.isSkipped = 0 OR l.isSkipped IS NULL) THEN 1 ELSE 0 END) > 0 
          THEN (CAST(SUM(CASE WHEN l.isCompleted = 0 AND (l.isSkipped = 0 OR l.isSkipped IS NULL) THEN 1 ELSE 0 END) AS FLOAT) / 
                SUM(CASE WHEN (l.isSkipped = 0 OR l.isSkipped IS NULL) THEN 1 ELSE 0 END)) * 100 
          ELSE 0.0 
        END as difficultyRate
      FROM habits h 
      LEFT JOIN daily_logs l ON h.id = l.habitId 
      WHERE h.title IS NOT NULL 
      GROUP BY h.id 
      HAVING missedCount > 0 AND difficultyRate >= 50
      ORDER BY difficultyRate DESC 
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
      WHERE (l.isSkipped = 0 OR l.isSkipped IS NULL)
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

  // 5. Momentum Score (Success Rate Trend)
  Future<double> getMomentumScore() async {
    final db = await dbHelper.database;
    final DateTime now = DateTime.now();
    final String today = _getDateString(now);
    final String sevenDaysAgo = _getDateString(now.subtract(const Duration(days: 7)));
    final String fourteenDaysAgo = _getDateString(now.subtract(const Duration(days: 14)));

    var currentRes = await db.rawQuery(
      'SELECT AVG(CAST(isCompleted AS REAL)) as avg FROM daily_logs WHERE date >= ? AND date < ? AND (isSkipped = 0 OR isSkipped IS NULL)', 
      [sevenDaysAgo, today]
    );
    var prevRes = await db.rawQuery(
      'SELECT AVG(CAST(isCompleted AS REAL)) as avg FROM daily_logs WHERE date >= ? AND date < ? AND (isSkipped = 0 OR isSkipped IS NULL)', 
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
      WHERE l.date >= ? AND (l.isSkipped = 0 OR l.isSkipped IS NULL)
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

  // 8. Habit Failure Analysis
  Future<Map<String, dynamic>> getHabitAnalysis(int habitId) async {
    final db = await dbHelper.database;
    final allHabits = await db.query('habits', where: 'id = ?', whereArgs: [habitId]);
    if (allHabits.isEmpty) return {"reason": "Habit not found."};
    
    final habitData = allHabits.first;
    final String? startDateStr = habitData['startDate']?.toString();
    final String thirtyDaysAgo = _getDateString(DateTime.now().subtract(const Duration(days: 30)));

    final List<Map<String, dynamic>> logs = await db.rawQuery('''
      SELECT date, isCompleted FROM daily_logs 
      WHERE habitId = ? AND date >= ? AND (isSkipped = 0 OR isSkipped IS NULL)
      ORDER BY date ASC
    ''', [habitId, thirtyDaysAgo]);

    if (logs.isEmpty) return {"reason": "Not enough data."};

    List<Map<String, dynamic>> validLogs = logs.where((log) {
      if (startDateStr != null && startDateStr.isNotEmpty) {
        return log['date'].toString().compareTo(startDateStr) >= 0;
      }
      return true;
    }).toList();

    int total = validLogs.length;
    int missed = validLogs.where((l) => l['isCompleted'] == 0).length;
    
    int weekendMissed = 0;
    int weekdayMissed = 0;
    for (var log in validLogs) {
      DateTime date = DateTime.parse(log['date']);
      if (log['isCompleted'] == 0) {
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
    } else if (total > 0 && missed > (total * 0.5)) {
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

  // 9. Aegis Insights
 Future<Map<String, dynamic>> getAegisInsights() async {
  try {
    final db = await dbHelper.database;
    
    // 1. Look for missed habits (relevant for "OOH NO" or "STEADY")
    final List<Map<String, dynamic>> missedLogs = await db.rawQuery('''
      SELECT h.title FROM daily_logs l 
      JOIN habits h ON l.habitId = h.id 
      WHERE l.isCompleted = 0 AND (l.isSkipped = 0 OR l.isSkipped IS NULL)
      GROUP BY h.id HAVING COUNT(*) > 0
      ORDER BY COUNT(*) DESC LIMIT 3
    ''');

    // 2. Look for recently completed habits (relevant for "HAPPY GROWTH")
    final List<Map<String, dynamic>> doneLogs = await db.rawQuery('''
      SELECT h.title FROM daily_logs l 
      JOIN habits h ON l.habitId = h.id 
      WHERE l.isCompleted = 1
      ORDER BY l.id DESC LIMIT 3
    ''');

    // Logic: Decide what is RELEVANT to show
    bool hasMisses = missedLogs.isNotEmpty;
    List<String> targets = hasMisses 
        ? missedLogs.map((e) => e['title'].toString()).toList()
        : doneLogs.map((e) => e['title'].toString()).toList();

    // If NO habits exist at all, then we show the "WATCHING" state
    if (targets.isEmpty) {
      return {
        "status": "WATCHING",
        "analysis": "Our helper is watching. Add some tasks to see your progress here!",
        "accentColor": const Color(0xFF64748B),
        "targets": ["new tasks"], 
      };
    }

    String habitText = targets.length > 1 
        ? "${targets.sublist(0, targets.length - 1).join(', ')} and ${targets.last}" 
        : targets.first;

    final double momentum = await getMomentumScore();
    
    // Handle the Status and Analysis based on relevance
    if (hasMisses) {
      bool isStruggling = momentum < -0.05 || targets.length >= 2;
      return {
        "status": isStruggling ? "OOH NO!" : "STEADY",
        "analysis": isStruggling 
            ? "Wait! $habitText are feeling a bit tricky. Let's try to do them now!"
            : "You're doing okay. If you can finish $habitText, you'll be even better tomorrow!",
        "accentColor": isStruggling ? const Color(0xFFEF4444) : const Color(0xFF10B981),
        "targets": targets,
      };
    } else {
      // If no misses, show HAPPY GROWTH using the completed habits
      return {
        "status": "HAPPY GROWTH",
        "analysis": "Everything looks perfect! $habitText are in great shape. You're a star!",
        "accentColor": const Color(0xFF10B981),
        "targets": targets,
      };
    }
  } catch (e) {
    debugPrint("Aegis Analysis Error: $e");
    return {
      "status": "ASLEEP",
      "analysis": "Our helper is taking a nap.",
      "accentColor": const Color(0xFF64748B),
      "targets": ["napping"],
    };
  }
}
  // 10. Neural Lab Insights
 Future<Map<String, dynamic>> getNeuralLabInsights() async {
  try {
    final db = await dbHelper.database;
    
    final List<Map<String, dynamic>> topHabits = await db.rawQuery('''
      SELECT h.title, h.streak, COUNT(l.id) as success_count 
      FROM habits h 
      JOIN daily_logs l ON h.id = l.habitId 
      WHERE l.isCompleted = 1
      GROUP BY h.id 
      ORDER BY h.streak DESC, success_count DESC 
      LIMIT 3
    ''');

    if (topHabits.isEmpty) {
      return {
        "title": "GETTING READY",
        "analysis": "Your little garden is waiting for its first seed! Finish a task to see your progress grow.",
        "accentColor": const Color(0xFF6366F1),
        "highlight": "Ready to play",
      };
    }

    String bestHabit = topHabits.first['title'];
    int bestStreak = topHabits.first['streak'] ?? 0;
    
    String analysis = "";
    String title = "GOOD JOB!";
    Color accent = const Color(0xFF8B5CF6);

    if (bestStreak >= 7) {
      title = "SUPER STAR!";
      analysis = "You are doing amazing with $bestHabit! You've practiced so much that it's now a part of who you are. Keep shining!";
    } else if (bestStreak >= 3) {
      title = "BIG MOMENTUM";
      analysis = "Look at you go! You're really getting the hang of $bestHabit. Don't stop now, you're doing great!";
    } else {
      title = "FIRST STEPS";
      analysis = "Yay! You started $bestHabit. Every big thing starts with a small step like this one. Just keep trying!";
    }

    return {
      "title": title,
      "analysis": analysis,
      "accentColor": accent,
      "highlight": bestHabit,
      "streak": bestStreak,
    };
  } catch (e) {
    return {
      "title": "NAPPING...",
      "analysis": "Our little helper is taking a tiny nap right now.",
      "accentColor": const Color(0xFF64748B),
      "highlight": "Be right back",
    };
  }
}
}