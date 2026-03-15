// lib/data/models/quran_verse.dart

import 'quran_word.dart';

class QuranVerse {
  final int suraNumber;
  final int ayaNumber;
  final String verseKey;
  final String textUthmani;
  final List<QuranWord> words;
  final int pageNumber;
  final int juzNumber;

  const QuranVerse({
    required this.suraNumber,
    required this.ayaNumber,
    required this.verseKey,
    required this.textUthmani,
    required this.words,
    required this.pageNumber,
    required this.juzNumber,
  });

  factory QuranVerse.fromWords(List<QuranWord> words) {
    if (words.isEmpty) {
      return const QuranVerse(
        suraNumber: 0, ayaNumber: 0, verseKey: '',
        textUthmani: '', words: [], pageNumber: 0, juzNumber: 0,
      );
    }
    final first = words.first;
    final text = words.map((w) => w.textUthmani).join(' ');
    return QuranVerse(
      suraNumber: first.suraNumber,
      ayaNumber: first.ayaNumber,
      verseKey: first.verseKey,
      textUthmani: text,
      words: words,
      pageNumber: first.pageNumber,
      juzNumber: 0,
    );
  }

  int get wordCount => words.length;

  @override
  String toString() => 'QuranVerse($verseKey: $textUthmani)';
}

// ═══════════════ QuranPage ═══════════════
class QuranPage {
  final int pageNumber;
  final List<QuranVerse> verses;
  final List<QuranWord> allWords;

  const QuranPage({
    required this.pageNumber,
    required this.verses,
    required this.allWords,
  });

  QuranWord? getWordByKey(String wordKey) {
    try {
      return allWords.firstWhere((w) => w.wordKey == wordKey);
    } catch (_) {
      return null;
    }
  }

  int get totalWordCount => allWords.length;

  @override
  String toString() =>
      'QuranPage($pageNumber: ${verses.length} verses, $totalWordCount words)';
}
