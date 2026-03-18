// lib/data/local/db/quran_database.dart
// ─── Cache-First: shared_preferences (JSON) + Quran.Foundation API ──────────
// يعمل على الويب وAndroid بدون مشاكل conditional imports أو sqflite
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/quran_word.dart';
import '../../remote/quran_api_service.dart';
import '../../../core/extensions/string_extensions.dart';

class QuranDatabase {
  // ─── Singleton ──────────────────────────────────────────────────────────────
  static QuranDatabase? _instance;
  QuranDatabase._();
  static QuranDatabase get instance {
    _instance ??= QuranDatabase._();
    return _instance!;
  }

  // ─── ثوابت ─────────────────────────────────────────────────────────────────
  static const int _cacheTtlMs   = 30 * 24 * 3600 * 1000; // 30 يوماً
  static const int _totalPages   = 604;
  static const int _totalSuras   = 114;
  static const String _pageKey   = 'qp_';   // prefix لصفحة
  static const String _suraKey   = 'qs_';   // prefix لسورة

  // ─── التبعيات ───────────────────────────────────────────────────────────────
  final QuranApiService _api = QuranApiService();
  SharedPreferences? _prefs;

  // ─── تهيئة SharedPreferences ─────────────────────────────────────────────
  Future<SharedPreferences> _getPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Cache helpers
  // ═══════════════════════════════════════════════════════════════════════════
  String _encode(List<QuranWord> words) => jsonEncode({
        'ts': DateTime.now().millisecondsSinceEpoch,
        'data': words.map((w) => w.toMap()).toList(),
      });

  ({int ts, List<QuranWord> words})? _decode(String? raw) {
    if (raw == null) return null;
    try {
      final outer  = jsonDecode(raw) as Map<String, dynamic>;
      final ts     = outer['ts'] as int? ?? 0;
      final list   = (outer['data'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(QuranWord.fromMap)
          .toList();
      return (ts: ts, words: list);
    } catch (_) {
      return null;
    }
  }

  bool _isExpired(int tsMs) =>
      DateTime.now().millisecondsSinceEpoch - tsMs > _cacheTtlMs;

  // ═══════════════════════════════════════════════════════════════════════════
  // getPageWords — cache-first ثم API
  // ═══════════════════════════════════════════════════════════════════════════
  Future<List<QuranWord>> getPageWords(int pageNumber) async {
    if (pageNumber < 1 || pageNumber > _totalPages) return [];

    final prefs = await _getPrefs();
    final key   = '$_pageKey$pageNumber';

    // 1. حاول من الـ cache
    final cached = _decode(prefs.getString(key));
    if (cached != null && !_isExpired(cached.ts) && cached.words.isNotEmpty) {
      if (kDebugMode) {
        debugPrint('📦 Cache hit: page $pageNumber (${cached.words.length} words)');
      }
      return cached.words;
    }

    // 2. اجلب من الـ API
    try {
      if (kDebugMode) debugPrint('🌐 API fetch: page $pageNumber ...');
      final words = await _api.fetchPageWords(pageNumber);
      if (words.isNotEmpty) {
        await prefs.setString(key, _encode(words));
        if (kDebugMode) {
          debugPrint('✅ API + cache saved: page $pageNumber (${words.length} words)');
        }
        return words;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ API error page $pageNumber: $e');
    }

    // 3. Fallback: cache منتهي الصلاحية أفضل من لا شيء
    if (cached != null && cached.words.isNotEmpty) {
      if (kDebugMode) debugPrint('⚠️  Stale cache page $pageNumber');
      return cached.words;
    }

    return [];
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // getSuraWords — cache-first ثم API
  // ═══════════════════════════════════════════════════════════════════════════
  Future<List<QuranWord>> getSuraWords(int suraNumber) async {
    if (suraNumber < 1 || suraNumber > _totalSuras) return [];

    final prefs = await _getPrefs();
    final key   = '$_suraKey$suraNumber';

    final cached = _decode(prefs.getString(key));
    if (cached != null && !_isExpired(cached.ts) && cached.words.isNotEmpty) {
      if (kDebugMode) {
        debugPrint('📦 Cache hit: sura $suraNumber (${cached.words.length} words)');
      }
      return cached.words;
    }

    try {
      if (kDebugMode) debugPrint('🌐 API fetch: sura $suraNumber ...');
      final words = await _api.fetchSuraWords(suraNumber);
      if (words.isNotEmpty) {
        await prefs.setString(key, _encode(words));
        if (kDebugMode) {
          debugPrint('✅ API + cache saved: sura $suraNumber (${words.length} words)');
        }
        return words;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ API error sura $suraNumber: $e');
    }

    return cached?.words ?? [];
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // getVerseWords
  // ═══════════════════════════════════════════════════════════════════════════
  Future<List<QuranWord>> getVerseWords(int suraNumber, int ayaNumber) async {
    final all = await getSuraWords(suraNumber);
    return all
        .where((w) => w.suraNumber == suraNumber && w.ayaNumber == ayaNumber)
        .toList();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // searchText — يبحث في الـ cache المحلي فقط
  // ═══════════════════════════════════════════════════════════════════════════
  Future<List<QuranWord>> searchText(String query) async {
    if (query.trim().isEmpty) return [];
    final normalized = query.normalizeArabicFull();
    final prefs      = await _getPrefs();
    final result     = <QuranWord>[];

    for (final key in prefs.getKeys()) {
      if (!key.startsWith(_pageKey) && !key.startsWith(_suraKey)) continue;
      final cached = _decode(prefs.getString(key));
      if (cached == null) continue;
      for (final w in cached.words) {
        if (w.textSimple.contains(normalized) ||
            w.textUthmani.contains(normalized)) {
          result.add(w);
          if (result.length >= 100) return result;
        }
      }
    }
    return result;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Utils
  // ═══════════════════════════════════════════════════════════════════════════
  int get totalSurahs => _totalSuras;
  int get totalPages  => _totalPages;

  Future<bool> isPopulated() async {
    final prefs = await _getPrefs();
    return prefs.getKeys().any(
      (k) => k.startsWith(_pageKey) || k.startsWith(_suraKey),
    );
  }

  Future<void> clearCache() async {
    final prefs = await _getPrefs();
    final keys  = prefs.getKeys().where(
      (k) => k.startsWith(_pageKey) || k.startsWith(_suraKey),
    ).toList();
    for (final k in keys) { await prefs.remove(k); }
    if (kDebugMode) debugPrint('🗑️ QuranDatabase cache cleared');
  }

  /// للتوافق مع AppDependencies
  Future<void> close() async {}
}
