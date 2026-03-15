import '../services/database_helper.dart';
import '../controllers/labs_controller.dart';
import 'package:intl/intl.dart';

class StreaksController {
  final DatabaseHelper _db = DatabaseHelper.instance;

  // Fetches every habit created by the user
 Future<List<Map<String, dynamic>>> getAllHabitStats() async {
  final List<Map<String, dynamic>> habits = await _db.getAllHabits();
  List<Map<String, dynamic>> enrichedHabits = [];
  final String todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

  for (var habit in habits) {
    // --- NEW FILTER: Skip if the habit is retired ---
    if (habit['endDate'] != null && habit['endDate'].toString().isNotEmpty) {
      if (todayStr.compareTo(habit['endDate'].toString()) > 0) {
        continue; // Habit is retired, don't show it in the Streaks list
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

  // Momentum logic (7-day completion rate)
  Future<double> calculateMomentumScore() async {
    final double currentRate = await _db.getCompletionRate(days: 7);
    return currentRate * 100; 
  }

  // Returns a rank based on streak number
  String getConsistencyRank(int streak) {
    if (streak >= 30) return "Legendary";
    if (streak >= 14) return "Elite";
    if (streak >= 7) return "Consistent";
    return "Building";
  }

  // Thorough Data Analysis for the Modal
  Future<Map<String, dynamic>> getHabitDeepAnalysis(int habitId) async {
    final logs = await _db.getLogsForHabit(habitId);
    
    int longestStreak = 0;
    int currentTempStreak = 0;
    int missedDays = 0;
    int totalAccomplished = 0;

    // Process logs (Ordered by date DESC from DB)
    // We reverse it to process chronologically for streak calculation
    for (var log in logs.reversed) {
      if (log['isCompleted'] == 1) {
        currentTempStreak++;
        totalAccomplished++;
        if (currentTempStreak > longestStreak) longestStreak = currentTempStreak;
      } else {
        currentTempStreak = 0;
        missedDays++;
      }
    }

    double rate = logs.isEmpty ? 0 : (totalAccomplished / logs.length) * 100;

    return {
      'longestStreak': longestStreak,
      'missedDays': missedDays,
      'totalAccomplished': totalAccomplished,
      'completionRate': rate.toInt(),
      'totalDaysTracked': logs.length,
    };
  }

  // StreaksController.dart

// Add this method to calculate streak on the fly for the cards
int calculateStrictStreak(List<Map<String, dynamic>> logs) {
  if (logs.isEmpty) return 0;

  final String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
  final String yesterday = DateFormat('yyyy-MM-dd').format(DateTime.now().subtract(const Duration(days: 1)));
  
  // Filter for completions and sort newest first
  final completedLogs = logs.where((l) => l['isCompleted'] == 1).toList();
  if (completedLogs.isEmpty) return 0;

  String latestDate = completedLogs.first['date'];
  
  // Strict check: Must have done it today or yesterday to even start counting
  if (latestDate == today || latestDate == yesterday) {
    int streak = 0;
    DateTime checkDate = DateTime.parse(latestDate);
    
    for (var log in completedLogs) {
      if (log['date'] == DateFormat('yyyy-MM-dd').format(checkDate)) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break; // Gap found, stop counting
      }
    }
    return streak;
  }
  
  return 0; // Missed both today and yesterday
}
}