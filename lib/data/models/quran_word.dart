// lib/data/models/quran_word.dart

class QuranWord {
  final int id;
  final String verseKey;   // مثل "1:1"
  final int suraNumber;
  final int ayaNumber;
  final int wordPosition;  // ترتيب الكلمة في الآية (0-based)
  final String textUthmani;  // النص العثماني المشكل
  final String textSimple;   // النص بدون تشكيل
  final int pageNumber;
  final int lineNumber;
  final bool isLastInAya;

  const QuranWord({
    required this.id,
    required this.verseKey,
    required this.suraNumber,
    required this.ayaNumber,
    required this.wordPosition,
    required this.textUthmani,
    required this.textSimple,
    required this.pageNumber,
    required this.lineNumber,
    required this.isLastInAya,
  });

  String get wordKey => '${suraNumber}_${ayaNumber}_$wordPosition';

  factory QuranWord.fromMap(Map<String, dynamic> map) {
    return QuranWord(
      id: map['id'] as int? ?? 0,
      verseKey: map['verse_key'] as String? ?? '',
      suraNumber: map['sura_number'] as int? ?? 0,
      ayaNumber: map['aya_number'] as int? ?? 0,
      wordPosition: map['word_position'] as int? ?? 0,
      textUthmani: map['text_uthmani'] as String? ?? '',
      textSimple: map['text_simple'] as String? ?? '',
      pageNumber: map['page_number'] as int? ?? 1,
      lineNumber: map['line_number'] as int? ?? 1,
      isLastInAya: (map['is_last_in_aya'] as int? ?? 0) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'verse_key': verseKey,
      'sura_number': suraNumber,
      'aya_number': ayaNumber,
      'word_position': wordPosition,
      'text_uthmani': textUthmani,
      'text_simple': textSimple,
      'page_number': pageNumber,
      'line_number': lineNumber,
      'is_last_in_aya': isLastInAya ? 1 : 0,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuranWord && runtimeType == other.runtimeType && wordKey == other.wordKey;

  @override
  int get hashCode => wordKey.hashCode;

  @override
  String toString() =>
      'QuranWord($verseKey:$wordPosition → $textUthmani)';
}
