import '../services/database_helper.dart';
import 'package:intl/intl.dart';

class StreaksController {
  final DatabaseHelper _db = DatabaseHelper.instance;

  Future<Map<String, dynamic>> getTodayStats() async {
  final List<Map<String, dynamic>> habits = await _db.getAllHabits();
  final String todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
  
  int maxStreak = 0;
  int finishedToday = 0;
  int totalActiveToday = 0;

  for (var habit in habits) {
    // 1. Apply the Dashboard logic: Skip retired or future habits
    if (habit['startDate'] != null && habit['startDate'].toString().isNotEmpty) {
      if (todayStr.compareTo(habit['startDate'].toString()) < 0) continue;
    }
    if (habit['endDate'] != null && habit['endDate'].toString().isNotEmpty) {
      if (todayStr.compareTo(habit['endDate'].toString()) > 0) continue;
    }

    // This habit is visible on the dashboard today
    totalActiveToday++;

    final logs = await _db.getLogsForHabit(habit['id']);
    
    // Calculate streak for the "Current Streak" card
    int liveStreak = calculateStrictStreak(logs);
    if (liveStreak > maxStreak) maxStreak = liveStreak;

    // 2. Check if completed today (Matches your doneCount logic)
    final bool isDoneToday = logs.any((log) => 
      log['date'] == todayStr && log['isCompleted'] == 1
    );
    
    if (isDoneToday) finishedToday++;
  }

  // 3. Final Percentage calculation (matches your CircularProgress logic)
  double completionRate = totalActiveToday == 0 
      ? 0 
      : (finishedToday / totalActiveToday) * 100;

  return {
    'currentStreak': maxStreak,
    'habitsFinished': finishedToday,
    'completionRate': completionRate.toInt(), // Returns the clean percentage (e.g., 100)
  };
}

  Future<List<Map<String, dynamic>>> getAllHabitStats() async {
    final List<Map<String, dynamic>> habits = await _db.getAllHabits();
    List<Map<String, dynamic>> enrichedHabits = [];
    final String todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    for (var habit in habits) {
      if (habit['endDate'] != null && habit['endDate'].toString().isNotEmpty) {
        if (todayStr.compareTo(habit['endDate'].toString()) > 0) {
          continue;
        }
      }

      final logs = await _db.getLogsForHabit(habit['id']);
      int liveStreak = calculateStrictStreak(logs);
      
      Map<String, dynamic> mutableHabit = Map.from(habit);
      mutableHabit['liveStreak'] = liveStreak;
      enrichedHabits.add(mutableHabit);
    }
    return enrichedHabits;
  }

  Future<double> calculateMomentumScore() async {
    final double currentRate = await _db.getCompletionRate(days: 7);
    return currentRate * 100; 
  }

  String getConsistencyRank(int streak) {
    if (streak >= 30) return "Legendary";
    if (streak >= 14) return "Elite";
    if (streak >= 7) return "Consistent";
    return "Building";
  }

  Future<Map<String, dynamic>> getHabitDeepAnalysis(int habitId) async {
    final logs = await _db.getLogsForHabit(habitId);
    final allHabits = await _db.getAllHabits();
    final habitData = allHabits.firstWhere((h) => h['id'] == habitId);
    final String? startDateStr = habitData['startDate'];
    
    int longestStreak = 0;
    int currentTempStreak = 0;
    int missedDays = 0;
    int totalAccomplished = 0;
    int validDaysTracked = 0;

    for (var log in logs.reversed) {
      if (startDateStr != null && log['date'].toString().compareTo(startDateStr) < 0) {
        continue;
      }

      if (log['isCompleted'] == 1) {
        currentTempStreak++;
        totalAccomplished++;
        validDaysTracked++;
        if (currentTempStreak > longestStreak) longestStreak = currentTempStreak;
      } else if (log['isCompleted'] == -1) {
        currentTempStreak = 0;
        missedDays++;
        validDaysTracked++;
      }
    }

    double rate = validDaysTracked == 0 ? 0 : (totalAccomplished / validDaysTracked) * 100;

    return {
      'longestStreak': longestStreak,
      'missedDays': missedDays,
      'totalAccomplished': totalAccomplished,
      'completionRate': rate.toInt(),
      'totalDaysTracked': validDaysTracked,
    };
  }

  int calculateStrictStreak(List<Map<String, dynamic>> logs) {
    if (logs.isEmpty) return 0;

    final String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final String yesterday = DateFormat('yyyy-MM-dd').format(DateTime.now().subtract(const Duration(days: 1)));
    
    final completedLogs = logs.where((l) => l['isCompleted'] == 1).toList();
    if (completedLogs.isEmpty) return 0;

    String latestDate = completedLogs.first['date'];
    
    if (latestDate == today || latestDate == yesterday) {
      int streak = 0;
      DateTime checkDate = DateTime.parse(latestDate);
      
      for (var log in completedLogs) {
        if (log['date'] == DateFormat('yyyy-MM-dd').format(checkDate)) {
          streak++;
          checkDate = checkDate.subtract(const Duration(days: 1));
        } else {
          break;
        }
      }
      return streak;
    }
    
    return 0;
  }
}