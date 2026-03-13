import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_hero/main.dart';
import 'package:habit_hero/screens/welcome_screen.dart'; // Add this import

void main() {
  testWidgets('App starts on Welcome Screen smoke test', (
    WidgetTester tester,
  ) async {
    // 1. Pass a "startScreen" to the constructor as now required by your main.dart logic
    await tester.pumpWidget(const HabitHeroApp(startScreen: WelcomeScreen()));

    // 2. Verify WelcomeScreen renders button
    expect(find.text("Get Started"), findsOneWidget);

    // 3. Verify no counter from template
    expect(find.text('0'), findsNothing);
  });
}
