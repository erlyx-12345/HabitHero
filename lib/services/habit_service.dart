import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/habit_model.dart';

class HabitService {
  // Map JSON strings to Flutter Icons
  IconData _getIcon(String iconName) {
    switch (iconName) {
      case 'self_improvement': return Icons.self_improvement;
      case 'spa': return Icons.spa;
      case 'edit': return Icons.edit;
      case 'air': return Icons.air;
      case 'bolt': return Icons.bolt;
      case 'psychology': return Icons.psychology;
      case 'event_note': return Icons.event_note;
      case 'email': return Icons.email;
      case 'favorite': return Icons.favorite;
      case 'water_drop': return Icons.water_drop;
      case 'fitness_center': return Icons.fitness_center;
      case 'directions_walk': return Icons.directions_walk;
      default: return Icons.help_outline;
    }
  }

  Future<List<FocusArea>> getFocusAreas() async {
    final String response = await rootBundle.loadString('assets/habits.json');
    final data = json.decode(response);
    List<dynamic> areasJson = data['focus_areas'];

    return areasJson.map((area) => FocusArea(
      name: area['name'],
      icon: _getIcon(area['icon']),
      habits: (area['habits'] as List).map((h) => HabitTemplate(
        title: h['title'],
        duration: h['duration'],
        icon: _getIcon(h['icon']),
        timeOfDay: h['timeOfDay'],
      )).toList(),
    )).toList();
  }
}