import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../services/database_helper.dart';

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

  static Future<Map<String, dynamic>?> fetchUserData() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final List<Map<String, dynamic>> userMaps = await db.query('users', limit: 1);

      if (userMaps.isNotEmpty) {
        return {
          'name': userMaps.first['name'],
          'profilePath': userMaps.first['profilePath'],
        };
      }
    } catch (e) {
      debugPrint("Error fetching user data: $e");
    }
    return null;
  }
}