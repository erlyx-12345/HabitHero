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

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const intType = 'INTEGER NOT NULL';

    await db.execute('''
    CREATE TABLE habits (
      id $idType,
      title $textType,
      description $textType,
      frequency $textType,
      createdAt $textType
    )
    ''');

    await db.execute('''
    CREATE TABLE daily_logs (
      id $idType,
      habitId $intType,
      date $textType,
      isCompleted $intType,
      FOREIGN KEY (habitId) REFERENCES habits (id) ON DELETE CASCADE
    )
    ''');
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}