import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

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
}