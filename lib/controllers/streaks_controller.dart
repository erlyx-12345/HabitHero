import '../services/database_helper.dart';
import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';

class StreaksController {
  final DatabaseHelper _db = DatabaseHelper.instance;

  String _getDateString(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

  /// --- THE SYNC ENGINE ---
  /// Matches Dashboard logic: Morning (12pm), Afternoon (5pm), Evening (9pm)
  Future<void> _syncDatabaseStreaks() async {
    final db = await _db.database;
    final now = DateTime.now();
    final String todayStr = _getDateString(now);
    final int currentHour = now.hour;

    final List<Map<String, dynamic>> habits = await db.query('habits');

    for (var habit in habits) {
      final int habitId = habit['id'];
      final String timeCategory = (habit['timeOfDay'] ?? "Anytime").toString().toLowerCase();
      final String? customTime = habit['reminderTime']; 

      // 1. Lifecycle Check
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

      // 2. Missed Logic
      if (todayLogs.isEmpty) {
        bool isNowMissed = false;

        // Custom Manual Time check
        if (customTime != null && customTime.contains(':')) {
          final int scheduledHour = int.parse(customTime.split(':')[0]);
          if (currentHour > scheduledHour) isNowMissed = true;
        } 
        // Dashboard Category windows
        else {
          if (timeCategory == 'morning' && currentHour >= 12) {
            isNowMissed = true;
          } else if (timeCategory == 'afternoon' && currentHour >= 17) {
            isNowMissed = true;
          } else if (timeCategory == 'evening' && currentHour >= 21) {
            isNowMissed = true;
          } else if (currentHour >= 23) {
            isNowMissed = true;
          }
        }

        if (isNowMissed) {
          await db.insert('daily_logs', {
            'habitId': habitId,
            'date': todayStr,
            'isCompleted': 0, 
          }, conflictAlgorithm: ConflictAlgorithm.ignore);

          await db.update('habits', {'streak': 0}, where: 'id = ?', whereArgs: [habitId]);
        }
      }
    }
  }

  /// 1. Today's Summary Stats
  Future<Map<String, dynamic>> getTodayStats() async {
    await _syncDatabaseStreaks(); 
    final List<Map<String, dynamic>> habits = await _db.getAllHabits();
    final String todayStr = _getDateString(DateTime.now());
    
    int maxStreak = 0;
    int finishedToday = 0;
    int totalActiveToday = 0;

    for (var habit in habits) {
      final logs = await _db.getLogsForHabit(habit['id']);
      int liveStreak = calculateStrictStreak(logs);
      if (liveStreak > maxStreak) maxStreak = liveStreak;

      final bool isDoneToday = logs.any((log) => 
        log['date'] == todayStr && log['isCompleted'] == 1
      );
      
      if (isDoneToday) finishedToday++;
      totalActiveToday++;
    }

    return {
      'currentStreak': maxStreak,
      'habitsFinished': finishedToday,
      'completionRate': totalActiveToday == 0 ? 0 : (finishedToday / totalActiveToday * 100).toInt(),
    };
  }

  /// 2. All Habit List
  Future<List<Map<String, dynamic>>> getAllHabitStats() async {
    await _syncDatabaseStreaks(); 
    final List<Map<String, dynamic>> habits = await _db.getAllHabits();
    List<Map<String, dynamic>> enrichedHabits = [];
    final String todayStr = _getDateString(DateTime.now());

    for (var habit in habits) {
      final logs = await _db.getLogsForHabit(habit['id']);
      bool isMissedToday = logs.any((l) => l['date'] == todayStr && l['isCompleted'] == 0);
      bool isDoneToday = logs.any((l) => l['date'] == todayStr && l['isCompleted'] == 1);

      Map<String, dynamic> mutableHabit = Map.from(habit);
      mutableHabit['liveStreak'] = calculateStrictStreak(logs);
      mutableHabit['isMissed'] = isMissedToday;
      mutableHabit['isCompletedToday'] = isDoneToday;
      
      enrichedHabits.add(mutableHabit);
    }
    return enrichedHabits;
  }

  /// 3. Deep Analysis Modal Data
  Future<Map<String, dynamic>> getHabitDeepAnalysis(int habitId) async {
    final logs = await _db.getLogsForHabit(habitId);
    
    int missedCount = logs.where((l) => l['isCompleted'] == 0).length;
    int completedCount = logs.where((l) => l['isCompleted'] == 1).length;

    int longest = 0;
    int current = 0;
    final sortedLogs = List.from(logs)..sort((a,b) => a['date'].compareTo(b['date']));
    for (var log in sortedLogs) {
      if (log['isCompleted'] == 1) {
        current++;
        if (current > longest) longest = current;
      } else {
        current = 0;
      }
    }

    return {
      'longestStreak': longest,
      'missedDays': missedCount,
      'totalAccomplished': completedCount,
      'completionRate': logs.isEmpty ? 0 : (completedCount / logs.length * 100).toInt(),
    };
  }

  /// --- MISSING METHOD FIX ---
  String getConsistencyRank(int streak) {
    if (streak >= 30) return "Legendary";
    if (streak >= 14) return "Elite";
    if (streak >= 7) return "Consistent";
    if (streak >= 3) return "Focused";
    return "Building";
  }

  int calculateStrictStreak(List<Map<String, dynamic>> logs) {
    if (logs.isEmpty) return 0;
    final String today = _getDateString(DateTime.now());
    final String yesterday = _getDateString(DateTime.now().subtract(const Duration(days: 1)));
    
    final completedLogs = logs.where((l) => l['isCompleted'] == 1).toList();
    if (completedLogs.isEmpty) return 0;

    String latestDate = completedLogs.first['date'];
    if (latestDate == today || latestDate == yesterday) {
      int streak = 0;
      DateTime checkDate = DateTime.parse(latestDate);
      for (var log in completedLogs) {
        if (log['date'] == _getDateString(checkDate)) {
          streak++;
          checkDate = checkDate.subtract(const Duration(days: 1));
        } else break;
      }
      return streak;
    }
    return 0;
  }
}