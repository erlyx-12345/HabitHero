import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_hero/main.dart';
import 'package:habit_hero/screens/welcome_screen.dart'; // Add this import

void main() {
  testWidgets('App starts on Welcome Screen smoke test', (WidgetTester tester) async {
    // 1. Pass a "startScreen" to the constructor as now required by your main.dart logic
    await tester.pumpWidget(const HabitHeroApp(
      startScreen: WelcomeScreen(),
    ));

    // 2. Look for text that actually exists in your Welcome Screen
    // Instead of looking for '0', let's look for 'Habit' or 'LET'S START'
    expect(find.textContaining('Habit'), findsOneWidget);
    expect(find.text("GET STARTED"), findsOneWidget);

    // 3. Verify that the counter '0' (which was from the default template) is gone
    expect(find.text('0'), findsNothing);
  });
}