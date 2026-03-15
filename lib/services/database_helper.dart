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
      version: 10, 
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future<int> deleteCustomFocusArea(String name) async {
    final db = await instance.database;
    return await db.delete(
      'custom_focus_areas',
      where: 'name = ?',
      whereArgs: [name],
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('CREATE TABLE users (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, profilePath TEXT)');

    await db.execute('''
      CREATE TABLE habits (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        focusArea TEXT NOT NULL,
        title TEXT NOT NULL,
        timeOfDay TEXT DEFAULT 'Anytime',
        endDate TEXT,
        startDate TEXT,
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

    await db.execute('''
      CREATE TABLE custom_focus_areas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        iconCode INTEGER,
        colorHex INTEGER
      )
    ''');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 6) {
      await db.execute('ALTER TABLE habits ADD COLUMN reminderTime TEXT');
    }
    
    if (oldVersion < 7) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS custom_focus_areas (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL UNIQUE,
          iconCode INTEGER,
          colorHex INTEGER
        )
      ''');
    }

    if (oldVersion < 8) {
      try {
        await db.execute('ALTER TABLE custom_focus_areas ADD COLUMN colorHex INTEGER');
      } catch (e) {
        print("Column colorHex already exists: $e");
      }
    }

    if (oldVersion < 9) {
      try {
        await db.execute('ALTER TABLE habits ADD COLUMN startDate TEXT');
      } catch (e) {
        print("Column startDate already exists: $e");
      }
    }

    if (oldVersion < 10) {
      try {
        await db.execute('ALTER TABLE users ADD COLUMN profilePath TEXT');
      } catch (e) {
        print("Column profilePath already exists: $e");
      }
    }
  }

  Future<int> updateUserProfile(String name, String? imagePath) async {
    final db = await database;
    return await db.update(
      'users',
      {'name': name, 'profilePath': imagePath},
      where: 'id = ?',
      whereArgs: [1],
    );
  }

  Future<int> insertCustomFocusArea(String name, int iconCode, int colorHex) async {
    final db = await database;
    return await db.insert('custom_focus_areas', {
      'name': name,
      'iconCode': iconCode,
      'colorHex': colorHex, 
    });
  }

  Future<List<Map<String, dynamic>>> getCustomFocusAreas() async {
    final db = await instance.database;
    return await db.query('custom_focus_areas');
  }

  Future<List<Map<String, dynamic>>> getAllHabits() async {
    final db = await instance.database;
    return await db.query('habits');
  }

  Future<double> getCompletionRate({int days = 7}) async {
    final db = await instance.database;
    final now = DateTime.now();
    final startDate = now.subtract(Duration(days: days));
    final dateString = DateFormat('yyyy-MM-dd').format(startDate);

    final completedResult = await db.rawQuery('''
      SELECT COUNT(*) as count FROM daily_logs 
      WHERE isCompleted = 1 AND date >= ?
    ''', [dateString]);

    int completedCount = Sqflite.firstIntValue(completedResult) ?? 0;
    final habitCountResult = await db.rawQuery('SELECT COUNT(*) FROM habits');
    int habitCount = Sqflite.firstIntValue(habitCountResult) ?? 0;

    if (habitCount == 0) return 0.0;
    double rate = completedCount / (habitCount * days);
    return rate.clamp(0.0, 1.0); 
  }

  Future<List<Map<String, dynamic>>> getLogsForHabit(int habitId) async {
    final db = await instance.database;
    return await db.query(
      'daily_logs',
      where: 'habitId = ?',
      whereArgs: [habitId],
      orderBy: 'date DESC',
    );
  }
}