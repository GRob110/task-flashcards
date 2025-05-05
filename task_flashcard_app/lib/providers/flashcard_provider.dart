import 'package:flutter/foundation.dart';
import '../models/flashcard.dart';
import '../services/db_service.dart';

class FlashcardProvider extends ChangeNotifier {
  final DBService _dbService = DBService.instance;

  List<Flashcard> _flashcards = [];
  List<Flashcard> get flashcards => _flashcards;

  /// Map of cardId → rolling average rating
  final Map<int, double> _averageRating = {};

  /// Today's review order: worst (lowest avg) first
  List<Flashcard> get todaysFlashcards {
    final list = List<Flashcard>.from(_flashcards);
    list.sort((a, b) {
      final aAvg = _averageRating[a.id!] ?? 1.0;
      final bAvg = _averageRating[b.id!] ?? 1.0;
      return aAvg.compareTo(bAvg);
    });
    return list;
  }

  /// Load cards and compute averages (default 30-day window)
  Future<void> loadFlashcards({int windowDays = 30}) async {
    _flashcards = await _dbService.getFlashcards();
    await _loadAverageRatings(windowDays: windowDays);
    notifyListeners();
  }

  /// Compute the average rating for each card over the past [windowDays]
  Future<void> _loadAverageRatings({required int windowDays}) async {
    _averageRating.clear();
    final since = DateTime.now().subtract(Duration(days: windowDays));
    for (var card in _flashcards) {
      final performances = await _dbService.getPerformances(
        card.id!,
        since: since,
      );
      if (performances.isNotEmpty) {
        final sum = performances.fold<int>(0, (sum, p) => sum + p.rating);
        _averageRating[card.id!] = sum / performances.length;
      } else {
        // No history → neutral average
        _averageRating[card.id!] = 1.0;
      }
    }
  }

  /// Add a new flashcard
  Future<void> addFlashcard(String text) async {
    await _dbService.insertFlashcard(Flashcard(text: text));
    await loadFlashcards();
  }

  /// Update an existing flashcard
  Future<void> updateFlashcard(Flashcard card) async {
    await _dbService.updateFlashcard(card);
    await loadFlashcards();
  }

  /// Delete a flashcard
  Future<void> deleteFlashcard(int id) async {
    await _dbService.deleteFlashcard(id);
    await loadFlashcards();
  }

  /// Record performance and recompute averages
  Future<void> recordPerformance(int cardId, int rating) async {
    await _dbService.recordPerformance(cardId, DateTime.now(), rating);
    // recompute all averages; you could optimize to just one card if needed
    await _loadAverageRatings(windowDays: 30);
    notifyListeners();
  }

  /// Get heatmap data for a card over the past year
  Future<Map<DateTime, int>> getYearlyData(int cardId) async {
    final since = DateTime.now().subtract(const Duration(days: 365));
    final performances =
        await _dbService.getPerformances(cardId, since: since);
    return { for (var p in performances) p.date: p.rating };
  }
}
