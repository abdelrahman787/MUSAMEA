// lib/presentation/screens/recitation/recitation_view_model.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../data/models/quran_word.dart';
import '../../../data/models/quran_verse.dart';
import '../../../data/local/db/quran_database.dart';
import '../../../data/local/db/app_database.dart';
import '../../../domain/models/domain_models.dart';
import '../../../services/text/quran_word_matcher.dart';
import '../../../services/audio/audio_service.dart';
import '../../../services/asr/asr_services.dart';
import '../../../core/constants/recitation_constants.dart';
import '../../../core/constants/quran_constants.dart';
import 'recitation_state.dart';

class RecitationViewModel extends ChangeNotifier {
  final QuranDatabase _quranDb;
  final AppDatabase _appDb;
  final QuranWordMatcher _wordMatcher;
  final AudioService _audioService;
  final ASREngine _asrEngine;

  RecitationUiState _state = const RecitationUiState();
  RecitationUiState get state => _state;

  // Timers
  Timer? _silenceTimer;
  Timer? _feedbackTimer;
  Timer? _progressTimer;
  DateTime? _sessionStartTime;
  DateTime? _wordDisplayTime;

  // Word attempt tracking
  final Map<String, int> _wordAttempts = {};

  // Audio subscriptions
  StreamSubscription? _audioSub;
  StreamSubscription? _vadSub;

  // For simulation
  Timer? _simTimer;

  RecitationViewModel({
    required QuranDatabase quranDb,
    required AppDatabase appDb,
    required QuranWordMatcher wordMatcher,
    required AudioService audioService,
    required ASREngine asrEngine,
  })  : _quranDb = quranDb,
        _appDb = appDb,
        _wordMatcher = wordMatcher,
        _audioService = audioService,
        _asrEngine = asrEngine;

  // ═══════════════ Session Management ═══════════════

  Future<void> startSession({
    required int pageNumber,
    required RecitationMode mode,
  }) async {
    // أظهر حالة التحميل فوراً
    _setState(_state.copyWith(
      isLoading: true,
      loadingMessage: 'جاري تحميل الصفحة $pageNumber…',
    ));
    notifyListeners();

    try {
      // تحميل بيانات الصفحة
      final words = await _quranDb.getPageWords(pageNumber);
      if (words.isEmpty) {
        _setState(_state.copyWith(
          isLoading: false,
          error: 'تعذّر تحميل بيانات الصفحة $pageNumber.\nتحقق من الاتصال بالإنترنت.',
        ));
        notifyListeners();
        return;
      }

      // بناء الصفحة
      final page = _buildPage(words, pageNumber);

      // إنشاء جلسة في قاعدة البيانات
      final now = DateTime.now().millisecondsSinceEpoch;
      final firstWord = words.first;
      final lastWord = words.last;
      final suraName = QuranConstants.getSuraName(firstWord.suraNumber);

      final sessionId = await _appDb.insertSession({
        'sura_number': firstWord.suraNumber,
        'sura_name': suraName,
        'start_aya': firstWord.ayaNumber,
        'end_aya': lastWord.ayaNumber,
        'start_page': pageNumber,
        'date_time_ms': now,
        'duration_seconds': 0,
        'total_words': words.length,
        'correct_words': 0,
        'forgotten_words': 0,
        'wrong_word_errors': 0,
        'diacritics_errors': 0,
        'accuracy_percent': 0.0,
        'mode': mode == RecitationMode.hidden
            ? RecitationConstants.modeHidden
            : RecitationConstants.modeVisible,
      });

      // تهيئة حالات الكلمات
      final wordStates = <String, WordDisplayState>{};
      for (int i = 0; i < words.length; i++) {
        final word = words[i];
        if (mode == RecitationMode.hidden) {
          wordStates[word.wordKey] = i == 0
              ? WordDisplayState.waiting
              : WordDisplayState.hidden;
        } else {
          wordStates[word.wordKey] = i == 0
              ? WordDisplayState.waiting
              : WordDisplayState.visibleHint;
        }
      }

      _sessionStartTime = DateTime.now();
      _wordDisplayTime = DateTime.now();

      _state = _state.copyWith(
        currentPage: page,
        wordStates: wordStates,
        currentWordKey: words.first.wordKey,
        sessionId: sessionId,
        mode: mode,
        isSessionStarted: true,
        isLoading: false,
        currentWordIndex: 0,
        allWords: words,
        sessionStats: const SessionStats(),
        clearError: true,
      );

      notifyListeners();
      _startProgressTimer();

      // بدء التسجيل الصوتي
      await _startAudioRecording();
    } catch (e) {
      _setState(_state.copyWith(
        isLoading: false,
        error: 'خطأ في بدء الجلسة: $e',
      ));
      notifyListeners();
      if (kDebugMode) debugPrint('❌ startSession error: $e');
    }
  }

  Future<void> _startAudioRecording() async {
    await _audioService.startRecording();

    // استمع لأحداث VAD
    _vadSub = _audioService.vadEvents.listen((event) {
      if (!event.isSpeech) {
        // صمت
        final silenceDuration = event.silenceDurationMs ?? 0;
        if (silenceDuration >= RecitationConstants.forgettingThresholdMs) {
          _onLongSilence(silenceDuration);
        }
      }
    });

    // استمع للصوت
    _audioSub = _audioService.stateStream.listen((audioState) {
      if (audioState == AudioState.speechDetected) {
        _onSpeechStart();
      } else if (audioState == AudioState.silenceDetected) {
        _onSpeechEnd();
      }
    });

    _setState(_state.copyWith(recordingPhase: RecordingPhase.recording));
  }

  void _onSpeechStart() {
    _silenceTimer?.cancel();
    _setState(_state.copyWith(
      recordingPhase: RecordingPhase.listening,
      silenceTimerMs: 0,
    ));
  }

  void _onSpeechEnd() {
    // معالجة الكلام
    _processSpokenWord();
  }

  void _onLongSilence(int durationMs) {
    if (_state.isSessionComplete || !_state.isSessionStarted) return;

    final currentWord = _state.currentWord;
    if (currentWord == null) return;

    // حدّث حالة الكلمة إلى FORGOTTEN
    final newStates = Map<String, WordDisplayState>.from(_state.wordStates);
    newStates[currentWord.wordKey] = WordDisplayState.forgotten;

    // في وضع الظهور: أظهر الكلمة كتلميح
    if (_state.mode == RecitationMode.visible) {
      newStates[currentWord.wordKey] = WordDisplayState.visibleHint;
    }

    // أظهر تغذية راجعة
    final feedback = FeedbackState(
      type: FeedbackType.forgotten,
      expectedWord: currentWord.textUthmani,
      spokenWord: null,
      message: '⏸ توقفتَ عند: ${currentWord.textUthmani}',
      createdAt: DateTime.now(),
    );

    // حدّث الإحصاءات
    final newStats = _state.sessionStats.copyWith(
      forgottenWords: _state.sessionStats.forgottenWords + 1,
      totalWords: _state.sessionStats.totalWords,
    );

    _setState(_state.copyWith(
      wordStates: newStates,
      feedback: feedback,
      sessionStats: newStats,
    ));

    // سجّل في قاعدة البيانات
    _saveWordEvent(
      word: currentWord,
      errorType: ErrorType.forgotten,
      spokenWord: null,
      delayMs: _getWordDelay(),
      confidence: 0.0,
    );

    // ابدأ مؤقت الإخفاء التلقائي للتغذية الراجعة
    _startFeedbackTimer();

    notifyListeners();
  }

  Future<void> _processSpokenWord() async {
    final currentWord = _state.currentWord;
    if (currentWord == null) return;

    _setState(_state.copyWith(recordingPhase: RecordingPhase.processing));

    try {
      // في الوضع الحقيقي: نأخذ بيانات الصوت المُسجَّلة
      // هنا: نستخدم محرك ASR مُحاكى
      final asrResult = await _asrEngine.recognize([]);
      final delayMs = _getWordDelay();

      if (asrResult is ASRSuccess) {
        _onWordRecognized(
          text: asrResult.text,
          confidence: asrResult.confidence,
          delayMs: delayMs,
        );
      } else if (asrResult is ASRLowConfidence) {
        // ثقة منخفضة - تجاهل أو انتظر
        _setState(_state.copyWith(recordingPhase: RecordingPhase.recording));
      } else {
        _setState(_state.copyWith(recordingPhase: RecordingPhase.recording));
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ ASR error: $e');
      _setState(_state.copyWith(recordingPhase: RecordingPhase.recording));
    }
  }

  void _onWordRecognized({
    required String text,
    required double confidence,
    required int delayMs,
  }) {
    final currentWord = _state.currentWord;
    if (currentWord == null) return;

    // تحقق من الحد الأدنى للثقة
    if (confidence < RecitationConstants.asrMinConfidence) {
      _setState(_state.copyWith(recordingPhase: RecordingPhase.recording));
      return;
    }

    final matchResult = _wordMatcher.matchWord(currentWord.textUthmani, text);
    final newStates = Map<String, WordDisplayState>.from(_state.wordStates);

    switch (matchResult) {
      case MatchCorrect():
        // ✅ صحيح
        newStates[currentWord.wordKey] = WordDisplayState.correct;
        final newStats = _state.sessionStats.copyWith(
          correctWords: _state.sessionStats.correctWords + 1,
          totalWords: _state.sessionStats.totalWords + 1,
        );
        _saveWordEvent(
          word: currentWord,
          errorType: ErrorType.correct,
          spokenWord: text,
          delayMs: delayMs,
          confidence: confidence,
        );
        _setState(_state.copyWith(
          wordStates: newStates,
          sessionStats: newStats,
          recordingPhase: RecordingPhase.recording,
        ));
        _advanceToNextWord();

      case MatchWrongDiacritics():
        // 🟠 تشكيل خاطئ
        newStates[currentWord.wordKey] = WordDisplayState.wrongDiacritics;
        final feedback = FeedbackState(
          type: FeedbackType.wrongDiac,
          expectedWord: currentWord.textUthmani,
          spokenWord: text,
          message: 'تشكيل خاطئ: قلتَ [$text] والصواب [${currentWord.textUthmani}]',
          createdAt: DateTime.now(),
        );
        final newStats = _state.sessionStats.copyWith(
          diacriticsErrors: _state.sessionStats.diacriticsErrors + 1,
          totalWords: _state.sessionStats.totalWords + 1,
        );
        _saveWordEvent(
          word: currentWord,
          errorType: ErrorType.wrongDiacritics,
          spokenWord: text,
          delayMs: delayMs,
          confidence: confidence,
        );
        _saveWeakWord(word: currentWord, errorType: ErrorType.wrongDiacritics);
        _setState(_state.copyWith(
          wordStates: newStates,
          feedback: feedback,
          sessionStats: newStats,
          recordingPhase: RecordingPhase.recording,
        ));
        // انتقل بعد 2 ثانية
        Future.delayed(
          Duration(milliseconds: RecitationConstants.wrongDiacAdvanceDelayMs),
          _advanceToNextWord,
        );
        _startFeedbackTimer();

      case MatchWrongWord():
        // 🔴 كلمة خاطئة
        final attempts = (_wordAttempts[currentWord.wordKey] ?? 0) + 1;
        _wordAttempts[currentWord.wordKey] = attempts;
        newStates[currentWord.wordKey] = WordDisplayState.wrongWord;
        final feedback = FeedbackState(
          type: FeedbackType.wrongWord,
          expectedWord: currentWord.textUthmani,
          spokenWord: text,
          message: '❌ قلتَ: [$text] — انتظر الكلمة الصحيحة',
          createdAt: DateTime.now(),
        );
        final newStats = _state.sessionStats.copyWith(
          wrongWordErrors: _state.sessionStats.wrongWordErrors + 1,
        );
        _saveWordEvent(
          word: currentWord,
          errorType: ErrorType.wrongWord,
          spokenWord: text,
          delayMs: delayMs,
          confidence: confidence,
        );
        _saveWeakWord(word: currentWord, errorType: ErrorType.wrongWord);
        _setState(_state.copyWith(
          wordStates: newStates,
          feedback: feedback,
          sessionStats: newStats,
          recordingPhase: RecordingPhase.recording,
        ));
        _startFeedbackTimer();

        // تخطي تلقائي بعد أقصى محاولات
        if (attempts >= RecitationConstants.maxAttemptsPerWord) {
          Future.delayed(const Duration(seconds: 1), skipCurrentWord);
        }

      case MatchForgotten():
        _setState(_state.copyWith(recordingPhase: RecordingPhase.recording));

      case MatchTooSilent():
        _setState(_state.copyWith(recordingPhase: RecordingPhase.recording));
    }

    notifyListeners();
  }

  void _advanceToNextWord() {
    final nextIndex = _state.currentWordIndex + 1;
    if (nextIndex >= _state.allWords.length) {
      // اكتملت الجلسة
      _completeSession();
      return;
    }

    final nextWord = _state.allWords[nextIndex];
    final newStates = Map<String, WordDisplayState>.from(_state.wordStates);

    // أظهر الكلمة التالية كـ WAITING
    newStates[nextWord.wordKey] = WordDisplayState.waiting;

    _wordDisplayTime = DateTime.now();
    _wordAttempts.remove(nextWord.wordKey);

    _setState(_state.copyWith(
      currentWordKey: nextWord.wordKey,
      currentWordIndex: nextIndex,
      wordStates: newStates,
    ));

    notifyListeners();
  }

  void skipCurrentWord() {
    final currentWord = _state.currentWord;
    if (currentWord == null) return;

    final newStates = Map<String, WordDisplayState>.from(_state.wordStates);
    newStates[currentWord.wordKey] = WordDisplayState.skipped;

    _saveWordEvent(
      word: currentWord,
      errorType: ErrorType.skipped,
      spokenWord: null,
      delayMs: _getWordDelay(),
      confidence: 0.0,
    );

    final newStats = _state.sessionStats.copyWith(
      skippedWords: _state.sessionStats.skippedWords + 1,
    );

    _setState(_state.copyWith(
      wordStates: newStates,
      sessionStats: newStats,
      clearFeedback: true,
    ));
    _advanceToNextWord();
  }

  void showHint() {
    final currentWord = _state.currentWord;
    if (currentWord == null) return;

    final newStates = Map<String, WordDisplayState>.from(_state.wordStates);
    newStates[currentWord.wordKey] = WordDisplayState.visibleHint;

    _setState(_state.copyWith(wordStates: newStates));
    notifyListeners();
  }

  void dismissFeedback() {
    _feedbackTimer?.cancel();
    _setState(_state.copyWith(clearFeedback: true));
    notifyListeners();
  }

  void toggleMode() {
    final newMode = _state.mode == RecitationMode.hidden
        ? RecitationMode.visible
        : RecitationMode.hidden;
    _setState(_state.copyWith(mode: newMode));
    notifyListeners();
  }

  // ═══════════════ Session Completion ═══════════════

  Future<void> _completeSession() async {
    final sessionId = _state.sessionId;
    if (sessionId == null) return;

    await stopRecording();

    final duration = _sessionStartTime != null
        ? DateTime.now().difference(_sessionStartTime!).inSeconds
        : 0;

    final stats = _state.sessionStats;
    final totalWords = stats.correctWords + stats.forgottenWords +
        stats.wrongWordErrors + stats.diacriticsErrors + stats.skippedWords;
    final accuracy = totalWords > 0
        ? (stats.correctWords / totalWords) * 100.0
        : 0.0;

    await _appDb.updateSession(sessionId, {
      'duration_seconds': duration,
      'total_words': totalWords,
      'correct_words': stats.correctWords,
      'forgotten_words': stats.forgottenWords,
      'wrong_word_errors': stats.wrongWordErrors,
      'diacritics_errors': stats.diacriticsErrors,
      'accuracy_percent': accuracy,
      'end_aya': _state.allWords.isNotEmpty
          ? _state.allWords.last.ayaNumber
          : 0,
    });

    _setState(_state.copyWith(isSessionComplete: true));
    notifyListeners();
  }

  Future<void> stopRecording() async {
    _silenceTimer?.cancel();
    _feedbackTimer?.cancel();
    _progressTimer?.cancel();
    _simTimer?.cancel();
    await _audioSub?.cancel();
    await _vadSub?.cancel();
    await _audioService.stopRecording();
    _setState(_state.copyWith(recordingPhase: RecordingPhase.idle));
  }

  Future<void> endSession() async {
    await stopRecording();
    _wordAttempts.clear();
    _setState(const RecitationUiState());
    notifyListeners();
  }

  // ═══════════════ Database Operations ═══════════════

  Future<void> _saveWordEvent({
    required QuranWord word,
    required ErrorType errorType,
    required String? spokenWord,
    required int delayMs,
    required double confidence,
  }) async {
    final sessionId = _state.sessionId;
    if (sessionId == null) return;

    await _appDb.insertWordEvent({
      'session_id': sessionId,
      'sura_number': word.suraNumber,
      'aya_number': word.ayaNumber,
      'word_position': word.wordPosition,
      'expected_word_uthmani': word.textUthmani,
      'expected_word_simple': word.textSimple,
      'spoken_word': spokenWord,
      'error_type': errorType.dbValue,
      'delay_before_speaking_ms': delayMs,
      'asr_confidence': confidence,
      'attempts_count': _wordAttempts[word.wordKey] ?? 1,
    });
  }

  Future<void> _saveWeakWord({
    required QuranWord word,
    required ErrorType errorType,
  }) async {
    final suraName = QuranConstants.getSuraName(word.suraNumber);
    await _appDb.upsertWeakWord({
      'word_key': word.wordKey,
      'sura_number': word.suraNumber,
      'sura_name': suraName,
      'aya_number': word.ayaNumber,
      'word_position': word.wordPosition,
      'word_text': word.textUthmani,
      'forgotten_count': errorType == ErrorType.forgotten ? 1 : 0,
      'wrong_word_count': errorType == ErrorType.wrongWord ? 1 : 0,
      'diacritics_error_count': errorType == ErrorType.wrongDiacritics ? 1 : 0,
      'last_error_date_ms': DateTime.now().millisecondsSinceEpoch,
      'last_error_type': errorType.dbValue,
    });
  }

  // ═══════════════ Timers ═══════════════

  void _startFeedbackTimer() {
    _feedbackTimer?.cancel();
    _feedbackTimer = Timer(
      const Duration(milliseconds: RecitationConstants.feedbackDisplayMs),
      dismissFeedback,
    );
  }

  void _startProgressTimer() {
    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => notifyListeners(),
    );
  }

  int _getWordDelay() {
    if (_wordDisplayTime == null) return 0;
    return DateTime.now().difference(_wordDisplayTime!).inMilliseconds;
  }

  // ═══════════════ Simulation Methods (for testing) ═══════════════

  /// محاكاة نطق الكلمة الحالية صحيحاً (للاختبار)
  void simulateCorrectWord() {
    final currentWord = _state.currentWord;
    if (currentWord == null) return;
    _onWordRecognized(
      text: currentWord.textUthmani,
      confidence: 0.95,
      delayMs: 1000,
    );
  }

  /// محاكاة خطأ في التشكيل (للاختبار)
  void simulateDiacriticsError() {
    final currentWord = _state.currentWord;
    if (currentWord == null) return;
    final simple = currentWord.textSimple;
    _onWordRecognized(text: simple, confidence: 0.90, delayMs: 1200);
  }

  /// محاكاة كلمة خاطئة (للاختبار)
  void simulateWrongWord() {
    _onWordRecognized(text: 'كلمة', confidence: 0.85, delayMs: 1500);
  }

  /// محاكاة صمت طويل (للاختبار)
  void simulateForgetting() {
    _onLongSilence(RecitationConstants.forgettingThresholdMs + 500);
  }

  // ═══════════════ Helper ═══════════════

  QuranPage _buildPage(List<QuranWord> words, int pageNumber) {
    final Map<String, List<QuranWord>> verseMap = {};
    for (final word in words) {
      verseMap.putIfAbsent(word.verseKey, () => []).add(word);
    }
    final verses = verseMap.entries
        .map((entry) => QuranVerse.fromWords(entry.value))
        .toList();
    return QuranPage(
      pageNumber: pageNumber,
      verses: verses,
      allWords: words,
    );
  }

  void _setState(RecitationUiState newState) {
    _state = newState;
  }

  @override
  void dispose() {
    endSession();
    _silenceTimer?.cancel();
    _feedbackTimer?.cancel();
    _progressTimer?.cancel();
    _simTimer?.cancel();
    super.dispose();
  }
}
