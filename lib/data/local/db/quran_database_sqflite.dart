// lib/data/local/db/quran_database_sqflite.dart
// backend لمنصة Android / iOS / Desktop — يستخدم sqflite

import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../../models/quran_word.dart';
import 'quran_database.dart';

class QuranCacheBackend {
  Database? _db;
  bool _initialized = false;

  static const String _dbName = 'quran_cache_v4.db';
  static const int _dbVersion = 4;

  Future<void> init() async {
    if (_initialized) return;
    final dir = await getApplicationDocumentsDirectory();
    final path = join(dir.path, _dbName);

    _db = await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
    _initialized = true;
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE words (
        id              INTEGER PRIMARY KEY AUTOINCREMENT,
        verse_key       TEXT NOT NULL,
        sura_number     INTEGER NOT NULL,
        aya_number      INTEGER NOT NULL,
        word_position   INTEGER NOT NULL,
        text_uthmani    TEXT NOT NULL,
        text_simple     TEXT NOT NULL,
        page_number     INTEGER NOT NULL,
        line_number     INTEGER NOT NULL DEFAULT 1,
        is_last_in_aya  INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute('CREATE INDEX idx_page ON words (page_number)');
    await db.execute('CREATE INDEX idx_sura ON words (sura_number)');
    await db.execute('''
      CREATE TABLE cache_meta (
        cache_key   TEXT PRIMARY KEY,
        cached_at   INTEGER NOT NULL
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldV, int newV) async {
    await db.execute('DROP TABLE IF EXISTS words');
    await db.execute('DROP TABLE IF EXISTS cache_meta');
    await _onCreate(db, newV);
  }

  // ─── Page ───────────────────────────────────────────
  Future<CachedPageData?> loadPage(int pageNumber) async {
    final meta = await _db!.query(
      'cache_meta',
      where: 'cache_key = ?',
      whereArgs: ['page_$pageNumber'],
    );
    if (meta.isEmpty) return null;
    final cachedAt = meta.first['cached_at'] as int;
    final rows = await _db!.query(
      'words',
      where: 'page_number = ?',
      whereArgs: [pageNumber],
      orderBy: 'sura_number, aya_number, word_position',
    );
    if (rows.isEmpty) return null;
    return CachedPageData(
      cachedAt: cachedAt,
      words: rows.map(QuranWord.fromMap).toList(),
    );
  }

  Future<void> savePage(int pageNumber, List<QuranWord> words) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await _db!.transaction((txn) async {
      await txn.delete(
        'words',
        where: 'page_number = ?',
        whereArgs: [pageNumber],
      );
      final batch = txn.batch();
      for (final w in words) {
        final map = w.toMap()..remove('id');
        batch.insert('words', map);
      }
      await batch.commit(noResult: true);
      await txn.insert(
        'cache_meta',
        {'cache_key': 'page_$pageNumber', 'cached_at': now},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
    if (kDebugMode) {
      debugPrint('💾 SQLite saved page $pageNumber (${words.length} words)');
    }
  }

  // ─── Sura ───────────────────────────────────────────
  Future<CachedPageData?> loadSura(int suraNumber) async {
    final meta = await _db!.query(
      'cache_meta',
      where: 'cache_key = ?',
      whereArgs: ['sura_$suraNumber'],
    );
    if (meta.isEmpty) return null;
    final cachedAt = meta.first['cached_at'] as int;
    final rows = await _db!.query(
      'words',
      where: 'sura_number = ?',
      whereArgs: [suraNumber],
      orderBy: 'aya_number, word_position',
    );
    if (rows.isEmpty) return null;
    return CachedPageData(
      cachedAt: cachedAt,
      words: rows.map(QuranWord.fromMap).toList(),
    );
  }

  Future<void> saveSura(int suraNumber, List<QuranWord> words) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await _db!.transaction((txn) async {
      await txn.delete(
        'words',
        where: 'sura_number = ?',
        whereArgs: [suraNumber],
      );
      final batch = txn.batch();
      for (final w in words) {
        final map = w.toMap()..remove('id');
        batch.insert('words', map);
      }
      await batch.commit(noResult: true);
      await txn.insert(
        'cache_meta',
        {'cache_key': 'sura_$suraNumber', 'cached_at': now},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }

  // ─── Search ──────────────────────────────────────────
  Future<List<QuranWord>> searchWords(String normalized, {int limit = 100}) async {
    final rows = await _db!.rawQuery(
      '''
      SELECT * FROM words
      WHERE text_uthmani LIKE ? OR text_simple LIKE ?
      ORDER BY sura_number, aya_number, word_position
      LIMIT ?
      ''',
      ['%$normalized%', '%$normalized%', limit],
    );
    return rows.map(QuranWord.fromMap).toList();
  }

  // ─── Utils ────────────────────────────────────────────
  bool hasAnyData() {
    // يُستدعى بشكل متزامن بعد init()
    return _db != null;
  }

  Future<void> clearAll() async {
    await _db!.delete('words');
    await _db!.delete('cache_meta');
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
    _initialized = false;
  }
}
