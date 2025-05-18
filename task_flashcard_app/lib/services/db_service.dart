import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/flashcard.dart';
import '../models/performance.dart';

class DBService {
  // Singleton boilerplate
  DBService._();
  static final DBService instance = DBService._();

  Database? _db;
  Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    final path = join(await getDatabasesPath(), 'flashcards.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE flashcards(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            text TEXT NOT NULL
          );
        ''');
        await db.execute('''
          CREATE TABLE performance(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            cardId INTEGER NOT NULL,
            date TEXT NOT NULL,
            rating INTEGER NOT NULL
          );
        ''');
      },
    );
  }

  // Flashcard CRUD
  Future<int> insertFlashcard(Flashcard card) async {
    final database = await db;
    return await database.insert('flashcards', card.toMap());
  }

  Future<List<Flashcard>> getFlashcards() async {
    final database = await db;
    final maps = await database.query('flashcards');
    return maps.map((m) => Flashcard.fromMap(m)).toList();
  }

  Future<int> updateFlashcard(Flashcard card) async {
    final database = await db;
    return await database.update(
      'flashcards',
      card.toMap(),
      where: 'id = ?',
      whereArgs: [card.id],
    );
  }

  Future<int> deleteFlashcard(int id) async {
    final database = await db;
    return await database.delete('flashcards', where: 'id = ?', whereArgs: [id]);
  }

  // Performance logging
  Future<int> recordPerformance(int cardId, DateTime date, int rating) async {
    final database = await db;
    return await database.insert(
      'performance',
      {'cardId': cardId, 'date': date.toIso8601String(), 'rating': rating},
    );
  }

  Future<List<Performance>> getPerformances(int cardId, {DateTime? since}) async {
    final database = await db;
    final whereClauses = <String>['cardId = ?'];
    final args = <Object?>[cardId];
    if (since != null) {
      whereClauses.add('date >= ?');
      args.add(since.toIso8601String());
    }
    final maps = await database.query(
      'performance',
      where: whereClauses.join(' AND '),
      whereArgs: args,
    );
    return maps.map((m) => Performance.fromMap(m)).toList();
  }

  // NEW: Update today's performance for a card
  Future<void> updateTodayPerformance(int cardId, int newRating) async {
    final database = await db;
    final startOfDay = DateTime.now();
    final today = DateTime(startOfDay.year, startOfDay.month, startOfDay.day);
    // Find today's performance
    final maps = await database.query(
      'performance',
      where: 'cardId = ? AND date >= ?',
      whereArgs: [cardId, today.toIso8601String()],
      orderBy: 'date DESC',
      limit: 1,
    );
    if (maps.isNotEmpty) {
      final id = maps.first['id'] as int;
      await database.update(
        'performance',
        {'rating': newRating},
        where: 'id = ?',
        whereArgs: [id],
      );
    } else {
      // If no performance exists for today, create a new one
      await database.insert(
        'performance',
        {'cardId': cardId, 'date': today.toIso8601String(), 'rating': newRating},
      );
    }
  }

  // NEW: Delete today's performance for a card
  Future<void> deleteTodayPerformance(int cardId) async {
    final database = await db;
    final startOfDay = DateTime.now();
    final today = DateTime(startOfDay.year, startOfDay.month, startOfDay.day);
    // Find today's performance
    final maps = await database.query(
      'performance',
      where: 'cardId = ? AND date >= ?',
      whereArgs: [cardId, today.toIso8601String()],
      orderBy: 'date DESC',
      limit: 1,
    );
    if (maps.isNotEmpty) {
      final id = maps.first['id'] as int;
      await database.delete(
        'performance',
        where: 'id = ?',
        whereArgs: [id],
      );
    }
  }

  // Fetch today's performance for a card
  Future<Performance?> getTodayPerformance(int cardId) async {
    final database = await db;
    final startOfDay = DateTime.now();
    final today = DateTime(startOfDay.year, startOfDay.month, startOfDay.day);
    final maps = await database.query(
      'performance',
      where: 'cardId = ? AND date >= ?',
      whereArgs: [cardId, today.toIso8601String()],
      orderBy: 'date DESC',
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return Performance.fromMap(maps.first);
    }
    return null;
  }
}
