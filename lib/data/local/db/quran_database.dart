// lib/data/local/db/quran_database.dart
// ─── استراتيجية Cache-First ───────────────────────────────────────────────
// 1. عند أول طلب لصفحة: جلب البيانات من Quran.Foundation API وتخزينها في SQLite
// 2. عند الطلبات اللاحقة: قراءة البيانات من SQLite مباشرة (لا إنترنت مطلوب)
// 3. TTL: 30 يوماً — بعدها يُعاد الجلب من الـ API تلقائياً
// ─────────────────────────────────────────────────────────────────────────

import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../../models/quran_word.dart';
import '../../remote/quran_api_service.dart';
import '../../../core/extensions/string_extensions.dart';

class QuranDatabase {
  // ─── Singleton ───────────────────────────────────────────
  static QuranDatabase? _instance;
  QuranDatabase._();
  static QuranDatabase get instance {
    _instance ??= QuranDatabase._();
    return _instance!;
  }

  // ─── ثوابت ───────────────────────────────────────────────
  static const String _dbName = 'quran_cache_v3.db';
  static const int _dbVersion = 3;
  static const int _cacheTtlDays = 30;
  static const int _totalPages = 604;
  static const int _totalSuras = 114;

  // ─── الحالة الداخلية ──────────────────────────────────────
  Database? _db;
  final QuranApiService _api = QuranApiService();

  // ═══════════════════════════════════════════════════════════
  // فتح / إنشاء قاعدة البيانات
  // ═══════════════════════════════════════════════════════════
  Future<Database> _getDb() async {
    if (_db != null) return _db!;
    final dir = await getApplicationDocumentsDirectory();
    final path = join(dir.path, _dbName);

    _db = await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
    return _db!;
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
    await db.execute(
      'CREATE INDEX idx_sura_aya ON words (sura_number, aya_number)',
    );
    await db.execute(
      'CREATE INDEX idx_page ON words (page_number)',
    );

    await db.execute('''
      CREATE TABLE cached_pages (
        page_number   INTEGER PRIMARY KEY,
        cached_at     INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE cached_suras (
        sura_number   INTEGER PRIMARY KEY,
        cached_at     INTEGER NOT NULL
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // إسقاط وإعادة إنشاء الجداول عند الترقية
    await db.execute('DROP TABLE IF EXISTS words');
    await db.execute('DROP TABLE IF EXISTS cached_pages');
    await db.execute('DROP TABLE IF EXISTS cached_suras');
    await _onCreate(db, newVersion);
  }

  // ═══════════════════════════════════════════════════════════
  // فحص صلاحية الـ Cache
  // ═══════════════════════════════════════════════════════════
  bool _isCacheExpired(int cachedAtMs) {
    final age = DateTime.now().millisecondsSinceEpoch - cachedAtMs;
    return age > (_cacheTtlDays * 24 * 3600 * 1000);
  }

  Future<bool> _isPageCached(Database db, int pageNumber) async {
    final rows = await db.query(
      'cached_pages',
      where: 'page_number = ?',
      whereArgs: [pageNumber],
    );
    if (rows.isEmpty) return false;
    final cachedAt = rows.first['cached_at'] as int;
    return !_isCacheExpired(cachedAt);
  }

  Future<bool> _isSuraCached(Database db, int suraNumber) async {
    final rows = await db.query(
      'cached_suras',
      where: 'sura_number = ?',
      whereArgs: [suraNumber],
    );
    if (rows.isEmpty) return false;
    final cachedAt = rows.first['cached_at'] as int;
    return !_isCacheExpired(cachedAt);
  }

  // ═══════════════════════════════════════════════════════════
  // تخزين كلمات في الـ Cache
  // ═══════════════════════════════════════════════════════════
  Future<void> _cachePageWords(
    Database db,
    int pageNumber,
    List<QuranWord> words,
  ) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    await db.transaction((txn) async {
      // حذف البيانات القديمة لهذه الصفحة
      await txn.delete(
        'words',
        where: 'page_number = ?',
        whereArgs: [pageNumber],
      );

      // إدراج الكلمات الجديدة
      final batch = txn.batch();
      for (final word in words) {
        batch.insert('words', word.toMap()..remove('id'));
      }
      await batch.commit(noResult: true);

      // تسجيل الصفحة في الـ cache
      await txn.insert(
        'cached_pages',
        {'page_number': pageNumber, 'cached_at': now},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });

    if (kDebugMode) {
      debugPrint(
        '💾 Cache saved: page $pageNumber (${words.length} words)',
      );
    }
  }

  Future<void> _cacheSuraWords(
    Database db,
    int suraNumber,
    List<QuranWord> words,
  ) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    await db.transaction((txn) async {
      await txn.delete(
        'words',
        where: 'sura_number = ?',
        whereArgs: [suraNumber],
      );
      final batch = txn.batch();
      for (final word in words) {
        batch.insert('words', word.toMap()..remove('id'));
      }
      await batch.commit(noResult: true);

      await txn.insert(
        'cached_suras',
        {'sura_number': suraNumber, 'cached_at': now},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });

    if (kDebugMode) {
      debugPrint(
        '💾 Cache saved: sura $suraNumber (${words.length} words)',
      );
    }
  }

  // ═══════════════════════════════════════════════════════════
  // getPageWords — cache-first ثم API
  // ═══════════════════════════════════════════════════════════
  Future<List<QuranWord>> getPageWords(int pageNumber) async {
    if (pageNumber < 1 || pageNumber > _totalPages) return [];

    final db = await _getDb();

    // ١. تحقق من الـ Cache
    if (await _isPageCached(db, pageNumber)) {
      final rows = await db.query(
        'words',
        where: 'page_number = ?',
        whereArgs: [pageNumber],
        orderBy: 'sura_number, aya_number, word_position',
      );
      if (rows.isNotEmpty) {
        if (kDebugMode) {
          debugPrint(
            '📦 Cache hit: page $pageNumber (${rows.length} words)',
          );
        }
        return rows.map(QuranWord.fromMap).toList();
      }
    }

    // ٢. جلب من API
    try {
      if (kDebugMode) debugPrint('🌐 API fetch: page $pageNumber');
      final words = await _api.fetchPageWords(pageNumber);
      if (words.isNotEmpty) {
        await _cachePageWords(db, pageNumber, words);
        return words;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ API error for page $pageNumber: $e');
    }

    // ٣. محاولة من الـ cache حتى لو انتهى TTL
    final fallback = await db.query(
      'words',
      where: 'page_number = ?',
      whereArgs: [pageNumber],
      orderBy: 'sura_number, aya_number, word_position',
    );
    return fallback.map(QuranWord.fromMap).toList();
  }

  // ═══════════════════════════════════════════════════════════
  // getSuraWords — cache-first ثم API
  // ═══════════════════════════════════════════════════════════
  Future<List<QuranWord>> getSuraWords(int suraNumber) async {
    if (suraNumber < 1 || suraNumber > _totalSuras) return [];

    final db = await _getDb();

    if (await _isSuraCached(db, suraNumber)) {
      final rows = await db.query(
        'words',
        where: 'sura_number = ?',
        whereArgs: [suraNumber],
        orderBy: 'aya_number, word_position',
      );
      if (rows.isNotEmpty) {
        if (kDebugMode) {
          debugPrint(
            '📦 Cache hit: sura $suraNumber (${rows.length} words)',
          );
        }
        return rows.map(QuranWord.fromMap).toList();
      }
    }

    try {
      if (kDebugMode) debugPrint('🌐 API fetch: sura $suraNumber');
      final words = await _api.fetchSuraWords(suraNumber);
      if (words.isNotEmpty) {
        await _cacheSuraWords(db, suraNumber, words);
        return words;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ API error for sura $suraNumber: $e');
    }

    final fallback = await db.query(
      'words',
      where: 'sura_number = ?',
      whereArgs: [suraNumber],
      orderBy: 'aya_number, word_position',
    );
    return fallback.map(QuranWord.fromMap).toList();
  }

  // ═══════════════════════════════════════════════════════════
  // getVerseWords
  // ═══════════════════════════════════════════════════════════
  Future<List<QuranWord>> getVerseWords(int suraNumber, int ayaNumber) async {
    final db = await _getDb();

    final rows = await db.query(
      'words',
      where: 'sura_number = ? AND aya_number = ?',
      whereArgs: [suraNumber, ayaNumber],
      orderBy: 'word_position',
    );

    if (rows.isNotEmpty) {
      return rows.map(QuranWord.fromMap).toList();
    }

    // جلب السورة كاملة إن لم تكن في الـ cache
    await getSuraWords(suraNumber);

    final retry = await db.query(
      'words',
      where: 'sura_number = ? AND aya_number = ?',
      whereArgs: [suraNumber, ayaNumber],
      orderBy: 'word_position',
    );
    return retry.map(QuranWord.fromMap).toList();
  }

  // ═══════════════════════════════════════════════════════════
  // searchText
  // ═══════════════════════════════════════════════════════════
  Future<List<QuranWord>> searchText(String query) async {
    if (query.trim().isEmpty) return [];

    final normalized = query.normalizeArabicFull();
    final db = await _getDb();

    final rows = await db.rawQuery(
      '''
      SELECT * FROM words
      WHERE text_uthmani LIKE ? OR text_simple LIKE ?
      ORDER BY sura_number, aya_number, word_position
      LIMIT 100
      ''',
      ['%$normalized%', '%$normalized%'],
    );

    return rows.map(QuranWord.fromMap).toList();
  }

  // ═══════════════════════════════════════════════════════════
  // إحصاءات ومساعدات
  // ═══════════════════════════════════════════════════════════
  int get totalSurahs => _totalSuras;
  int get totalPages => _totalPages;

  /// هل الصفحة موجودة في الـ cache؟
  Future<bool> isPageCached(int pageNumber) async {
    final db = await _getDb();
    return _isPageCached(db, pageNumber);
  }

  /// عدد الصفحات المخزّنة مؤقتاً
  Future<int> cachedPagesCount() async {
    final db = await _getDb();
    final result = await db.rawQuery(
      'SELECT COUNT(*) as cnt FROM cached_pages',
    );
    return (result.first['cnt'] as int?) ?? 0;
  }

  /// إلغاء الـ cache (لإعادة التحميل)
  Future<void> clearCache() async {
    final db = await _getDb();
    await db.delete('words');
    await db.delete('cached_pages');
    await db.delete('cached_suras');
    if (kDebugMode) debugPrint('🗑️ QuranDatabase cache cleared');
  }

  /// للتوافق مع الكود القديم
  Future<bool> isPopulated() async {
    final count = await cachedPagesCount();
    return count > 0;
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
