// lib/domain/models/domain_models.dart
// جميع نماذج المجال في ملف واحد

// ═══════════════ Error Type ═══════════════
enum ErrorType {
  correct,
  wrongWord,
  wrongDiacritics,
  forgotten,
  skipped;

  String get arabicName {
    switch (this) {
      case ErrorType.correct: return 'صحيح';
      case ErrorType.wrongWord: return 'كلمة خاطئة';
      case ErrorType.wrongDiacritics: return 'خطأ تشكيل';
      case ErrorType.forgotten: return 'منسي';
      case ErrorType.skipped: return 'متخطى';
    }
  }

  String get dbValue {
    switch (this) {
      case ErrorType.correct: return 'CORRECT';
      case ErrorType.wrongWord: return 'WRONG_WORD';
      case ErrorType.wrongDiacritics: return 'WRONG_DIACRITICS';
      case ErrorType.forgotten: return 'FORGOTTEN';
      case ErrorType.skipped: return 'SKIPPED';
    }
  }

  static ErrorType fromDbValue(String value) {
    switch (value) {
      case 'CORRECT': return ErrorType.correct;
      case 'WRONG_WORD': return ErrorType.wrongWord;
      case 'WRONG_DIACRITICS': return ErrorType.wrongDiacritics;
      case 'FORGOTTEN': return ErrorType.forgotten;
      case 'SKIPPED': return ErrorType.skipped;
      default: return ErrorType.correct;
    }
  }
}

// ═══════════════ Word Event ═══════════════
class WordEvent {
  final int? id;
  final int sessionId;
  final int suraNumber;
  final int ayaNumber;
  final int wordPosition;
  final String expectedWordUthmani;
  final String expectedWordSimple;
  final String? spokenWord;
  final ErrorType errorType;
  final int delayBeforeSpeakingMs;
  final double asrConfidence;
  final int attemptsCount;

  const WordEvent({
    this.id,
    required this.sessionId,
    required this.suraNumber,
    required this.ayaNumber,
    required this.wordPosition,
    required this.expectedWordUthmani,
    required this.expectedWordSimple,
    this.spokenWord,
    required this.errorType,
    required this.delayBeforeSpeakingMs,
    required this.asrConfidence,
    this.attemptsCount = 1,
  });

  String get wordKey => '${suraNumber}_${ayaNumber}_$wordPosition';

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'session_id': sessionId,
    'sura_number': suraNumber,
    'aya_number': ayaNumber,
    'word_position': wordPosition,
    'expected_word_uthmani': expectedWordUthmani,
    'expected_word_simple': expectedWordSimple,
    'spoken_word': spokenWord,
    'error_type': errorType.dbValue,
    'delay_before_speaking_ms': delayBeforeSpeakingMs,
    'asr_confidence': asrConfidence,
    'attempts_count': attemptsCount,
  };

  factory WordEvent.fromMap(Map<String, dynamic> map) => WordEvent(
    id: map['id'] as int?,
    sessionId: map['session_id'] as int,
    suraNumber: map['sura_number'] as int,
    ayaNumber: map['aya_number'] as int,
    wordPosition: map['word_position'] as int,
    expectedWordUthmani: map['expected_word_uthmani'] as String,
    expectedWordSimple: map['expected_word_simple'] as String,
    spokenWord: map['spoken_word'] as String?,
    errorType: ErrorType.fromDbValue(map['error_type'] as String? ?? 'CORRECT'),
    delayBeforeSpeakingMs: map['delay_before_speaking_ms'] as int? ?? 0,
    asrConfidence: (map['asr_confidence'] as num?)?.toDouble() ?? 0.0,
    attemptsCount: map['attempts_count'] as int? ?? 1,
  );
}

// ═══════════════ Session Stats ═══════════════
class SessionStats {
  final int totalWords;
  final int correctWords;
  final int forgottenWords;
  final int wrongWordErrors;
  final int diacriticsErrors;
  final int skippedWords;

  const SessionStats({
    this.totalWords = 0,
    this.correctWords = 0,
    this.forgottenWords = 0,
    this.wrongWordErrors = 0,
    this.diacriticsErrors = 0,
    this.skippedWords = 0,
  });

  int get totalErrors => forgottenWords + wrongWordErrors + diacriticsErrors + skippedWords;

  double get accuracyPercent {
    if (totalWords == 0) return 0.0;
    return (correctWords / totalWords) * 100.0;
  }

  SessionStats copyWith({
    int? totalWords,
    int? correctWords,
    int? forgottenWords,
    int? wrongWordErrors,
    int? diacriticsErrors,
    int? skippedWords,
  }) {
    return SessionStats(
      totalWords: totalWords ?? this.totalWords,
      correctWords: correctWords ?? this.correctWords,
      forgottenWords: forgottenWords ?? this.forgottenWords,
      wrongWordErrors: wrongWordErrors ?? this.wrongWordErrors,
      diacriticsErrors: diacriticsErrors ?? this.diacriticsErrors,
      skippedWords: skippedWords ?? this.skippedWords,
    );
  }
}

// ═══════════════ Recitation Session ═══════════════
class RecitationSession {
  final int? id;
  final int suraNumber;
  final String suraName;
  final int startAya;
  final int endAya;
  final int startPage;
  final int dateTimeMs;
  final int durationSeconds;
  final int totalWords;
  final int correctWords;
  final int forgottenWords;
  final int wrongWordErrors;
  final int diacriticsErrors;
  final double accuracyPercent;
  final String mode;

  const RecitationSession({
    this.id,
    required this.suraNumber,
    required this.suraName,
    required this.startAya,
    required this.endAya,
    required this.startPage,
    required this.dateTimeMs,
    required this.durationSeconds,
    required this.totalWords,
    required this.correctWords,
    required this.forgottenWords,
    required this.wrongWordErrors,
    required this.diacriticsErrors,
    required this.accuracyPercent,
    required this.mode,
  });

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'sura_number': suraNumber,
    'sura_name': suraName,
    'start_aya': startAya,
    'end_aya': endAya,
    'start_page': startPage,
    'date_time_ms': dateTimeMs,
    'duration_seconds': durationSeconds,
    'total_words': totalWords,
    'correct_words': correctWords,
    'forgotten_words': forgottenWords,
    'wrong_word_errors': wrongWordErrors,
    'diacritics_errors': diacriticsErrors,
    'accuracy_percent': accuracyPercent,
    'mode': mode,
  };

  factory RecitationSession.fromMap(Map<String, dynamic> map) => RecitationSession(
    id: map['id'] as int?,
    suraNumber: map['sura_number'] as int,
    suraName: map['sura_name'] as String,
    startAya: map['start_aya'] as int,
    endAya: map['end_aya'] as int,
    startPage: map['start_page'] as int? ?? 1,
    dateTimeMs: map['date_time_ms'] as int,
    durationSeconds: map['duration_seconds'] as int? ?? 0,
    totalWords: map['total_words'] as int? ?? 0,
    correctWords: map['correct_words'] as int? ?? 0,
    forgottenWords: map['forgotten_words'] as int? ?? 0,
    wrongWordErrors: map['wrong_word_errors'] as int? ?? 0,
    diacriticsErrors: map['diacritics_errors'] as int? ?? 0,
    accuracyPercent: (map['accuracy_percent'] as num?)?.toDouble() ?? 0.0,
    mode: map['mode'] as String? ?? 'HIDDEN',
  );
}

// ═══════════════ Weak Point ═══════════════
class WeakPoint {
  final String wordKey;
  final int suraNumber;
  final String suraName;
  final int ayaNumber;
  final int wordPosition;
  final String wordText;
  final int forgottenCount;
  final int wrongWordCount;
  final int diacriticsErrorCount;
  final int totalErrorCount;
  final int lastErrorDateMs;
  final String lastErrorType;

  const WeakPoint({
    required this.wordKey,
    required this.suraNumber,
    required this.suraName,
    required this.ayaNumber,
    required this.wordPosition,
    required this.wordText,
    required this.forgottenCount,
    required this.wrongWordCount,
    required this.diacriticsErrorCount,
    required this.totalErrorCount,
    required this.lastErrorDateMs,
    required this.lastErrorType,
  });

  factory WeakPoint.fromMap(Map<String, dynamic> map) => WeakPoint(
    wordKey: map['word_key'] as String? ?? '${map['sura_number']}_${map['aya_number']}_${map['word_position']}',
    suraNumber: map['sura_number'] as int,
    suraName: map['sura_name'] as String? ?? '',
    ayaNumber: map['aya_number'] as int,
    wordPosition: map['word_position'] as int,
    wordText: map['word_text'] as String? ?? map['expected_word_uthmani'] as String? ?? '',
    forgottenCount: map['forgotten_count'] as int? ?? 0,
    wrongWordCount: map['wrong_word_count'] as int? ?? 0,
    diacriticsErrorCount: map['diacritics_error_count'] as int? ?? map['diac_count'] as int? ?? 0,
    totalErrorCount: map['total_error_count'] as int? ?? map['total_errors'] as int? ?? 0,
    lastErrorDateMs: map['last_error_date_ms'] as int? ?? 0,
    lastErrorType: map['last_error_type'] as String? ?? '',
  );

  String get verseRef => '$suraName ($suraNumber:$ayaNumber)';
}
