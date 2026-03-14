import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';

import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

@pragma('vm:entry-point')
Future<void> alarmCallback(int id, Map<String, dynamic> params) async {
  WidgetsFlutterBinding.ensureInitialized();

  final FlutterLocalNotificationsPlugin notifications = FlutterLocalNotificationsPlugin();

  const AndroidInitializationSettings androidInit =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  await notifications.initialize(
    const InitializationSettings(android: androidInit),
  );

  final String title = params["title"] ?? "Habit";

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'habit_hero_alarm_channel',
    'Habit Alarms',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  await notifications
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await notifications.show(
    id,
    "HABIT HERO",
    "TIME TO: ${title.toUpperCase()}",
    NotificationDetails(
      android: AndroidNotificationDetails(
        channel.id,
        channel.name,
        importance: Importance.max,
        priority: Priority.max,
        category: AndroidNotificationCategory.alarm,
        fullScreenIntent: true,
        ongoing: true, 
        autoCancel: false,
        visibility: NotificationVisibility.public,
        audioAttributesUsage: AudioAttributesUsage.alarm,
        vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]),
      ),
    ),
  );
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();
    await AndroidAlarmManager.initialize();

    try {
      // FIXED: Using .toString() or .identifier correctly based on recent package logic
      final timezoneInfo = await FlutterTimezone.getLocalTimezone();
      // If .identifier fails, use .toString().split(' ').last or similar
      String timezoneName = timezoneInfo.toString();
      
      tz.setLocalLocation(tz.getLocation(timezoneName));
      debugPrint("HabitHero: Timezone set to -> $timezoneName");
    } catch (e) {
      debugPrint("HabitHero: Timezone fallback -> Asia/Manila");
      tz.setLocalLocation(tz.getLocation('Asia/Manila'));
    }
    
    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    await _notifications.initialize(
      const InitializationSettings(android: androidInit),
    );
  }

  Future<void> requestPermissions() async {
    if (Platform.isAndroid) {
      await Permission.notification.request();

      if (await Permission.ignoreBatteryOptimizations.isDenied) {
        await Permission.ignoreBatteryOptimizations.request();
      }

      if (await Permission.scheduleExactAlarm.isDenied) {
        await Permission.scheduleExactAlarm.request();
      }
    }
  }

  Future<bool> isReadyForAlarms() async {
    if (Platform.isAndroid) {
      final alarmStatus = await Permission.scheduleExactAlarm.status;
      final batteryStatus = await Permission.ignoreBatteryOptimizations.status;
      return alarmStatus.isGranted && batteryStatus.isGranted;
    }
    return true;
  }

  Future<void> scheduleHabitReminder(int id, String title, int hour, int minute) async {
    final now = DateTime.now();
    DateTime schedule = DateTime(now.year, now.month, now.day, hour, minute);

    if (schedule.isBefore(now)) {
      schedule = schedule.add(const Duration(days: 1));
    }

    // High-Precision: Using exact and wakeup for 0-delay
    await AndroidAlarmManager.oneShotAt(
      schedule,
      id,
      alarmCallback,
      allowWhileIdle: true, // Crucial for modern Android
      exact: true,          // Forces exact timing
      wakeup: true,         // Wakes CPU from sleep
      rescheduleOnReboot: true,
      params: {"title": title},
    );

    debugPrint("Armed: $title exactly at $schedule");
  }

  Future<void> scheduleDailyHabit(int id, String title, int hour, int minute) async {
    final now = DateTime.now();
    DateTime schedule = DateTime(now.year, now.month, now.day, hour, minute);

    if (schedule.isBefore(now)) {
      schedule = schedule.add(const Duration(days: 1));
    }

    await AndroidAlarmManager.periodic(
      const Duration(days: 1),
      id,
      alarmCallback,
      startAt: schedule,
      exact: true,
      wakeup: true,
      allowWhileIdle: true,
      rescheduleOnReboot: true,
      params: {"title": title},
    );
  }

  Future<void> instantFireTest() async {
    final testTime = DateTime.now().add(const Duration(seconds: 5));
    await AndroidAlarmManager.oneShotAt(
      testTime,
      9999,
      alarmCallback,
      allowWhileIdle: true,
      exact: true,
      wakeup: true,
      params: {"title": "Instant Test"},
    );
  }

  Future<void> cancelReminder(int id) async {
    await AndroidAlarmManager.cancel(id);
    await _notifications.cancel(id);
  }
}