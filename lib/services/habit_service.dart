import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/habit_model.dart';
import 'database_helper.dart';

class HabitService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  IconData _getIcon(String iconName) {
    switch (iconName) {
      // Focus Areas
      case 'devices': return Icons.important_devices;
      case 'auto_awesome': return Icons.auto_awesome;
      case 'restaurant': return Icons.restaurant;
      case 'bolt': return Icons.bolt;
      case 'spa': return Icons.spa;
      case 'nightlight_round': return Icons.nightlight_round;
      case 'star': return Icons.star;
      case 'account_balance_wallet': return Icons.account_balance_wallet;
      case 'pets': return Icons.pets;

      // Habits
      case 'phonelink_off': return Icons.phonelink_off;
      case 'coffee': return Icons.coffee;
      case 'timer': return Icons.timer;
      case 'sentiment_very_satisfied': return Icons.sentiment_very_satisfied;
      case 'brush': return Icons.brush;
      case 'cleaning_services': return Icons.dry_cleaning; // More stable replacement
      case 'videocam': return Icons.videocam;
      case 'track_changes': return Icons.track_changes;
      case 'checklist': return Icons.checklist;
      case 'directions_walk': return Icons.directions_walk;
      case 'fitness_center': return Icons.fitness_center;
      case 'bedtime': return Icons.bedtime;
      case 'payments': return Icons.payments;
      case 'mop': return Icons.cleaning_services; // Fallback or use 'layers'
      case 'fmd_bad': return Icons.warning_amber_rounded;
      case 'coffee_maker': return Icons.local_cafe;
      case 'no_drinks': return Icons.no_drinks;
      case 'set_meal': return Icons.restaurant_menu;
      case 'egg_alt': return Icons.breakfast_dining;
      case 'water_drop': return Icons.water_drop;
      case 'eco': return Icons.eco;
      case 'medication': return Icons.medication;
      case 'directions_run': return Icons.directions_run;
      case 'pool': return Icons.pool;
      case 'accessibility_new': return Icons.accessibility_new;
      case 'self_improvement': return Icons.self_improvement;
      case 'airline_seat_recline_normal': return Icons.airline_seat_recline_normal;
      case 'smoke_free': return Icons.smoke_free;
      case 'hiking': return Icons.terrain;
      case 'air': return Icons.air;
      case 'menu_book': return Icons.menu_book;
      case 'edit_note': return Icons.note_alt;
      case 'forest': return Icons.park;
      case 'psychology': return Icons.psychology;
      case 'no_meals': return Icons.no_meals;
      case 'alarm_on': return Icons.alarm_on;
      case 'child_care': return Icons.child_care;
      case 'bathtub': return Icons.hot_tub;
      case 'volunteer_activism': return Icons.favorite;
      case 'restaurant_menu': return Icons.restaurant_menu;
      case 'forum': return Icons.forum;
      case 'money_off': return Icons.money_off;
      case 'shopping_cart': return Icons.shopping_cart;
      case 'receipt_long': return Icons.receipt_long;
      case 'savings': return Icons.savings;
      case 'house': return Icons.home;
      case 'soap': return Icons.clean_hands;
      
      default: return Icons.help_outline;
    }
  }

  Future<List<FocusArea>> getFocusAreas() async {
    final String response = await rootBundle.loadString('assets/habits.json');
    final data = json.decode(response);
    List<dynamic> areasJson = data['focus_areas'];

    List<FocusArea> allAreas = areasJson.map((area) => FocusArea(
      name: area['name'],
      icon: _getIcon(area['icon']),
      habits: (area['habits'] as List).map((h) => HabitTemplate(
        title: h['title'],
        duration: h['duration'],
        icon: _getIcon(h['icon']),
        timeOfDay: "Anytime", // Defaulted as per removal from JSON
      )).toList(),
    )).toList();

    final List<Map<String, dynamic>> customRes = await _dbHelper.getCustomFocusAreas();
    final db = await _dbHelper.database;

    for (var row in customRes) {
      final String areaName = row['name'];
      final List<Map<String, dynamic>> habitRows = await db.query(
        'habits',
        where: 'focusArea = ?',
        whereArgs: [areaName],
      );

      allAreas.add(FocusArea(
        name: areaName,
        icon: IconData(row['iconCode'], fontFamily: 'MaterialIcons'),
        habits: habitRows.map((h) => HabitTemplate(
          title: h['title'],
          duration: "Custom", 
          icon: IconData(h['iconCode'], fontFamily: 'MaterialIcons'),
          timeOfDay: h['timeOfDay'] ?? "Anytime",
        )).toList(),
      ));
    }

    return allAreas;
  }
}