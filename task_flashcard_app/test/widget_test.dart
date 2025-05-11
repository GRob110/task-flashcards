// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flash_task/main.dart';
import 'package:flash_task/providers/flashcard_provider.dart';
import 'package:flash_task/services/db_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // Initialize test database
    await DBService.instance.db;
  });

  testWidgets('App should render main screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => FlashcardProvider()),
        ],
        child: const MyApp(),
      ),
    );

    // Wait for the app to load
    await tester.pumpAndSettle();

    // Verify that the app title is displayed
    expect(find.text('Flash Task'), findsOneWidget);

    // Verify that the main navigation buttons are present
    expect(find.byIcon(Icons.list), findsOneWidget); // Card list icon
    expect(find.byIcon(Icons.calendar_today), findsOneWidget); // Heatmap icon
    expect(find.byIcon(Icons.refresh), findsOneWidget); // Review icon
  });
}
