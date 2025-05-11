import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/db_service.dart';
import 'providers/flashcard_provider.dart';
import 'screens/review_screen.dart';
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
    return ChangeNotifierProvider(
      create: (_) => FlashcardProvider()..loadFlashcards(),
      child: MaterialApp(
        title: 'Flash Task',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF4CAF50),
            brightness: Brightness.light,
            primary: const Color(0xFF4CAF50),
            secondary: const Color(0xFF81C784),
            tertiary: const Color(0xFFC8E6C9),
            background: const Color(0xFFF1F8E9),
          ),
          cardTheme: CardTheme(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            color: Colors.white,
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF4CAF50),
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            backgroundColor: Color(0xFF4CAF50),
            foregroundColor: Colors.white,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF4CAF50),
            ),
          ),
          scaffoldBackgroundColor: const Color(0xFFF1F8E9),
        ),
        home: const ReviewScreen(),
        routes: {
          '/heatmap': (_) => const HeatmapScreen(),
          '/all': (_) => const CardListScreen(),
        },
      ),
    );
  }
}
