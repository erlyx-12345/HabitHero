import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../services/database_helper.dart';
import '../controllers/labs_controller.dart';


class ProfileController {
  final ImagePicker _picker = ImagePicker();

  Future<File?> pickProfileImage(String currentName) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
      );

      if (image != null) {
        await DatabaseHelper.instance.updateUserProfile(currentName, image.path);
        return File(image.path);
      }
      return null;
    } catch (e) {
      debugPrint("Error picking image: $e");
      return null;
    }
  }

 static Future<int> getAchievementLevel() async {
  try {
    final db = DatabaseHelper.instance;

    // Helper to check if consistency was met EVERY day for 'X' days
    Future<bool> maintained(double threshold, int days) async {
      for (int i = 0; i < days; i++) {
        // Assuming getCompletionRate returns the rate for a specific day offset
        // or you can modify your SQL to check the min() over a range
        double dailyRate = await db.getCompletionRate(days: i + 1); 
        if (dailyRate < threshold) return false;
      }
      return true;
    }

    // Check from hardest to easiest
    // 98% for 2 weeks (14 days)
    if (await maintained(0.98, 14)) return 7;
    
    // 85% for 2 weeks (14 days)
    if (await maintained(0.85, 14)) return 6;
    
    // 70% for 1.5 weeks (10 days)
    if (await maintained(0.70, 10)) return 5;
    
    // 50% for 1 week (7 days)
    if (await maintained(0.50, 7)) return 4;
    
    // 30% for 5 days
    if (await maintained(0.30, 5)) return 3;
    
    // 20% for 3 days
    if (await maintained(0.20, 3)) return 2;

    return 1; // Default
  } catch (e) {
    debugPrint("Achievement Error: $e");
    return 1;
  }
}

  // Inside ProfileController
static Future<void> updateSelectedBorder(int level) async {
  final db = await DatabaseHelper.instance.database;
  await db.update(
    'users',
    {'selectedLevel': level},
    where: 'rowid = (SELECT MIN(rowid) FROM users)',
  );
}

static Future<Map<String, dynamic>?> fetchUserData() async {
  try {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> userMaps = await db.query('users', limit: 1);
    int calculatedMaxLevel = await getAchievementLevel();

    if (userMaps.isNotEmpty) {
      return {
        'name': userMaps.first['name'],
        'profilePath': userMaps.first['profilePath'],
        'maxLevel': calculatedMaxLevel, 
        'selectedLevel': userMaps.first['selectedLevel'] ?? 1, // Get saved choice
      };
    }
  } catch (e) { /*...*/ }
  return null;
}
  Future<bool> updateUserName(String newName) async {
  try {
    if (newName.trim().isEmpty) return false;
    
    final db = await DatabaseHelper.instance.database;
    // We update the first user found in the table
    await db.update(
      'users',
      {'name': newName.trim()},
      where: 'rowid = (SELECT MIN(rowid) FROM users)', 
    );
    return true;
  } catch (e) {
    debugPrint("Error updating name: $e");
    return false;
  }
}

static Future<void> totalSystemWipe() async {
  try {
    await DatabaseHelper.instance.deleteFullDatabase();
  } catch (e) {
    debugPrint("Error during total wipe: $e");
  }
}

// Inside ProfileController
static Future<void> updateMaxLevel(int level) async {
  final db = await DatabaseHelper.instance.database;
  await db.update(
    'users',
    {'maxLevel': level},
    where: 'id = ?',
    whereArgs: [1],
  );
}

}