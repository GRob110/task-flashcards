import 'package:flutter/foundation.dart';
import '../models/flashcard.dart';
import '../services/db_service.dart';

class FlashcardProvider extends ChangeNotifier {
  final DBService _db = DBService.instance;

  List<Flashcard> _flashcards = [];
  List<Flashcard> get flashcards => _flashcards;

  // rolling average rating per card
  final Map<int, double> _averageRating = {};
  // track which cards have been completed or skipped today
  final Set<int> _completedToday = {};
  Set<int> get completedToday => _completedToday;
  final Set<int> _skippedToday   = {};

  /// Call this on app start (or pull-to-refresh) to load everything.
  Future<void> loadFlashcards({int windowDays = 30}) async {
    _flashcards = await _db.getFlashcards();
    await _computeAverages(windowDays: windowDays);
    await _loadTodayCompleted();
    _skippedToday.clear();
    notifyListeners();
  }

  /// Compute each card's rolling average over the past [windowDays].
  Future<void> _computeAverages({required int windowDays}) async {
    _averageRating.clear();
    final since = DateTime.now().subtract(Duration(days: windowDays));
    for (var card in _flashcards) {
      final history = await _db.getPerformances(card.id!, since: since);
      if (history.isNotEmpty) {
        final sum = history.fold<int>(0, (s, p) => s + p.rating);
        _averageRating[card.id!] = sum / history.length;
      } else {
        _averageRating[card.id!] = 1.0; // neutral
      }
    }
  }

  /// Find which cards already have a rating _today_.
  Future<void> _loadTodayCompleted() async {
    _completedToday.clear();
    final startOfDay = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    for (var card in _flashcards) {
      final today = await _db.getPerformances(card.id!, since: startOfDay);
      if (today.isNotEmpty) _completedToday.add(card.id!);
    }
  }

  /// Cards left to review: neither completed nor skipped today, sorted by worst avg first.
  List<Flashcard> get todaysFlashcards {
    final remain = _flashcards.where((c) =>
      !_completedToday.contains(c.id) &&
      !_skippedToday.contains(c.id)
    ).toList();
    remain.sort((a, b) {
      return (_averageRating[a.id!] ?? 1.0)
        .compareTo(_averageRating[b.id!] ?? 1.0);
    });
    return remain;
  }

  /// Record a real rating (0,1,2), mark completed, recompute averages.
  Future<void> recordPerformance(int cardId, int rating) async {
    print('Recording performance: cardId=$cardId, rating=$rating');
    await _db.recordPerformance(cardId, DateTime.now(), rating);
    _completedToday.add(cardId);
    await _computeAverages(windowDays: 30);
    notifyListeners();
  }

  /// Skip a card (no DB write), so it won't reappear until you reload tomorrow.
  void skipCard(int cardId) {
    _skippedToday.add(cardId);
    notifyListeners();
  }

  /// Standard CRUD for flashcards.
  Future<void> addFlashcard(String text) async {
    await _db.insertFlashcard(Flashcard(text: text));
    await loadFlashcards();
  }
  Future<void> updateFlashcard(Flashcard card) async {
    await _db.updateFlashcard(card);
    await loadFlashcards();
  }
  Future<void> deleteFlashcard(int id) async {
    await _db.deleteFlashcard(id);
    await loadFlashcards();
  }

  /// Heatmap data: map of DateTime→rating for the past year.
  Future<Map<DateTime,int>> getYearlyData(int cardId) async {
    final since = DateTime.now().subtract(const Duration(days: 365));
    final list = await _db.getPerformances(cardId, since: since);
    final map = { for (var p in list) DateTime(p.date.year, p.date.month, p.date.day): p.rating };
    print('Heatmap for card $cardId: $map');
    return map;
  }

  /// Update today's performance for a card
  Future<void> updateTodayPerformance(int cardId, int newRating) async {
    await _db.updateTodayPerformance(cardId, newRating);
    await loadFlashcards();
    notifyListeners();
  }

  /// Delete today's performance for a card
  Future<void> deleteTodayPerformance(int cardId) async {
    await _db.deleteTodayPerformance(cardId);
    await loadFlashcards();
    notifyListeners();
  }

  /// Get today's performance for a card
  Future<int?> getTodayPerformanceRating(int cardId) async {
    final perf = await _db.getTodayPerformance(cardId);
    return perf?.rating;
  }
}
