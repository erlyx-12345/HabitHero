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
    final LabController labs = LabController();
    final List<Map<String, dynamic>> chartData = await labs.getFilteredChartData("Overall");

    if (chartData.isEmpty) return 1;

    double currentConsistency = chartData.last['rate']; 
    debugPrint("Current Consistency: ${(currentConsistency * 100).toStringAsFixed(0)}%");

    // UPDATED TIERS TO MATCH YOUR 7 LEVELS
    if (currentConsistency >= 0.95) return 7; // 95% - Gold/Purple/Black
    if (currentConsistency >= 0.85) return 6; // 85% - Red
    if (currentConsistency >= 0.70) return 5; // 70% - Purple
    if (currentConsistency >= 0.50) return 4; // 50% - Green
    if (currentConsistency >= 0.30) return 3; // 30% - Orange
    if (currentConsistency >= 0.20) return 2; // 20% - Blue
    
    return 1; // Default - Brown/Grey
  } catch (e) {
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