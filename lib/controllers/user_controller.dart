import 'package:sqflite/sqflite.dart';
import '../services/database_helper.dart';

class UserController {
  Future<bool> saveHeroName(String name) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.insert(
        'users',
        {'name': name},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return true;
    } catch (e) {
      return false;
    }
  }
}