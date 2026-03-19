# 1. Protect your specific Data Models (UserProfile and Habit)
# This looks for the classes by name anywhere in your app's code
-keep class **.UserProfile { *; }
-keep class **.Habit { *; }
-keep class **.HabitTemplate { *; }
-keep class **.FocusArea { *; }

# 2. Protect the Map keys (Crucial for user.first['name'] to work)
-keepclassmembers class * {
    @Field *;
}

# 3. Protect Background Services (Alarms and Notifications)
-keep class dev.fluttercommunity.plus.androidalarmmanager.** { *; }
-keep class com.dexterous.flutterlocalnotifications.** { *; }

# 4. Protect SQFlite (The database engine)
-keep class com.tekartik.sqflite.** { *; }

# 5. Flutter Internals
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }