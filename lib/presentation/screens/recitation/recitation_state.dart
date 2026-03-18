// lib/presentation/screens/recitation/recitation_state.dart

import '../../../data/models/quran_word.dart';
import '../../../data/models/quran_verse.dart';
import '../../../domain/models/domain_models.dart';

/// حالات عرض الكلمة
enum WordDisplayState {
  hidden,         // مخفية
  waiting,        // الكلمة التالية المنتظرة
  correct,        // صحيح (أخضر)
  wrongDiacritics,// تشكيل خاطئ (برتقالي)
  wrongWord,      // كلمة خاطئة (أحمر)
  forgotten,      // نسيان (أحمر غامق)
  visibleHint,    // تلميح (رمادي)
  skipped,        // متخطى
}

enum RecitationMode { hidden, visible }

enum RecordingPhase { idle, recording, listening, processing }

enum FeedbackType { success, wrongWord, wrongDiac, forgotten, skipped }

class FeedbackState {
  final FeedbackType type;
  final String expectedWord;
  final String? spokenWord;
  final String message;
  final int durationMs;
  final DateTime createdAt;

  const FeedbackState({
    required this.type,
    required this.expectedWord,
    this.spokenWord,
    required this.message,
    this.durationMs = 2500,
    required this.createdAt,
  });
}

class RecitationUiState {
  final QuranPage? currentPage;
  final Map<String, WordDisplayState> wordStates;
  final String? currentWordKey;
  final RecordingPhase recordingPhase;
  final RecitationMode mode;
  final int silenceTimerMs;
  final int? sessionId;
  final FeedbackState? feedback;
  final SessionStats sessionStats;
  final bool isSessionComplete;
  final bool isSessionStarted;
  final bool isLoading;        // true أثناء تحميل بيانات الصفحة من API
  final String? loadingMessage;// رسالة التحميل
  final String? error;
  final int currentWordIndex;
  final List<QuranWord> allWords;

  const RecitationUiState({
    this.currentPage,
    this.wordStates = const {},
    this.currentWordKey,
    this.recordingPhase = RecordingPhase.idle,
    this.mode = RecitationMode.hidden,
    this.silenceTimerMs = 0,
    this.sessionId,
    this.feedback,
    this.sessionStats = const SessionStats(),
    this.isSessionComplete = false,
    this.isSessionStarted = false,
    this.isLoading = false,
    this.loadingMessage,
    this.error,
    this.currentWordIndex = 0,
    this.allWords = const [],
  });

  bool get isRecording => recordingPhase != RecordingPhase.idle;
  bool get isListening => recordingPhase == RecordingPhase.listening;
  bool get isProcessing => recordingPhase == RecordingPhase.processing;

  QuranWord? get currentWord {
    if (currentWordIndex >= 0 && currentWordIndex < allWords.length) {
      return allWords[currentWordIndex];
    }
    return null;
  }

  double get progressPercent {
    if (allWords.isEmpty) return 0.0;
    return currentWordIndex / allWords.length;
  }

  RecitationUiState copyWith({
    QuranPage? currentPage,
    Map<String, WordDisplayState>? wordStates,
    String? currentWordKey,
    RecordingPhase? recordingPhase,
    RecitationMode? mode,
    int? silenceTimerMs,
    int? sessionId,
    FeedbackState? feedback,
    bool clearFeedback = false,
    SessionStats? sessionStats,
    bool? isSessionComplete,
    bool? isSessionStarted,
    bool? isLoading,
    String? loadingMessage,
    String? error,
    bool clearError = false,
    int? currentWordIndex,
    List<QuranWord>? allWords,
  }) {
    return RecitationUiState(
      currentPage: currentPage ?? this.currentPage,
      wordStates: wordStates ?? this.wordStates,
      currentWordKey: currentWordKey ?? this.currentWordKey,
      recordingPhase: recordingPhase ?? this.recordingPhase,
      mode: mode ?? this.mode,
      silenceTimerMs: silenceTimerMs ?? this.silenceTimerMs,
      sessionId: sessionId ?? this.sessionId,
      feedback: clearFeedback ? null : (feedback ?? this.feedback),
      sessionStats: sessionStats ?? this.sessionStats,
      isSessionComplete: isSessionComplete ?? this.isSessionComplete,
      isSessionStarted: isSessionStarted ?? this.isSessionStarted,
      isLoading: isLoading ?? this.isLoading,
      loadingMessage: loadingMessage ?? this.loadingMessage,
      error: clearError ? null : (error ?? this.error),
      currentWordIndex: currentWordIndex ?? this.currentWordIndex,
      allWords: allWords ?? this.allWords,
    );
  }
}
