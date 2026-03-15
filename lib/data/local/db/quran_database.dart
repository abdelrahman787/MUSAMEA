// lib/data/local/db/quran_database.dart
// قاعدة بيانات المصحف المحلية (SQLite)

import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../../models/quran_word.dart';
import '../../models/quran_verse.dart';
import '../../../core/constants/quran_constants.dart';
import '../../../core/extensions/string_extensions.dart';

class QuranDatabase {
  static QuranDatabase? _instance;
  static Database? _db;

  QuranDatabase._();

  static QuranDatabase get instance {
    _instance ??= QuranDatabase._();
    return _instance!;
  }

  Future<Database> get database async {
    _db ??= await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final dbPath = join(docsDir.path, QuranConstants.quranDbName);

    // إذا لم تكن قاعدة البيانات موجودة، قم بإنشاء بيانات اصطناعية
    final dbFile = File(dbPath);
    if (!dbFile.existsSync()) {
      await _createDatabaseFromScratch(dbPath);
    }

    return openDatabase(
      dbPath,
      version: QuranConstants.quranDbVersion,
      readOnly: false,
    );
  }

  /// إنشاء قاعدة بيانات من البيانات المضمّنة
  Future<void> _createDatabaseFromScratch(String dbPath) async {
    final db = await openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS words (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            verse_key TEXT NOT NULL,
            sura_number INTEGER NOT NULL,
            aya_number INTEGER NOT NULL,
            word_position INTEGER NOT NULL,
            text_uthmani TEXT NOT NULL,
            text_simple TEXT NOT NULL,
            page_number INTEGER NOT NULL,
            line_number INTEGER NOT NULL DEFAULT 1,
            is_last_in_aya INTEGER NOT NULL DEFAULT 0
          )
        ''');

        await db.execute('''
          CREATE INDEX IF NOT EXISTS idx_sura_aya 
          ON words(sura_number, aya_number)
        ''');

        await db.execute('''
          CREATE INDEX IF NOT EXISTS idx_page 
          ON words(page_number)
        ''');

        // أدخل بيانات سورة الفاتحة كأساس
        await _insertFatihaData(db);
        await _insertBaqaraStart(db);
      },
    );
    await db.close();
  }

  /// بيانات سورة الفاتحة الكاملة (للاختبار والعرض)
  Future<void> _insertFatihaData(Database db) async {
    final fatihaWords = [
      // بسم الله الرحمن الرحيم (آية 1)
      {'verse_key': '1:1', 'sura_number': 1, 'aya_number': 1, 'word_position': 0, 'text_uthmani': 'بِسۡمِ', 'text_simple': 'بسم', 'page_number': 1, 'line_number': 2, 'is_last_in_aya': 0},
      {'verse_key': '1:1', 'sura_number': 1, 'aya_number': 1, 'word_position': 1, 'text_uthmani': 'ٱللَّهِ', 'text_simple': 'الله', 'page_number': 1, 'line_number': 2, 'is_last_in_aya': 0},
      {'verse_key': '1:1', 'sura_number': 1, 'aya_number': 1, 'word_position': 2, 'text_uthmani': 'ٱلرَّحۡمَٰنِ', 'text_simple': 'الرحمن', 'page_number': 1, 'line_number': 2, 'is_last_in_aya': 0},
      {'verse_key': '1:1', 'sura_number': 1, 'aya_number': 1, 'word_position': 3, 'text_uthmani': 'ٱلرَّحِيمِ', 'text_simple': 'الرحيم', 'page_number': 1, 'line_number': 2, 'is_last_in_aya': 1},
      // الحمد لله رب العالمين (آية 2)
      {'verse_key': '1:2', 'sura_number': 1, 'aya_number': 2, 'word_position': 0, 'text_uthmani': 'ٱلۡحَمۡدُ', 'text_simple': 'الحمد', 'page_number': 1, 'line_number': 3, 'is_last_in_aya': 0},
      {'verse_key': '1:2', 'sura_number': 1, 'aya_number': 2, 'word_position': 1, 'text_uthmani': 'لِلَّهِ', 'text_simple': 'لله', 'page_number': 1, 'line_number': 3, 'is_last_in_aya': 0},
      {'verse_key': '1:2', 'sura_number': 1, 'aya_number': 2, 'word_position': 2, 'text_uthmani': 'رَبِّ', 'text_simple': 'رب', 'page_number': 1, 'line_number': 3, 'is_last_in_aya': 0},
      {'verse_key': '1:2', 'sura_number': 1, 'aya_number': 2, 'word_position': 3, 'text_uthmani': 'ٱلۡعَٰلَمِينَ', 'text_simple': 'العالمين', 'page_number': 1, 'line_number': 3, 'is_last_in_aya': 1},
      // الرحمن الرحيم (آية 3)
      {'verse_key': '1:3', 'sura_number': 1, 'aya_number': 3, 'word_position': 0, 'text_uthmani': 'ٱلرَّحۡمَٰنِ', 'text_simple': 'الرحمن', 'page_number': 1, 'line_number': 4, 'is_last_in_aya': 0},
      {'verse_key': '1:3', 'sura_number': 1, 'aya_number': 3, 'word_position': 1, 'text_uthmani': 'ٱلرَّحِيمِ', 'text_simple': 'الرحيم', 'page_number': 1, 'line_number': 4, 'is_last_in_aya': 1},
      // مالك يوم الدين (آية 4)
      {'verse_key': '1:4', 'sura_number': 1, 'aya_number': 4, 'word_position': 0, 'text_uthmani': 'مَٰلِكِ', 'text_simple': 'مالك', 'page_number': 1, 'line_number': 4, 'is_last_in_aya': 0},
      {'verse_key': '1:4', 'sura_number': 1, 'aya_number': 4, 'word_position': 1, 'text_uthmani': 'يَوۡمِ', 'text_simple': 'يوم', 'page_number': 1, 'line_number': 4, 'is_last_in_aya': 0},
      {'verse_key': '1:4', 'sura_number': 1, 'aya_number': 4, 'word_position': 2, 'text_uthmani': 'ٱلدِّينِ', 'text_simple': 'الدين', 'page_number': 1, 'line_number': 4, 'is_last_in_aya': 1},
      // إياك نعبد وإياك نستعين (آية 5)
      {'verse_key': '1:5', 'sura_number': 1, 'aya_number': 5, 'word_position': 0, 'text_uthmani': 'إِيَّاكَ', 'text_simple': 'إياك', 'page_number': 1, 'line_number': 5, 'is_last_in_aya': 0},
      {'verse_key': '1:5', 'sura_number': 1, 'aya_number': 5, 'word_position': 1, 'text_uthmani': 'نَعۡبُدُ', 'text_simple': 'نعبد', 'page_number': 1, 'line_number': 5, 'is_last_in_aya': 0},
      {'verse_key': '1:5', 'sura_number': 1, 'aya_number': 5, 'word_position': 2, 'text_uthmani': 'وَإِيَّاكَ', 'text_simple': 'وإياك', 'page_number': 1, 'line_number': 5, 'is_last_in_aya': 0},
      {'verse_key': '1:5', 'sura_number': 1, 'aya_number': 5, 'word_position': 3, 'text_uthmani': 'نَسۡتَعِينُ', 'text_simple': 'نستعين', 'page_number': 1, 'line_number': 5, 'is_last_in_aya': 1},
      // اهدنا الصراط المستقيم (آية 6)
      {'verse_key': '1:6', 'sura_number': 1, 'aya_number': 6, 'word_position': 0, 'text_uthmani': 'ٱهۡدِنَا', 'text_simple': 'اهدنا', 'page_number': 1, 'line_number': 6, 'is_last_in_aya': 0},
      {'verse_key': '1:6', 'sura_number': 1, 'aya_number': 6, 'word_position': 1, 'text_uthmani': 'ٱلصِّرَٰطَ', 'text_simple': 'الصراط', 'page_number': 1, 'line_number': 6, 'is_last_in_aya': 0},
      {'verse_key': '1:6', 'sura_number': 1, 'aya_number': 6, 'word_position': 2, 'text_uthmani': 'ٱلۡمُسۡتَقِيمَ', 'text_simple': 'المستقيم', 'page_number': 1, 'line_number': 6, 'is_last_in_aya': 1},
      // صراط الذين أنعمت عليهم غير المغضوب عليهم ولا الضالين (آية 7)
      {'verse_key': '1:7', 'sura_number': 1, 'aya_number': 7, 'word_position': 0, 'text_uthmani': 'صِرَٰطَ', 'text_simple': 'صراط', 'page_number': 1, 'line_number': 7, 'is_last_in_aya': 0},
      {'verse_key': '1:7', 'sura_number': 1, 'aya_number': 7, 'word_position': 1, 'text_uthmani': 'ٱلَّذِينَ', 'text_simple': 'الذين', 'page_number': 1, 'line_number': 7, 'is_last_in_aya': 0},
      {'verse_key': '1:7', 'sura_number': 1, 'aya_number': 7, 'word_position': 2, 'text_uthmani': 'أَنۡعَمۡتَ', 'text_simple': 'أنعمت', 'page_number': 1, 'line_number': 7, 'is_last_in_aya': 0},
      {'verse_key': '1:7', 'sura_number': 1, 'aya_number': 7, 'word_position': 3, 'text_uthmani': 'عَلَيۡهِمۡ', 'text_simple': 'عليهم', 'page_number': 1, 'line_number': 7, 'is_last_in_aya': 0},
      {'verse_key': '1:7', 'sura_number': 1, 'aya_number': 7, 'word_position': 4, 'text_uthmani': 'غَيۡرِ', 'text_simple': 'غير', 'page_number': 1, 'line_number': 8, 'is_last_in_aya': 0},
      {'verse_key': '1:7', 'sura_number': 1, 'aya_number': 7, 'word_position': 5, 'text_uthmani': 'ٱلۡمَغۡضُوبِ', 'text_simple': 'المغضوب', 'page_number': 1, 'line_number': 8, 'is_last_in_aya': 0},
      {'verse_key': '1:7', 'sura_number': 1, 'aya_number': 7, 'word_position': 6, 'text_uthmani': 'عَلَيۡهِمۡ', 'text_simple': 'عليهم', 'page_number': 1, 'line_number': 8, 'is_last_in_aya': 0},
      {'verse_key': '1:7', 'sura_number': 1, 'aya_number': 7, 'word_position': 7, 'text_uthmani': 'وَلَا', 'text_simple': 'ولا', 'page_number': 1, 'line_number': 8, 'is_last_in_aya': 0},
      {'verse_key': '1:7', 'sura_number': 1, 'aya_number': 7, 'word_position': 8, 'text_uthmani': 'ٱلضَّآلِّينَ', 'text_simple': 'الضالين', 'page_number': 1, 'line_number': 8, 'is_last_in_aya': 1},
    ];

    final batch = db.batch();
    for (final word in fatihaWords) {
      batch.insert('words', word);
    }
    await batch.commit(noResult: true);
  }

  /// بيانات بداية سورة البقرة
  Future<void> _insertBaqaraStart(Database db) async {
    final baqaraWords = [
      {'verse_key': '2:1', 'sura_number': 2, 'aya_number': 1, 'word_position': 0, 'text_uthmani': 'الٓمٓ', 'text_simple': 'الم', 'page_number': 2, 'line_number': 3, 'is_last_in_aya': 1},
      {'verse_key': '2:2', 'sura_number': 2, 'aya_number': 2, 'word_position': 0, 'text_uthmani': 'ذَٰلِكَ', 'text_simple': 'ذلك', 'page_number': 2, 'line_number': 4, 'is_last_in_aya': 0},
      {'verse_key': '2:2', 'sura_number': 2, 'aya_number': 2, 'word_position': 1, 'text_uthmani': 'ٱلۡكِتَٰبُ', 'text_simple': 'الكتاب', 'page_number': 2, 'line_number': 4, 'is_last_in_aya': 0},
      {'verse_key': '2:2', 'sura_number': 2, 'aya_number': 2, 'word_position': 2, 'text_uthmani': 'لَا', 'text_simple': 'لا', 'page_number': 2, 'line_number': 4, 'is_last_in_aya': 0},
      {'verse_key': '2:2', 'sura_number': 2, 'aya_number': 2, 'word_position': 3, 'text_uthmani': 'رَيۡبَۛ', 'text_simple': 'ريب', 'page_number': 2, 'line_number': 4, 'is_last_in_aya': 0},
      {'verse_key': '2:2', 'sura_number': 2, 'aya_number': 2, 'word_position': 4, 'text_uthmani': 'فِيهِۛ', 'text_simple': 'فيه', 'page_number': 2, 'line_number': 4, 'is_last_in_aya': 0},
      {'verse_key': '2:2', 'sura_number': 2, 'aya_number': 2, 'word_position': 5, 'text_uthmani': 'هُدٗى', 'text_simple': 'هدى', 'page_number': 2, 'line_number': 4, 'is_last_in_aya': 0},
      {'verse_key': '2:2', 'sura_number': 2, 'aya_number': 2, 'word_position': 6, 'text_uthmani': 'لِّلۡمُتَّقِينَ', 'text_simple': 'للمتقين', 'page_number': 2, 'line_number': 4, 'is_last_in_aya': 1},
      {'verse_key': '2:3', 'sura_number': 2, 'aya_number': 3, 'word_position': 0, 'text_uthmani': 'ٱلَّذِينَ', 'text_simple': 'الذين', 'page_number': 2, 'line_number': 5, 'is_last_in_aya': 0},
      {'verse_key': '2:3', 'sura_number': 2, 'aya_number': 3, 'word_position': 1, 'text_uthmani': 'يُؤۡمِنُونَ', 'text_simple': 'يؤمنون', 'page_number': 2, 'line_number': 5, 'is_last_in_aya': 0},
      {'verse_key': '2:3', 'sura_number': 2, 'aya_number': 3, 'word_position': 2, 'text_uthmani': 'بِٱلۡغَيۡبِ', 'text_simple': 'بالغيب', 'page_number': 2, 'line_number': 5, 'is_last_in_aya': 0},
      {'verse_key': '2:3', 'sura_number': 2, 'aya_number': 3, 'word_position': 3, 'text_uthmani': 'وَيُقِيمُونَ', 'text_simple': 'ويقيمون', 'page_number': 2, 'line_number': 5, 'is_last_in_aya': 0},
      {'verse_key': '2:3', 'sura_number': 2, 'aya_number': 3, 'word_position': 4, 'text_uthmani': 'ٱلصَّلَوٰةَ', 'text_simple': 'الصلاة', 'page_number': 2, 'line_number': 5, 'is_last_in_aya': 0},
      {'verse_key': '2:3', 'sura_number': 2, 'aya_number': 3, 'word_position': 5, 'text_uthmani': 'وَمِمَّا', 'text_simple': 'ومما', 'page_number': 2, 'line_number': 5, 'is_last_in_aya': 0},
      {'verse_key': '2:3', 'sura_number': 2, 'aya_number': 3, 'word_position': 6, 'text_uthmani': 'رَزَقۡنَٰهُمۡ', 'text_simple': 'رزقناهم', 'page_number': 2, 'line_number': 5, 'is_last_in_aya': 0},
      {'verse_key': '2:3', 'sura_number': 2, 'aya_number': 3, 'word_position': 7, 'text_uthmani': 'يُنفِقُونَ', 'text_simple': 'ينفقون', 'page_number': 2, 'line_number': 5, 'is_last_in_aya': 1},
    ];

    final batch = db.batch();
    for (final word in baqaraWords) {
      batch.insert('words', word);
    }
    await batch.commit(noResult: true);
  }

  // ═══════════════ Query Methods ═══════════════

  /// الحصول على كلمات صفحة معينة
  Future<List<QuranWord>> getPageWords(int pageNumber) async {
    final db = await database;
    final maps = await db.query(
      'words',
      where: 'page_number = ?',
      whereArgs: [pageNumber],
      orderBy: 'sura_number ASC, aya_number ASC, word_position ASC',
    );
    return maps.map((m) => QuranWord.fromMap(m)).toList();
  }

  /// الحصول على كلمات سورة معينة
  Future<List<QuranWord>> getSuraWords(int suraNumber) async {
    final db = await database;
    final maps = await db.query(
      'words',
      where: 'sura_number = ?',
      whereArgs: [suraNumber],
      orderBy: 'aya_number ASC, word_position ASC',
    );
    return maps.map((m) => QuranWord.fromMap(m)).toList();
  }

  /// الحصول على كلمات آية معينة
  Future<List<QuranWord>> getVerseWords(int suraNumber, int ayaNumber) async {
    final db = await database;
    final maps = await db.query(
      'words',
      where: 'sura_number = ? AND aya_number = ?',
      whereArgs: [suraNumber, ayaNumber],
      orderBy: 'word_position ASC',
    );
    return maps.map((m) => QuranWord.fromMap(m)).toList();
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

  Future<void> close() async {
    final db = _db;
    if (db != null) {
      await db.close();
      _db = null;
    }
  }
}
