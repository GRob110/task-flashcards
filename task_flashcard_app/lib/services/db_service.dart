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
}
