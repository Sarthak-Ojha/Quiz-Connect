import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_app/main.dart';
import 'package:quiz_app/screens/splash_screen.dart';

void main() {
  testWidgets('App renders splash screen on startup', (WidgetTester tester) async {
    // Store the original error widget builder
    final originalErrorBuilder = ErrorWidget.builder;
    
    // Set up the widget
    await tester.pumpWidget(
      const MaterialApp(
        home: SplashScreen(),
      ),
    );
    
    // Verify splash screen is shown
    expect(find.byType(SplashScreen), findsOneWidget);
    
    // Fast-forward the timer and animations
    await tester.pumpAndSettle(const Duration(seconds: 3));
    
    // Clean up
    addTearDown(() {
      // Restore the original error widget builder
      ErrorWidget.builder = originalErrorBuilder;
    });
  });
}
