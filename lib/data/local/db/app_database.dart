// lib/data/local/db/app_database.dart
// قاعدة بيانات التقارير والجلسات (SQLite عبر sqflite)

import 'dart:async';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  static AppDatabase? _instance;
  static Database? _db;

  AppDatabase._();

  static AppDatabase get instance {
    _instance ??= AppDatabase._();
    return _instance!;
  }

  Future<Database> get database async {
    _db ??= await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final dbPath = join(docsDir.path, 'musaami_reports.db');

    return openDatabase(
      dbPath,
      version: 1,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // جدول جلسات التسميع
    await db.execute('''
      CREATE TABLE IF NOT EXISTS recitation_sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sura_number INTEGER NOT NULL,
        sura_name TEXT NOT NULL,
        start_aya INTEGER NOT NULL,
        end_aya INTEGER NOT NULL,
        start_page INTEGER NOT NULL DEFAULT 1,
        date_time_ms INTEGER NOT NULL,
        duration_seconds INTEGER NOT NULL DEFAULT 0,
        total_words INTEGER NOT NULL DEFAULT 0,
        correct_words INTEGER NOT NULL DEFAULT 0,
        forgotten_words INTEGER NOT NULL DEFAULT 0,
        wrong_word_errors INTEGER NOT NULL DEFAULT 0,
        diacritics_errors INTEGER NOT NULL DEFAULT 0,
        accuracy_percent REAL NOT NULL DEFAULT 0.0,
        mode TEXT NOT NULL DEFAULT 'HIDDEN'
      )
    ''');

    // جدول أحداث الكلمات
    await db.execute('''
      CREATE TABLE IF NOT EXISTS word_events (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id INTEGER NOT NULL,
        sura_number INTEGER NOT NULL,
        aya_number INTEGER NOT NULL,
        word_position INTEGER NOT NULL,
        expected_word_uthmani TEXT NOT NULL,
        expected_word_simple TEXT NOT NULL,
        spoken_word TEXT,
        error_type TEXT NOT NULL DEFAULT 'CORRECT',
        delay_before_speaking_ms INTEGER NOT NULL DEFAULT 0,
        asr_confidence REAL NOT NULL DEFAULT 0.0,
        attempts_count INTEGER NOT NULL DEFAULT 1,
        FOREIGN KEY (session_id) REFERENCES recitation_sessions(id) ON DELETE CASCADE
      )
    ''');

    // جدول الكلمات الضعيفة المجمعة
    await db.execute('''
      CREATE TABLE IF NOT EXISTS weak_words (
        word_key TEXT PRIMARY KEY,
        sura_number INTEGER NOT NULL,
        sura_name TEXT NOT NULL,
        aya_number INTEGER NOT NULL,
        word_position INTEGER NOT NULL,
        word_text TEXT NOT NULL,
        forgotten_count INTEGER NOT NULL DEFAULT 0,
        wrong_word_count INTEGER NOT NULL DEFAULT 0,
        diacritics_error_count INTEGER NOT NULL DEFAULT 0,
        total_error_count INTEGER NOT NULL DEFAULT 0,
        last_error_date_ms INTEGER NOT NULL DEFAULT 0,
        last_error_type TEXT NOT NULL DEFAULT ''
      )
    ''');

    // الفهارس
    await db.execute('CREATE INDEX IF NOT EXISTS idx_sessions_sura ON recitation_sessions(sura_number)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_sessions_date ON recitation_sessions(date_time_ms)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_events_session ON word_events(session_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_events_word ON word_events(sura_number, aya_number, word_position)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_weak_errors ON weak_words(total_error_count DESC)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // يمكن إضافة migrations هنا
  }

  // ═══════════════ Session Operations ═══════════════

  Future<int> insertSession(Map<String, dynamic> session) async {
    final db = await database;
    return db.insert('recitation_sessions', session);
  }

  Future<void> updateSession(int sessionId, Map<String, dynamic> updates) async {
    final db = await database;
    await db.update(
      'recitation_sessions',
      updates,
      where: 'id = ?',
      whereArgs: [sessionId],
    );
  }

  Future<Map<String, dynamic>?> getSession(int sessionId) async {
    final db = await database;
    final results = await db.query(
      'recitation_sessions',
      where: 'id = ?',
      whereArgs: [sessionId],
      limit: 1,
    );
    return results.isEmpty ? null : results.first;
  }

  Future<List<Map<String, dynamic>>> getRecentSessions({int limit = 20}) async {
    final db = await database;
    return db.query(
      'recitation_sessions',
      orderBy: 'date_time_ms DESC',
      limit: limit,
    );
  }

  Future<Map<String, dynamic>?> getLastSession() async {
    final db = await database;
    final results = await db.query(
      'recitation_sessions',
      orderBy: 'date_time_ms DESC',
      limit: 1,
    );
    return results.isEmpty ? null : results.first;
  }

  Future<List<Map<String, dynamic>>> getProgressData({
    int suraFilter = -1,
    required int fromDate,
  }) async {
    final db = await database;
    String where = 'date_time_ms >= ?';
    List<dynamic> args = [fromDate];

    if (suraFilter != -1) {
      where += ' AND sura_number = ?';
      args.add(suraFilter);
    }

    return db.query(
      'recitation_sessions',
      columns: ['id', 'date_time_ms', 'sura_name', 'sura_number', 'accuracy_percent', 'total_words', 'duration_seconds'],
      where: where,
      whereArgs: args,
      orderBy: 'date_time_ms ASC',
    );
  }

  // ═══════════════ Word Events Operations ═══════════════

  Future<int> insertWordEvent(Map<String, dynamic> event) async {
    final db = await database;
    return db.insert('word_events', event);
  }

  Future<List<Map<String, dynamic>>> getSessionWordEvents(int sessionId) async {
    final db = await database;
    return db.query(
      'word_events',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'aya_number ASC, word_position ASC',
    );
  }

  Future<List<Map<String, dynamic>>> getWordEventsBySura(int suraNumber) async {
    final db = await database;
    return db.rawQuery('''
      SELECT we.*, rs.sura_name, rs.date_time_ms
      FROM word_events we
      JOIN recitation_sessions rs ON we.session_id = rs.id
      WHERE we.sura_number = ?
      ORDER BY rs.date_time_ms DESC
    ''', [suraNumber]);
  }

  // ═══════════════ Weak Words Operations ═══════════════

  Future<void> upsertWeakWord(Map<String, dynamic> data) async {
    final db = await database;
    await db.rawInsert('''
      INSERT INTO weak_words 
        (word_key, sura_number, sura_name, aya_number, word_position, word_text,
         forgotten_count, wrong_word_count, diacritics_error_count, total_error_count,
         last_error_date_ms, last_error_type)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ON CONFLICT(word_key) DO UPDATE SET
        forgotten_count = forgotten_count + excluded.forgotten_count,
        wrong_word_count = wrong_word_count + excluded.wrong_word_count,
        diacritics_error_count = diacritics_error_count + excluded.diacritics_error_count,
        total_error_count = total_error_count + 1,
        last_error_date_ms = excluded.last_error_date_ms,
        last_error_type = excluded.last_error_type
    ''', [
      data['word_key'], data['sura_number'], data['sura_name'],
      data['aya_number'], data['word_position'], data['word_text'],
      data['forgotten_count'] ?? 0, data['wrong_word_count'] ?? 0,
      data['diacritics_error_count'] ?? 0, 1,
      data['last_error_date_ms'], data['last_error_type'],
    ]);
  }

  Future<List<Map<String, dynamic>>> getWeakPoints({int limit = 50}) async {
    final db = await database;
    return db.rawQuery('''
      SELECT 
        word_key, sura_number, sura_name, aya_number, word_position, word_text,
        forgotten_count, wrong_word_count, diacritics_error_count,
        total_error_count, last_error_date_ms, last_error_type
      FROM weak_words
      WHERE total_error_count >= 2
      ORDER BY total_error_count DESC, last_error_date_ms DESC
      LIMIT ?
    ''', [limit]);
  }

  Future<List<Map<String, dynamic>>> getWeakPointsAggregated() async {
    final db = await database;
    return db.rawQuery('''
      SELECT 
        sura_number, aya_number, word_position,
        expected_word_uthmani as word_text,
        COUNT(CASE WHEN error_type='FORGOTTEN' THEN 1 END) as forgotten_count,
        COUNT(CASE WHEN error_type='WRONG_WORD' THEN 1 END) as wrong_word_count,
        COUNT(CASE WHEN error_type='WRONG_DIACRITICS' THEN 1 END) as diac_count,
        COUNT(*) as total_errors,
        MAX(session_id) as last_session_id
      FROM word_events
      WHERE error_type != 'CORRECT'
      GROUP BY sura_number, aya_number, word_position
      HAVING total_errors >= 2
      ORDER BY total_errors DESC
      LIMIT 50
    ''');
  }

  // ═══════════════ Statistics ═══════════════

  Future<Map<String, dynamic>> getOverallStats() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT 
        COUNT(*) as total_sessions,
        COALESCE(SUM(duration_seconds), 0) as total_duration,
        COALESCE(AVG(accuracy_percent), 0) as avg_accuracy,
        COALESCE(SUM(total_words), 0) as total_words_recited,
        COALESCE(SUM(correct_words), 0) as total_correct_words,
        COALESCE(MAX(accuracy_percent), 0) as best_accuracy
      FROM recitation_sessions
    ''');
    return result.isEmpty ? {} : result.first;
  }

  Future<void> deleteSession(int sessionId) async {
    final db = await database;
    await db.delete(
      'recitation_sessions',
      where: 'id = ?',
      whereArgs: [sessionId],
    );
  }

  Future<void> close() async {
    final db = _db;
    if (db != null) {
      await db.close();
      _db = null;
    }
  }
}
