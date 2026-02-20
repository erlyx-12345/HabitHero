import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../models/habit.dart';
import '../models/daily_log.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  /// Get database instance
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('habithero.db');
    return _database!;
  }

  /// Initialize database
  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  /// Create tables
  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE habits (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT,
        category TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE daily_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        habit_id INTEGER NOT NULL,
        date TEXT NOT NULL,
        completed INTEGER NOT NULL,
        FOREIGN KEY (habit_id) REFERENCES habits (id)
      )
    ''');
  }

  // ================= HABIT CRUD =================

  Future<int> insertHabit(Habit habit) async {
    final db = await instance.database;
    return await db.insert('habits', habit.toMap());
  }

  Future<List<Habit>> getHabits() async {
    final db = await instance.database;
    final result = await db.query('habits', orderBy: 'created_at DESC');
    return result.map((json) => Habit.fromMap(json)).toList();
  }

  Future<int> updateHabit(Habit habit) async {
    final db = await instance.database;
    return await db.update(
      'habits',
      habit.toMap(),
      where: 'id = ?',
      whereArgs: [habit.id],
    );
  }

  Future<int> deleteHabit(int id) async {
    final db = await instance.database;
    return await db.delete('habits', where: 'id = ?', whereArgs: [id]);
  }

  // ================= DAILY LOG CRUD =================

  Future<int> insertDailyLog(DailyLog log) async {
    final db = await instance.database;
    return await db.insert('daily_logs', log.toMap());
  }

  Future<List<DailyLog>> getLogsForHabit(int habitId) async {
    final db = await instance.database;
    final result = await db.query(
      'daily_logs',
      where: 'habit_id = ?',
      whereArgs: [habitId],
      orderBy: 'date DESC',
    );
    return result.map((json) => DailyLog.fromMap(json)).toList();
  }

  Future<int> updateDailyLog(DailyLog log) async {
    final db = await instance.database;
    return await db.update(
      'daily_logs',
      log.toMap(),
      where: 'id = ?',
      whereArgs: [log.id],
    );
  }

  Future<int> deleteDailyLog(int id) async {
    final db = await instance.database;
    return await db.delete('daily_logs', where: 'id = ?', whereArgs: [id]);
  }

  // ================= EXTRA UTILITIES =================

  /// Delete all logs for a habit (useful when deleting habit)
  Future<void> deleteLogsForHabit(int habitId) async {
    final db = await instance.database;
    await db.delete('daily_logs', where: 'habit_id = ?', whereArgs: [habitId]);
  }

  /// Close database
  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
