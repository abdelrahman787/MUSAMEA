// lib/data/local/db/quran_database.dart
// ─── استراتيجية Cache-First — متوافقة مع Web وAndroid ──────────────────────
//
//  Web     → shared_preferences  (JSON strings, لا SQLite)
//  Android → sqflite             (قاعدة بيانات SQLite حقيقية)
//
//  TTL: 30 يوماً في كلا الحالتين
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../models/quran_word.dart';
import '../../remote/quran_api_service.dart';
import '../../../core/extensions/string_extensions.dart';

// فقط على المنصات التي تدعم sqflite (Android / iOS / Desktop)
import 'quran_database_sqflite.dart'
    if (dart.library.html) 'quran_database_web.dart';

class QuranDatabase {
  // ─── Singleton ──────────────────────────────────────
  static QuranDatabase? _instance;
  QuranDatabase._();
  static QuranDatabase get instance {
    _instance ??= QuranDatabase._();
    return _instance!;
  }

  // ─── ثوابت ──────────────────────────────────────────
  static const int _cacheTtlMs = 30 * 24 * 3600 * 1000; // 30 يوماً
  static const int _totalPages = 604;
  static const int _totalSuras = 114;

  // ─── التبعيات ────────────────────────────────────────
  final QuranApiService _api = QuranApiService();
  late final QuranCacheBackend _backend = QuranCacheBackend();

  // ═══════════════════════════════════════════════════════
  // getPageWords — cache-first ثم API
  // ═══════════════════════════════════════════════════════
  Future<List<QuranWord>> getPageWords(int pageNumber) async {
    if (pageNumber < 1 || pageNumber > _totalPages) return [];

    await _backend.init();

    // 1. جرّب الـ cache
    final cached = await _backend.loadPage(pageNumber);
    if (cached != null && !_isExpired(cached.cachedAt)) {
      if (kDebugMode) {
        debugPrint('📦 Cache hit: page $pageNumber (${cached.words.length} words)');
      }
      return cached.words;
    }

    // 2. جلب من API
    try {
      if (kDebugMode) debugPrint('🌐 API fetch: page $pageNumber');
      final words = await _api.fetchPageWords(pageNumber);
      if (words.isNotEmpty) {
        await _backend.savePage(pageNumber, words);
        return words;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ API error page $pageNumber: $e');
    }

    // 3. fallback: cache منتهي الصلاحية أفضل من لا شيء
    return cached?.words ?? [];
  }

  // ═══════════════════════════════════════════════════════
  // getSuraWords — cache-first ثم API
  // ═══════════════════════════════════════════════════════
  Future<List<QuranWord>> getSuraWords(int suraNumber) async {
    if (suraNumber < 1 || suraNumber > _totalSuras) return [];

    await _backend.init();

    final cached = await _backend.loadSura(suraNumber);
    if (cached != null && !_isExpired(cached.cachedAt)) {
      if (kDebugMode) {
        debugPrint('📦 Cache hit: sura $suraNumber (${cached.words.length} words)');
      }
      return cached.words;
    }

    try {
      if (kDebugMode) debugPrint('🌐 API fetch: sura $suraNumber');
      final words = await _api.fetchSuraWords(suraNumber);
      if (words.isNotEmpty) {
        await _backend.saveSura(suraNumber, words);
        return words;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ API error sura $suraNumber: $e');
    }

    return cached?.words ?? [];
  }

  // ═══════════════════════════════════════════════════════
  // getVerseWords
  // ═══════════════════════════════════════════════════════
  Future<List<QuranWord>> getVerseWords(int suraNumber, int ayaNumber) async {
    final all = await getSuraWords(suraNumber);
    return all
        .where((w) => w.suraNumber == suraNumber && w.ayaNumber == ayaNumber)
        .toList();
  }

  // ═══════════════════════════════════════════════════════
  // searchText — بحث في الـ cache المحلي
  // ═══════════════════════════════════════════════════════
  Future<List<QuranWord>> searchText(String query) async {
    if (query.trim().isEmpty) return [];

    await _backend.init();
    final normalized = query.normalizeArabicFull();
    return _backend.searchWords(normalized, limit: 100);
  }

  // ─── مساعدات ────────────────────────────────────────
  bool _isExpired(int cachedAtMs) {
    return DateTime.now().millisecondsSinceEpoch - cachedAtMs > _cacheTtlMs;
  }

  int get totalSurahs => _totalSuras;
  int get totalPages => _totalPages;

  Future<bool> isPopulated() async {
    await _backend.init();
    return _backend.hasAnyData();
  }

  Future<void> clearCache() async {
    await _backend.init();
    await _backend.clearAll();
    if (kDebugMode) debugPrint('🗑️ QuranDatabase cache cleared');
  }

  Future<void> close() async {
    await _backend.close();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// مساعد مشترك: تسلسل / فك تسلسل QuranWord ← JSON
// ─────────────────────────────────────────────────────────────────────────────
class CachedPageData {
  final int cachedAt;
  final List<QuranWord> words;
  CachedPageData({required this.cachedAt, required this.words});
}

String encodeWords(List<QuranWord> words) =>
    jsonEncode(words.map((w) => w.toMap()).toList());

CachedPageData? decodeWords(String? raw) {
  if (raw == null) return null;
  try {
    final outer = jsonDecode(raw) as Map<String, dynamic>;
    final cachedAt = outer['ts'] as int? ?? 0;
    final list = (outer['data'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(QuranWord.fromMap)
        .toList();
    return CachedPageData(cachedAt: cachedAt, words: list);
  } catch (_) {
    return null;
  }
}

String wrapWords(List<QuranWord> words) => jsonEncode({
      'ts': DateTime.now().millisecondsSinceEpoch,
      'data': words.map((w) => w.toMap()).toList(),
    });
