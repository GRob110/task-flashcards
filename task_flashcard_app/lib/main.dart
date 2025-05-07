import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/db_service.dart';
import 'providers/flashcard_provider.dart';
import 'screens/review_screen.dart';
import 'screens/manage_screen.dart';
import 'screens/heatmap_screen.dart';
import 'screens/card_list_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize the database
  await DBService.instance.db;

  // Create provider and load with a 30-day rolling window
  final flashcardProvider = FlashcardProvider();
  await flashcardProvider.loadFlashcards(windowDays: 30);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<FlashcardProvider>.value(
          value: flashcardProvider,
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flashcards',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const ReviewScreen(),
      routes: {
        '/manage': (_) => const ManageScreen(),
        '/heatmap': (_) => const HeatmapScreen(),
        '/all': (_) => const CardListScreen(),
      },
    );
  }
}
