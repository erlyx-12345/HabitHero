import '../services/database_helper.dart';
import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';

class StreaksController {
  final DatabaseHelper _db = DatabaseHelper.instance;

  String _getDateString(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

  /// --- THE SYNC ENGINE ---
  /// Corrected: Skips are ignored. Only creates a "Miss" if no log (Done or Skip) exists.
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

      // Check if ANY log exists for today (Completion OR Skip)
      final List<Map<String, dynamic>> todayLogs = await db.query(
        'daily_logs',
        where: 'habitId = ? AND date = ?',
        whereArgs: [habitId, todayStr],
      );

      // 2. Missed Logic: ONLY trigger if there is NO log at all.
      // If todayLogs has a Skip (isSkipped = 1), this block is bypassed.
      if (todayLogs.isEmpty) {
        bool isNowMissed = false;

        if (customTime != null && customTime.contains(':')) {
          final int scheduledHour = int.parse(customTime.split(':')[0]);
          if (currentHour > scheduledHour) isNowMissed = true;
        } 
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
            'isSkipped': 0, // Explicitly not a skip
          }, conflictAlgorithm: ConflictAlgorithm.ignore);

          await db.update('habits', {'streak': 0}, where: 'id = ?', whereArgs: [habitId]);
        }
      }
    }
  }

  /// --- UPDATED STREAK LOGIC ---
  /// Logic: Completed = +1, Skipped = Neutral (Keep going), Missed = Reset to 0.
  int calculateStrictStreak(List<Map<String, dynamic>> logs) {
    if (logs.isEmpty) return 0;

    // Sort logs by date descending (newest first)
    final List<Map<String, dynamic>> sortedLogs = List.from(logs)
      ..sort((a, b) => b['date'].compareTo(a['date']));

    int streak = 0;
    bool streakActive = false;
    
    final String today = _getDateString(DateTime.now());
    final String yesterday = _getDateString(DateTime.now().subtract(const Duration(days: 1)));

    // 1. Determine if the streak is still valid (Last action was Today or Yesterday)
    // We look for the most recent log that is NOT a skip to see if the streak is alive.
    final latestNonSkip = sortedLogs.firstWhere(
      (l) => (l['isSkipped'] ?? 0) == 0, 
      orElse: () => {},
    );

    if (latestNonSkip.isEmpty) return 0;
    
    String lastActiveDate = latestNonSkip['date'];
    bool isCompleted = latestNonSkip['isCompleted'] == 1;

    // If the last thing you did was "Miss" (isCompleted 0, isSkipped 0), streak is dead.
    if (!isCompleted) return 0;

    // If the last completion was too long ago (before yesterday), streak is dead.
    if (lastActiveDate != today && lastActiveDate != yesterday) return 0;

    // 2. Count the streak
    for (var log in sortedLogs) {
      if (log['isCompleted'] == 1) {
        streak++; // Completion adds to streak
      } else if ((log['isSkipped'] ?? 0) == 1) {
        continue; // Skip is invisible to the streak (neutral)
      } else {
        break; // A true "Miss" (isCompleted 0, isSkipped 0) breaks the streak
      }
    }

    return streak;
  }

  // --- Summary Methods ---
  Future<Map<String, dynamic>> getTodayStats() async {
    await _syncDatabaseStreaks(); 
    final List<Map<String, dynamic>> habits = await _db.getAllHabits();
    final String todayStr = _getDateString(DateTime.now());
    
    int maxStreak = 0;
    int finishedToday = 0;
    int totalActiveToday = 0;

    for (var habit in habits) {
      // 1. LIFECYCLE CHECK: Is the habit active today?
      bool isWithinLifecycle = true;
      if (habit['startDate'] != null && habit['startDate'].toString().isNotEmpty) {
        if (todayStr.compareTo(habit['startDate'].toString()) < 0) isWithinLifecycle = false;
      }
      if (habit['endDate'] != null && habit['endDate'].toString().isNotEmpty) {
        if (todayStr.compareTo(habit['endDate'].toString()) > 0) isWithinLifecycle = false; 
      }

      // If the habit is retired or hasn't started yet, skip it entirely
      if (!isWithinLifecycle) continue;

      final logs = await _db.getLogsForHabit(habit['id']);
      
      // Update Max Streak
      int liveStreak = calculateStrictStreak(logs);
      if (liveStreak > maxStreak) maxStreak = liveStreak;

      // 2. CHECK STATUS
      final bool isDoneToday = logs.any((log) => 
        log['date'] == todayStr && log['isCompleted'] == 1
      );
      
      final bool isSkippedToday = logs.any((log) => 
        log['date'] == todayStr && (log['isSkipped'] ?? 0) == 1
      );
      
      if (isDoneToday) {
        finishedToday++;
      }

      // 3. THE FIX: Include habits that are neither done nor skipped (Pending)
      // Only exclude if the user EXPLICITLY skipped it today.
      if (!isSkippedToday) {
        totalActiveToday++;
      }
    }

    return {
      'currentStreak': maxStreak,
      'habitsFinished': finishedToday,
      'completionRate': totalActiveToday == 0 ? 0 : (finishedToday / totalActiveToday * 100).toInt(),
    };
  }
  
  Future<List<Map<String, dynamic>>> getAllHabitStats() async {
    await _syncDatabaseStreaks(); 
    final List<Map<String, dynamic>> habits = await _db.getAllHabits();
    List<Map<String, dynamic>> enrichedHabits = [];
    final String todayStr = _getDateString(DateTime.now());

    for (var habit in habits) {
      // --- OPTIONAL: Only show active habits in the main list ---
      // If you want to keep retired habits in the list but show they are "Ended", 
      // remove the next 6 lines.
      if (habit['startDate'] != null && habit['startDate'].toString().isNotEmpty) {
        if (todayStr.compareTo(habit['startDate'].toString()) < 0) continue;
      }
      if (habit['endDate'] != null && habit['endDate'].toString().isNotEmpty) {
        if (todayStr.compareTo(habit['endDate'].toString()) > 0) continue; 
      }

      final logs = await _db.getLogsForHabit(habit['id']);
      
      bool isMissedToday = logs.any((l) => 
        l['date'] == todayStr && l['isCompleted'] == 0 && (l['isSkipped'] ?? 0) == 0
      );
      bool isDoneToday = logs.any((l) => 
        l['date'] == todayStr && l['isCompleted'] == 1
      );
      bool isSkippedToday = logs.any((l) => 
        l['date'] == todayStr && (l['isSkipped'] ?? 0) == 1
      );

      Map<String, dynamic> mutableHabit = Map.from(habit);
      mutableHabit['liveStreak'] = calculateStrictStreak(logs);
      mutableHabit['isMissed'] = isMissedToday;
      mutableHabit['isCompletedToday'] = isDoneToday;
      mutableHabit['isSkippedToday'] = isSkippedToday;
      
      enrichedHabits.add(mutableHabit);
    }
    return enrichedHabits;
  }

  String getConsistencyRank(int streak) {
    if (streak >= 30) return "Legendary";
    if (streak >= 14) return "Elite";
    if (streak >= 7) return "Consistent";
    if (streak >= 3) return "Focused";
    return "Building";
  }

  /// 3. Deep Analysis Modal Data (Corrected for Skipped Habits)
  Future<Map<String, dynamic>> getHabitDeepAnalysis(int habitId) async {
    // Get all logs for this specific habit
    final logs = await _db.getLogsForHabit(habitId);
    
    // 1. Filter counts
    int totalCompleted = logs.where((l) => l['isCompleted'] == 1).length;
    int totalMissed = logs.where((l) => l['isCompleted'] == 0 && (l['isSkipped'] ?? 0) == 0).length;
    
    // Total accountable days (ignores skips)
    int accountableDays = logs.where((l) => (l['isSkipped'] ?? 0) == 0).length;

    // 2. Calculate Longest Streak (Ignoring skips)
    int longest = 0;
    int currentRunning = 0;
    
    // Sort logs by date ascending to calculate history
    final sortedLogs = List.from(logs)..sort((a,b) => a['date'].compareTo(b['date']));
    
    for (var log in sortedLogs) {
      if (log['isCompleted'] == 1) {
        currentRunning++;
        if (currentRunning > longest) longest = currentRunning;
      } else if ((log['isSkipped'] ?? 0) == 1) {
        // Skip is neutral: don't increment, but don't reset
        continue; 
      } else {
        // A true miss resets the historical streak
        currentRunning = 0;
      }
    }

    return {
      'longestStreak': longest,
      'missedDays': totalMissed,
      'totalAccomplished': totalCompleted,
      // Completion rate only counts days where you were actually "accountable"
      'completionRate': accountableDays == 0 
          ? 0 
          : ((totalCompleted / accountableDays) * 100).toInt(),
    };
  }

  // 1. Get habits with an ongoing streak > 0
  Future<List<Map<String, dynamic>>> getOngoingStreaks() async {
    final all = await getAllHabitStats();
    return all.where((h) => (h['liveStreak'] ?? 0) > 0).toList()
      ..sort((a, b) => (b['liveStreak'] ?? 0).compareTo(a['liveStreak'] ?? 0));
  }

  // 2. Get habits marked as DONE today
  Future<List<Map<String, dynamic>>> getFinishedToday() async {
    final all = await getAllHabitStats();
    return all.where((h) => h['isCompletedToday'] == true).toList();
  }

  // 3. Get all habits applicable for today (Done + Pending)
  Future<List<Map<String, dynamic>>> getCompletionBreakdown() async {
    final all = await getAllHabitStats();
    // Filters out habits that were skipped today to show how the % is calculated
    return all.where((h) => h['isSkippedToday'] == false).toList();
  }
}