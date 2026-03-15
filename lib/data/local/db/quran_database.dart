// lib/data/local/db/quran_database.dart
// قاعدة بيانات المصحف المحلية - تستخدم مكتبة quran الكاملة (114 سورة، 6236 آية)

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:quran/quran.dart' as quran;
import '../../models/quran_word.dart';
import '../../../core/constants/quran_constants.dart';
import '../../../core/extensions/string_extensions.dart';

class QuranDatabase {
  static QuranDatabase? _instance;
  static Database? _db;

  // نسخة قاعدة البيانات — نرفعها عند تغيير المخطط
  static const int _kDbVersion = 2;

  QuranDatabase._();

  static QuranDatabase get instance {
    _instance ??= QuranDatabase._();
    return _instance!;
  }

  Future<Database> get database async {
    _db ??= await _initDatabase();
    return _db!;
  }

  // ═══════════════ تهيئة قاعدة البيانات ═══════════════

  Future<Database> _initDatabase() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final dbPath = join(docsDir.path, QuranConstants.quranDbName);

    return openDatabase(
      dbPath,
      version: _kDbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await _createSchema(db);
    await _populateAllQuran(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // المخطط القديم — أعد الإنشاء من الصفر
      await db.execute('DROP TABLE IF EXISTS words');
      await _createSchema(db);
      await _populateAllQuran(db);
    }
  }

  Future<void> _createSchema(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS words (
        id              INTEGER PRIMARY KEY AUTOINCREMENT,
        verse_key       TEXT    NOT NULL,
        sura_number     INTEGER NOT NULL,
        aya_number      INTEGER NOT NULL,
        word_position   INTEGER NOT NULL,
        text_uthmani    TEXT    NOT NULL,
        text_simple     TEXT    NOT NULL,
        page_number     INTEGER NOT NULL,
        line_number     INTEGER NOT NULL DEFAULT 1,
        is_last_in_aya  INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_sura_aya ON words(sura_number, aya_number)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_page ON words(page_number)',
    );
  }

  // ═══════════════ تعبئة القرآن الكامل (114 سورة) ═══════════════

  Future<void> _populateAllQuran(Database db) async {
    if (kDebugMode) debugPrint('📖 بدء تعبئة القرآن الكامل...');

    final batch = db.batch();
    int globalWordId = 1;

    for (int sura = 1; sura <= quran.totalSurahCount; sura++) {
      final verseCount = quran.getVerseCount(sura);
      final pageOfSura = quran.getSurahPages(sura).first; // الصفحة الأولى للسورة

      for (int aya = 1; aya <= verseCount; aya++) {
        // نص الآية كاملاً من المكتبة (عربي بالتشكيل الكامل)
        final verseText = quran.getVerse(sura, aya, verseEndSymbol: false);
        final words = verseText.trim().split(RegExp(r'\s+'));

        // حساب رقم الصفحة بشكل أكثر دقة
        final pageNumber = _getPageForVerse(sura, aya, pageOfSura);

        for (int w = 0; w < words.length; w++) {
          final word = words[w];
          if (word.isEmpty) continue;

          final isLast = w == words.length - 1 ? 1 : 0;
          final verseKey = '$sura:$aya';

          batch.insert('words', {
            'verse_key': verseKey,
            'sura_number': sura,
            'aya_number': aya,
            'word_position': w,
            'text_uthmani': word,
            'text_simple': _stripDiacritics(word),
            'page_number': pageNumber,
            'line_number': 1,
            'is_last_in_aya': isLast,
          });

          globalWordId++;
        }
      }

      // نفّذ على دفعات لتجنب تجاوز الذاكرة
      if (sura % 10 == 0) {
        await batch.commit(noResult: true);
        if (kDebugMode) debugPrint('  ✓ أُدخلت السور 1..$sura');
      }
    }

    // الدفعة الأخيرة
    await batch.commit(noResult: true);
    if (kDebugMode) {
      debugPrint('✅ اكتملت تعبئة القرآن الكامل: $globalWordId كلمة');
    }
  }

  /// احسب رقم الصفحة لآية بعينها باستخدام بيانات getPageData
  int _getPageForVerse(int sura, int aya, int defaultPage) {
    try {
      // نستخدم بيانات الصفحات من المكتبة
      for (int page = defaultPage; page <= quran.totalPagesCount; page++) {
        final pageData = quran.getPageData(page);
        for (final entry in pageData) {
          if (entry['surah'] == sura) {
            final start = entry['start'] as int;
            final end = entry['end'] as int;
            if (aya >= start && aya <= end) return page;
          }
        }
        // إذا تجاوزنا السورة في هذه الصفحة توقف
        bool surahFoundAhead = false;
        for (final entry in pageData) {
          if ((entry['surah'] as int) > sura) { surahFoundAhead = true; break; }
        }
        if (surahFoundAhead) break;
      }
    } catch (_) {}
    return defaultPage;
  }

  /// إزالة التشكيل لإنتاج النص البسيط
  String _stripDiacritics(String text) {
    // أحرف التشكيل unicode range
    return text.replaceAll(
      RegExp(
        r'[\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06DC\u06DF-\u06E4\u06E7-\u06E8\u06EA-\u06ED]',
      ),
      '',
    );
  }

  // ═══════════════ طرق الاستعلام ═══════════════

  /// كلمات صفحة معينة (من DB)
  Future<List<QuranWord>> getPageWords(int pageNumber) async {
    final db = await database;
    final maps = await db.query(
      'words',
      where: 'page_number = ?',
      whereArgs: [pageNumber],
      orderBy: 'sura_number ASC, aya_number ASC, word_position ASC',
    );

    if (maps.isEmpty) {
      // fallback: استخدم مكتبة quran مباشرة
      return _getPageWordsFromPackage(pageNumber);
    }

    return maps.map((m) => QuranWord.fromMap(m)).toList();
  }

  /// fallback مباشر من المكتبة دون DB (عند أول تشغيل أو مشاكل)
  List<QuranWord> _getPageWordsFromPackage(int pageNumber) {
    final result = <QuranWord>[];
    try {
      final pageData = quran.getPageData(pageNumber);
      for (final entry in pageData) {
        final sura = entry['surah'] as int;
        final startAya = entry['start'] as int;
        final endAya = entry['end'] as int;

        for (int aya = startAya; aya <= endAya; aya++) {
          final verseText =
              quran.getVerse(sura, aya, verseEndSymbol: false);
          final words = verseText.trim().split(RegExp(r'\s+'));

          for (int w = 0; w < words.length; w++) {
            final word = words[w];
            if (word.isEmpty) continue;
            result.add(QuranWord(
              id: result.length + 1,
              verseKey: '$sura:$aya',
              suraNumber: sura,
              ayaNumber: aya,
              wordPosition: w,
              textUthmani: word,
              textSimple: _stripDiacritics(word),
              pageNumber: pageNumber,
              lineNumber: 1,
              isLastInAya: w == words.length - 1,
            ));
          }
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ fallback error page $pageNumber: $e');
    }
    return result;
  }

  /// كلمات سورة كاملة
  Future<List<QuranWord>> getSuraWords(int suraNumber) async {
    final db = await database;
    final maps = await db.query(
      'words',
      where: 'sura_number = ?',
      whereArgs: [suraNumber],
      orderBy: 'aya_number ASC, word_position ASC',
    );

    if (maps.isEmpty) {
      return _getSuraWordsFromPackage(suraNumber);
    }
    return maps.map((m) => QuranWord.fromMap(m)).toList();
  }

  List<QuranWord> _getSuraWordsFromPackage(int suraNumber) {
    final result = <QuranWord>[];
    try {
      final verseCount = quran.getVerseCount(suraNumber);
      final page = quran.getSurahPages(suraNumber).first;
      for (int aya = 1; aya <= verseCount; aya++) {
        final verseText =
            quran.getVerse(suraNumber, aya, verseEndSymbol: false);
        final words = verseText.trim().split(RegExp(r'\s+'));
        for (int w = 0; w < words.length; w++) {
          final word = words[w];
          if (word.isEmpty) continue;
          result.add(QuranWord(
            id: result.length + 1,
            verseKey: '$suraNumber:$aya',
            suraNumber: suraNumber,
            ayaNumber: aya,
            wordPosition: w,
            textUthmani: word,
            textSimple: _stripDiacritics(word),
            pageNumber: page,
            lineNumber: 1,
            isLastInAya: w == words.length - 1,
          ));
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ fallback sura $suraNumber: $e');
    }
    return result;
  }

  /// كلمات آية معينة
  Future<List<QuranWord>> getVerseWords(int suraNumber, int ayaNumber) async {
    final db = await database;
    final maps = await db.query(
      'words',
      where: 'sura_number = ? AND aya_number = ?',
      whereArgs: [suraNumber, ayaNumber],
      orderBy: 'word_position ASC',
    );
    if (maps.isEmpty) {
      return _getVerseWordsFromPackage(suraNumber, ayaNumber);
    }
    return maps.map((m) => QuranWord.fromMap(m)).toList();
  }

  List<QuranWord> _getVerseWordsFromPackage(int suraNumber, int ayaNumber) {
    final result = <QuranWord>[];
    try {
      final verseText =
          quran.getVerse(suraNumber, ayaNumber, verseEndSymbol: false);
      final words = verseText.trim().split(RegExp(r'\s+'));
      final page = quran.getSurahPages(suraNumber).first;
      for (int w = 0; w < words.length; w++) {
        final word = words[w];
        if (word.isEmpty) continue;
        result.add(QuranWord(
          id: w + 1,
          verseKey: '$suraNumber:$ayaNumber',
          suraNumber: suraNumber,
          ayaNumber: ayaNumber,
          wordPosition: w,
          textUthmani: word,
          textSimple: _stripDiacritics(word),
          pageNumber: page,
          lineNumber: 1,
          isLastInAya: w == words.length - 1,
        ));
      }
    } catch (_) {}
    return result;
  }

  /// البحث في النص
  Future<List<QuranWord>> searchText(String query) async {
    final db = await database;
    final normalized = query.normalizeArabicFull();
    final maps = await db.query(
      'words',
      where: 'text_simple LIKE ?',
      whereArgs: ['%$normalized%'],
      limit: 100,
    );
    return maps.map((m) => QuranWord.fromMap(m)).toList();
  }

  // ═══════════════ إحصاءات ═══════════════

  /// هل قاعدة البيانات جاهزة وكاملة؟
  Future<bool> isPopulated() async {
    final db = await database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM words'),
    );
    return (count ?? 0) > 1000; // أقل من 1000 كلمة يعني غير مكتملة
  }

  Future<void> close() async {
    final db = _db;
    if (db != null) {
      await db.close();
      _db = null;
    }
  }
}
