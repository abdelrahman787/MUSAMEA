// lib/data/local/db/quran_database.dart
// بيانات القرآن الكامل — مباشرة من مكتبة quran (114 سورة، 6236 آية)
// لا تحتاج قاعدة بيانات خارجية — البيانات مُضمَّنة في الحزمة

import 'package:flutter/foundation.dart';
import 'package:quran/quran.dart' as quran_lib;
import '../../models/quran_word.dart';
import '../../../core/extensions/string_extensions.dart';

class QuranDatabase {
  static QuranDatabase? _instance;

  QuranDatabase._();

  static QuranDatabase get instance {
    _instance ??= QuranDatabase._();
    return _instance!;
  }

  // ═══════════════ طرق استرجاع البيانات ═══════════════

  /// كلمات صفحة كاملة — مباشرة من المكتبة
  Future<List<QuranWord>> getPageWords(int pageNumber) async {
    if (pageNumber < 1 || pageNumber > quran_lib.totalPagesCount) {
      return [];
    }
    final result = <QuranWord>[];
    try {
      final pageData = quran_lib.getPageData(pageNumber);

      for (final surahData in pageData) {
        final surahNumber = surahData['surah'] as int;
        final startVerse = surahData['start'] as int;
        final endVerse = surahData['end'] as int;

        for (int ayaNum = startVerse; ayaNum <= endVerse; ayaNum++) {
          final verseText =
              quran_lib.getVerse(surahNumber, ayaNum, verseEndSymbol: false);
          final words = verseText.trim().split(RegExp(r'\s+'));

          for (int i = 0; i < words.length; i++) {
            final word = words[i].trim();
            if (word.isEmpty) continue;

            result.add(QuranWord(
              id: result.length + 1,
              verseKey: '$surahNumber:$ayaNum',
              suraNumber: surahNumber,
              ayaNumber: ayaNum,
              wordPosition: i,
              textUthmani: word,
              textSimple: _removeArabicDiacritics(word),
              pageNumber: pageNumber,
              lineNumber: 1,
              isLastInAya: i == words.length - 1,
            ));
          }
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ getPageWords($pageNumber) error: $e');
    }
    return result;
  }

  /// كلمات سورة كاملة
  Future<List<QuranWord>> getSuraWords(int suraNumber) async {
    if (suraNumber < 1 || suraNumber > quran_lib.totalSurahCount) return [];
    final result = <QuranWord>[];
    try {
      final verseCount = quran_lib.getVerseCount(suraNumber);
      for (int ayaNum = 1; ayaNum <= verseCount; ayaNum++) {
        final verseText =
            quran_lib.getVerse(suraNumber, ayaNum, verseEndSymbol: false);
        final words = verseText.trim().split(RegExp(r'\s+'));
        final pageNum = quran_lib.getPageNumber(suraNumber, ayaNum);

        for (int i = 0; i < words.length; i++) {
          final word = words[i].trim();
          if (word.isEmpty) continue;
          result.add(QuranWord(
            id: result.length + 1,
            verseKey: '$suraNumber:$ayaNum',
            suraNumber: suraNumber,
            ayaNumber: ayaNum,
            wordPosition: i,
            textUthmani: word,
            textSimple: _removeArabicDiacritics(word),
            pageNumber: pageNum,
            lineNumber: 1,
            isLastInAya: i == words.length - 1,
          ));
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ getSuraWords($suraNumber) error: $e');
    }
    return result;
  }

  /// كلمات آية معينة
  Future<List<QuranWord>> getVerseWords(int suraNumber, int ayaNumber) async {
    final result = <QuranWord>[];
    try {
      final verseText =
          quran_lib.getVerse(suraNumber, ayaNumber, verseEndSymbol: false);
      final words = verseText.trim().split(RegExp(r'\s+'));
      final pageNum = quran_lib.getPageNumber(suraNumber, ayaNumber);

      for (int i = 0; i < words.length; i++) {
        final word = words[i].trim();
        if (word.isEmpty) continue;
        result.add(QuranWord(
          id: i + 1,
          verseKey: '$suraNumber:$ayaNumber',
          suraNumber: suraNumber,
          ayaNumber: ayaNumber,
          wordPosition: i,
          textUthmani: word,
          textSimple: _removeArabicDiacritics(word),
          pageNumber: pageNum,
          lineNumber: 1,
          isLastInAya: i == words.length - 1,
        ));
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ getVerseWords error: $e');
    }
    return result;
  }

  /// البحث في القرآن (بسيط — يبحث في نص الآية)
  Future<List<QuranWord>> searchText(String query) async {
    if (query.trim().isEmpty) return [];
    final normalized = query.normalizeArabicFull();
    final result = <QuranWord>[];

    try {
      for (int sura = 1; sura <= quran_lib.totalSurahCount; sura++) {
        final verseCount = quran_lib.getVerseCount(sura);
        for (int aya = 1; aya <= verseCount; aya++) {
          final verseText =
              quran_lib.getVerse(sura, aya, verseEndSymbol: false);
          if (!verseText.contains(normalized) &&
              !_removeArabicDiacritics(verseText).contains(normalized)) {
            continue;
          }
          final words = verseText.trim().split(RegExp(r'\s+'));
          final pageNum = quran_lib.getPageNumber(sura, aya);
          for (int i = 0; i < words.length; i++) {
            final word = words[i].trim();
            if (word.isEmpty) continue;
            final simple = _removeArabicDiacritics(word);
            if (!simple.contains(normalized) && !word.contains(normalized)) {
              continue;
            }
            result.add(QuranWord(
              id: result.length + 1,
              verseKey: '$sura:$aya',
              suraNumber: sura,
              ayaNumber: aya,
              wordPosition: i,
              textUthmani: word,
              textSimple: simple,
              pageNumber: pageNum,
              lineNumber: 1,
              isLastInAya: i == words.length - 1,
            ));
            if (result.length >= 100) return result;
          }
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ searchText error: $e');
    }
    return result;
  }

  // ═══════════════ إحصاءات ═══════════════

  int get totalSurahs => quran_lib.totalSurahCount;    // 114
  int get totalVerses => quran_lib.totalVerseCount;    // 6236
  int get totalPages => quran_lib.totalPagesCount;     // 604

  /// هل المكتبة جاهزة؟ (دائماً true — البيانات مُضمَّنة)
  Future<bool> isPopulated() async => true;

  /// لا يوجد شيء لإغلاقه (لا SQLite)
  Future<void> close() async {}
}

// ─── دالة مساعدة: إزالة التشكيل ───
String _removeArabicDiacritics(String text) {
  return text.replaceAll(
    RegExp(r'[\u064B-\u065F\u0670\u0610-\u061A\u06D6-\u06DC\u06DF-\u06E4\u06E7-\u06E8\u06EA-\u06ED]'),
    '',
  );
}
