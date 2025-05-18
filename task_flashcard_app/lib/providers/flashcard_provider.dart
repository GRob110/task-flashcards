import '../models/flashcard.dart';
import '../services/db_service.dart';
import 'package:flutter/material.dart';

class FlashcardProvider extends ChangeNotifier {
  final DBService _db = DBService.instance;

  List<Flashcard> _flashcards = [];
  List<Flashcard> get flashcards => _flashcards;

  // rolling average rating per card
  final Map<int, double> _averageRating = {};
  final Map<int, double> _emaRating = {};
  // track which cards have been completed today
  final Set<int> _completedToday = {};
  Set<int> get completedToday => _completedToday;
  
  // Current order of cards for review
  List<Flashcard> _currentOrder = [];
  // Track the last day we reset the order
  DateTime? _lastResetDay;

  /// Call this on app start (or pull-to-refresh) to load everything.
  Future<void> loadFlashcards({int windowDays = 30}) async {
    _flashcards = await _db.getFlashcards();
    await _computeAverages(windowDays: windowDays);
    await _loadTodayCompleted();
    _resetCardOrder();
    notifyListeners();
  }

  /// Compute each card's rolling average and EMA over the past [windowDays].
  Future<void> _computeAverages({required int windowDays}) async {
    _averageRating.clear();
    _emaRating.clear();
    final since = DateTime.now().subtract(Duration(days: windowDays));
    const double alpha = 0.5; // Smoothing factor for EMA (0.5 = recent counts more)
    
    // Get today's date at midnight for comparison
    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    
    for (var card in _flashcards) {
      final history = await _db.getPerformances(card.id!, since: since);
      
      // Split history into today and before today
      final todayPerformance = history.where((p) => 
        DateTime(p.date.year, p.date.month, p.date.day).isAtSameMomentAs(today)
      ).toList();
      
      final historyExcludingToday = history.where((p) => 
        DateTime(p.date.year, p.date.month, p.date.day).isBefore(today)
      ).toList();
      
      // Calculate EMA based on historical data first
      double? ema;
      if (historyExcludingToday.isNotEmpty) {
        final validHistory = historyExcludingToday.where((p) => p.rating >= 0);
        if (validHistory.isNotEmpty) {
          // Simple average (excluding passes)
          final sum = validHistory.fold<int>(0, (s, p) => s + p.rating);
          _averageRating[card.id!] = sum / validHistory.length;
          
          // EMA (sorted by date, with decay for missing days)
          final sortedHistory = [...validHistory]..sort((a, b) => a.date.compareTo(b.date));
          DateTime? prevDate;
          for (var p in sortedHistory) {
            if (ema == null) {
              ema = p.rating.toDouble();
            } else {
              // Insert virtual fails for each missing day
              final daysGap = p.date.difference(prevDate!).inDays;
              for (int i = 1; i < daysGap; i++) {
                ema = alpha * 0 + (1 - alpha) * (ema ?? 0.0); // Decay for missing day
              }
              ema = alpha * p.rating + (1 - alpha) * (ema ?? 0.0);
            }
            prevDate = DateTime(p.date.year, p.date.month, p.date.day);
          }
          // Decay until today
          if (prevDate != null) {
            final daysSince = today.difference(prevDate).inDays;
            for (int i = 1; i <= daysSince; i++) {
              ema = alpha * 0 + (1 - alpha) * (ema ?? 0.0);
            }
          }
        } else {
          _averageRating[card.id!] = 0.0;
          ema = 0.0;
        }
      } else {
        // No history - start with failing EMA
        _averageRating[card.id!] = 0.0;
        ema = 0.0;
      }
      
      // If there's a performance today, apply it to the EMA
      if (todayPerformance.isNotEmpty) {
        final todayRating = todayPerformance.first.rating;
        if (todayRating >= 0) { // Only apply if it's not a pass (-1)
          ema = alpha * todayRating + (1 - alpha) * (ema ?? 0.0);
        }
      }
      
      _emaRating[card.id!] = ema ?? 0.0;
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

  /// Reset the card order based on EMA
  void _resetCardOrder() {
    // Get all uncompleted cards
    final uncompleted = _flashcards.where((c) => !_completedToday.contains(c.id)).toList();
    // Sort by EMA
    uncompleted.sort((a, b) => getAdjustedEmaForCard(a.id!).compareTo(getAdjustedEmaForCard(b.id!)));
    _currentOrder = uncompleted;
    _lastResetDay = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
  }

  /// Check if we need to reset the order for a new day
  void _checkAndResetForNewDay() {
    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    if (_lastResetDay == null || !_lastResetDay!.isAtSameMomentAs(today)) {
      _resetCardOrder();
    }
  }

  /// Cards left to review in their current order
  List<Flashcard> get todaysFlashcards {
    _checkAndResetForNewDay();
    return _currentOrder;
  }

  /// Skip a card (move to end of current list)
  void skipCard(int cardId) {
    final card = _currentOrder.firstWhere((c) => c.id == cardId);
    _currentOrder.remove(card);
    _currentOrder.add(card);
    notifyListeners();
  }

  /// Record a real rating (0,1,2), mark completed, recompute averages.
  Future<void> recordPerformance(int cardId, int rating) async {
    await _db.recordPerformance(cardId, DateTime.now(), rating);
    _completedToday.add(cardId);
    // Remove the card from current order
    _currentOrder.removeWhere((c) => c.id == cardId);
    await _computeAverages(windowDays: 30);
    notifyListeners();
  }

  /// Pass a card (special rating that doesn't affect EMA)
  Future<void> passCard(int cardId) async {
    await _db.recordPerformance(cardId, DateTime.now(), -1); // Use -1 for pass
    _completedToday.add(cardId);
    // Remove the card from current order
    _currentOrder.removeWhere((c) => c.id == cardId);
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
    return { for (var p in list) DateTime(p.date.year, p.date.month, p.date.day): p.rating };
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
    _completedToday.remove(cardId);
    // Add the card back to the end of the current order
    final card = _flashcards.firstWhere((c) => c.id == cardId);
    if (!_currentOrder.contains(card)) {
      _currentOrder.add(card);
    }
    await loadFlashcards();
    notifyListeners();
  }

  /// Get today's performance for a card
  Future<int?> getTodayPerformanceRating(int cardId) async {
    final perf = await _db.getTodayPerformance(cardId);
    return perf?.rating;
  }

  /// Get EMA for a card
  double getEmaForCard(int cardId) => _emaRating[cardId] ?? 1.0;

  /// Get a gradient color from red (0) to yellow (1) to green (2) based on EMA
  /// Passes (-1) are shown in blue
  /// Returns a tuple of (backgroundColor, textColor)
  (Color, Color) getCardColor(double ema) {
    if (ema == -1) {
      return (Colors.blue, Colors.white);
    }
    if (ema <= 1.0) {
      // Red to yellow
      final bgColor = Color.lerp(Colors.red, Colors.yellow, ema)!;
      // Use black text for yellow backgrounds, white for red
      final textColor = ema > 0.5 ? Colors.black : Colors.white;
      return (bgColor, textColor);
    } else {
      // Yellow to green
      final bgColor = Color.lerp(Colors.yellow, Colors.green, ema - 1)!;
      // Use black text for yellow backgrounds, white for green
      final textColor = ema < 1.5 ? Colors.black : Colors.white;
      return (bgColor, textColor);
    }
  }

  // Helper to get adjusted EMA (reduce slightly if no history)
  double getAdjustedEmaForCard(int cardId) {
    final ema = getEmaForCard(cardId);
    // If the card has no history, _emaRating[cardId] will be exactly 1.0 (our default)
    // Reduce slightly for unrecorded cards
    if ((_emaRating[cardId] ?? 1.0) == 1.0) {
      return (ema - 0.1).clamp(0.0, 2.0);
    }
    return ema;
  }

  // Sort all flashcards by adjusted EMA (lowest first)
  List<Flashcard> get sortedFlashcards {
    final sorted = [..._flashcards];
    sorted.sort((a, b) => getAdjustedEmaForCard(a.id!).compareTo(getAdjustedEmaForCard(b.id!)));
    return sorted;
  }
}
