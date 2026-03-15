// lib/data/local/db/quran_database_web.dart
// backend لمنصة الويب — يستخدم shared_preferences لتخزين JSON

import 'package:shared_preferences/shared_preferences.dart';
import '../../models/quran_word.dart';
import 'quran_database.dart';

class QuranCacheBackend {
  SharedPreferences? _prefs;
  bool _initialized = false;

  static const String _pagePrefix = 'qpage_';
  static const String _suraPrefix = 'qsura_';

  Future<void> init() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    _initialized = true;
  }

  Future<CachedPageData?> loadPage(int pageNumber) async {
    final raw = _prefs?.getString('$_pagePrefix$pageNumber');
    return decodeWords(raw);
  }

  Future<void> savePage(int pageNumber, List<QuranWord> words) async {
    await _prefs?.setString('$_pagePrefix$pageNumber', wrapWords(words));
  }

  Future<CachedPageData?> loadSura(int suraNumber) async {
    final raw = _prefs?.getString('$_suraPrefix$suraNumber');
    return decodeWords(raw);
  }

  Future<void> saveSura(int suraNumber, List<QuranWord> words) async {
    await _prefs?.setString('$_suraPrefix$suraNumber', wrapWords(words));
  }

  Future<List<QuranWord>> searchWords(String normalized, {int limit = 100}) async {
    final result = <QuranWord>[];
    final keys = _prefs?.getKeys() ?? {};
    for (final key in keys) {
      if (!key.startsWith(_pagePrefix) && !key.startsWith(_suraPrefix)) continue;
      final raw = _prefs?.getString(key);
      final data = decodeWords(raw);
      if (data == null) continue;
      for (final w in data.words) {
        if (w.textSimple.contains(normalized) ||
            w.textUthmani.contains(normalized)) {
          result.add(w);
          if (result.length >= limit) return result;
        }
      }
    }
    return result;
  }

  bool hasAnyData() {
    final keys = _prefs?.getKeys() ?? {};
    return keys.any(
      (k) => k.startsWith(_pagePrefix) || k.startsWith(_suraPrefix),
    );
  }

  Future<void> clearAll() async {
    final keys = _prefs?.getKeys().toList() ?? [];
    for (final k in keys) {
      if (k.startsWith(_pagePrefix) || k.startsWith(_suraPrefix)) {
        await _prefs?.remove(k);
      }
    }
  }

  Future<void> close() async {}
}
