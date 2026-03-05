import 'package:flutter/material.dart';

/// The core Habit model used for Database and Analytics
class Habit {
  final int? id;
  final String title;
  final String focusArea;
  final String timeOfDay;
  final int iconCode;
  final int colorHex;
  final int streak;
  final int currentTier;
  final int resistance;
  final String? endDate;

  Habit({
    this.id,
    required this.title,
    required this.focusArea,
    this.timeOfDay = 'Anytime',
    required this.iconCode,
    required this.colorHex,
    this.streak = 0,
    this.currentTier = 1,
    this.resistance = 50,
    this.endDate,
  });

  // Convert Database Map to Habit Object
  factory Habit.fromMap(Map<String, dynamic> map) {
    return Habit(
      id: map['id'],
      title: map['title'],
      focusArea: map['focusArea'],
      timeOfDay: map['timeOfDay'],
      iconCode: map['iconCode'],
      colorHex: map['colorHex'],
      streak: map['streak'],
      currentTier: map['currentTier'],
      resistance: map['resistance'],
      endDate: map['endDate'],
    );
  }

  // Convert Habit Object to Database Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'focusArea': focusArea,
      'timeOfDay': timeOfDay,
      'iconCode': iconCode,
      'colorHex': colorHex,
      'streak': streak,
      'currentTier': currentTier,
      'resistance': resistance,
      'endDate': endDate,
    };
  }
}

/// Used for the "Selection" and "Template" UI
class HabitTemplate {
  final String title;
  final String duration; // e.g., "10 mins"
  final IconData icon;
  final String timeOfDay;
  final Color color;

  HabitTemplate({
    required this.title,
    required this.duration,
    required this.icon,
    required this.timeOfDay,
    this.color = const Color(0xFF10B981),
  });
}

class FocusArea {
  final String name;
  final IconData icon;
  final List<HabitTemplate> habits;

  FocusArea({
    required this.name, 
    required this.icon, 
    required this.habits,
  });
}