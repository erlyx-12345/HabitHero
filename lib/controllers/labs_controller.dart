import '../services/database_helper.dart';
import '../models/habit_model.dart';
import 'package:intl/intl.dart';

class LabController {
  final dbHelper = DatabaseHelper.instance;

  // --- EXISTING LOGIC ---
  Future<List<Map<String, dynamic>>> getFilteredChartData(String timeframe) async {
    final db = await dbHelper.database;
    List<Map<String, dynamic>> chartData = [];
    for (int i = 6; i >= 0; i--) {
      DateTime date = DateTime.now().subtract(Duration(days: i));
      String formattedDate = DateFormat('yyyy-MM-dd').format(date);
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
      int total = result.isNotEmpty && result[0]['total'] != null ? result[0]['total'] as int : 0;
      int completed = result.isNotEmpty && result[0]['completed'] != null ? result[0]['completed'] as int : 0;
      chartData.add({'day': DateFormat('E').format(date).substring(0, 1), 'rate': total > 0 ? (completed / total) : 0.0});
    }
    return chartData;
  }

  Future<double> getCompletionRate() async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> result = await db.rawQuery('SELECT COUNT(*) as total, SUM(CASE WHEN isCompleted = 1 THEN 1 ELSE 0 END) as completed FROM daily_logs WHERE date >= date("now", "-30 days")');
    int total = result.isNotEmpty && result[0]['total'] != null ? result[0]['total'] as int : 0;
    int completed = result.isNotEmpty && result[0]['completed'] != null ? result[0]['completed'] as int : 0;
    return total > 0 ? (completed / total) : 0.0;
  }

  Future<List<Habit>> getEliteHabits() async {
    final db = await dbHelper.database;
    final maps = await db.query('habits', orderBy: 'streak DESC', limit: 3);
    return maps.map((h) => Habit.fromMap(h)).toList();
  }

  // --- NEW ANALYTICS LOGIC (FIXED) ---

  // 1. Habit Difficulty Index - FIXED: Added completedCount to the SELECT statement
  Future<List<Map<String, dynamic>>> getHabitDifficulty() async {
    final db = await dbHelper.database;
    // We now select the SUM of completions so the UI can display it
    return await db.rawQuery('''
      SELECT 
        h.title, 
        h.colorHex,
        SUM(CASE WHEN l.isCompleted = 1 THEN 1 ELSE 0 END) as completedCount,
        (CAST(SUM(CASE WHEN l.isCompleted = 1 THEN 1 ELSE 0 END) AS FLOAT) / COUNT(l.id)) * 100 as successRate
      FROM habits h 
      JOIN daily_logs l ON h.id = l.habitId
      GROUP BY h.id 
      ORDER BY successRate ASC 
      LIMIT 3
    ''');
  }

  // 4. Best Performing Time of Day
  Future<Map<String, double>> getTimeOfDayComparison() async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> res = await db.rawQuery('''
      SELECT h.timeOfDay, 
      AVG(CASE WHEN l.isCompleted = 1 THEN 1.0 ELSE 0.0 END) as rate
      FROM habits h JOIN daily_logs l ON h.id = l.habitId
      GROUP BY h.timeOfDay
    ''');
    return {for (var item in res) item['timeOfDay'].toString(): (item['rate'] as double? ?? 0.0)};
  }

  // 5. Momentum Score (Current 7 days vs Previous 7 days)
  Future<double> getMomentumScore() async {
    final db = await dbHelper.database;
    // Using CAST to REAL to ensure precise division in SQLite
    var currentRes = await db.rawQuery('SELECT AVG(CAST(isCompleted AS REAL)) as avg FROM daily_logs WHERE date >= date("now", "-7 days")');
    var prevRes = await db.rawQuery('SELECT AVG(CAST(isCompleted AS REAL)) as avg FROM daily_logs WHERE date < date("now", "-7 days") AND date >= date("now", "-14 days")');
    
    double current = (currentRes.first['avg'] as num? ?? 0.0).toDouble();
    double previous = (prevRes.first['avg'] as num? ?? 0.0).toDouble();
    return current - previous; 
  }

  // 3. Drop-off Detection (Habits failed for last 5 days)
  Future<List<String>> getDropOffs() async {
    final db = await dbHelper.database;
    final res = await db.rawQuery('''
      SELECT h.title FROM habits h JOIN daily_logs l ON h.id = l.habitId
      WHERE l.date >= date('now', '-5 days')
      GROUP BY h.id HAVING SUM(l.isCompleted) = 0
    ''');
    return res.map((e) => e['title'].toString()).toList();
  }
}