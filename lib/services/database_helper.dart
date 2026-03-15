import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:intl/intl.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('habithero.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    
    return await openDatabase(
      path,
      version: 6, // Bumped version
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('CREATE TABLE users (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL)');

    await db.execute('''
      CREATE TABLE habits (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        focusArea TEXT NOT NULL,
        title TEXT NOT NULL,
        timeOfDay TEXT DEFAULT 'Anytime',
        endDate TEXT,
        iconCode INTEGER,
        colorHex INTEGER,
        reminder INTEGER DEFAULT 0,
        reminderTime TEXT, 
        currentTier INTEGER DEFAULT 1,
        streak INTEGER DEFAULT 0,
        resistance INTEGER DEFAULT 50
      )
    ''');

    await db.execute('''
      CREATE TABLE daily_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        habitId INTEGER,
        date TEXT,
        isCompleted INTEGER,
        FOREIGN KEY (habitId) REFERENCES habits (id) ON DELETE CASCADE,
        UNIQUE(habitId, date)
      )
    ''');

    await db.execute('CREATE TABLE targets (id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT NOT NULL UNIQUE)');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 6) {
      // Add the reminderTime column if upgrading from older version
      await db.execute('ALTER TABLE habits ADD COLUMN reminderTime TEXT');
    }
  }


  // Add these inside your DatabaseHelper class

Future<List<Map<String, dynamic>>> getAllHabits() async {
  final db = await instance.database;
  return await db.query('habits');
}

// FIX: This defines getCompletionRate for your controller
Future<double> getCompletionRate({int days = 7}) async {
  final db = await instance.database;
  
  // Calculate the date range
  final now = DateTime.now();
  final startDate = now.subtract(Duration(days: days));
  final dateString = DateFormat('yyyy-MM-dd').format(startDate);

  // Count how many completions exist in the last X days
  final completedResult = await db.rawQuery('''
    SELECT COUNT(*) as count FROM daily_logs 
    WHERE isCompleted = 1 AND date >= ?
  ''', [dateString]);

  int completedCount = Sqflite.firstIntValue(completedResult) ?? 0;

  // Count total habits to find the potential maximum completions
  final habitCountResult = await db.rawQuery('SELECT COUNT(*) FROM habits');
  int habitCount = Sqflite.firstIntValue(habitCountResult) ?? 0;

  if (habitCount == 0) return 0.0;

  // Calculate percentage: (Actual completions) / (Total possible completions)
  double rate = completedCount / (habitCount * days);
  return rate.clamp(0.0, 1.0); 
}

// Add this inside your DatabaseHelper class
Future<List<Map<String, dynamic>>> getLogsForHabit(int habitId) async {
  final db = await instance.database;
  
  // We order by date DESC so the most recent logs are at the top,
  // matches the logic in your StreaksController
  return await db.query(
    'daily_logs',
    where: 'habitId = ?',
    whereArgs: [habitId],
    orderBy: 'date DESC',
  );
}
}