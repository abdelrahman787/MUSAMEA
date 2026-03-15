// lib/services/asr/asr_services.dart
// محرك التعرف على الصوت — حقيقي (speech_to_text) + محاكاة

import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_to_text.dart' show SpeechListenOptions;
import 'package:speech_to_text/speech_recognition_result.dart';
import '../../core/constants/recitation_constants.dart';

// ═══════════════ نتائج ASR (Sealed Classes) ═══════════════

sealed class ASRResult {
  const ASRResult();
}

class ASRSuccess extends ASRResult {
  final String text;
  final double confidence;
  final int processingTimeMs;
  const ASRSuccess({
    required this.text,
    required this.confidence,
    required this.processingTimeMs,
  });
}

class ASRError extends ASRResult {
  final String message;
  final Exception? exception;
  const ASRError(this.message, {this.exception});
}

class ASREmpty extends ASRResult {
  const ASREmpty();
}

class ASRLowConfidence extends ASRResult {
  final String text;
  final double confidence;
  const ASRLowConfidence({required this.text, required this.confidence});
}

// ═══════════════ واجهة محرك ASR ═══════════════

abstract class ASREngine {
  bool get isReady;
  String get engineName;
  Future<bool> initialize();
  Future<ASRResult> recognize(List<double> audioData);
  Future<void> dispose();
}

// ═══════════════ محرك الكلام الحقيقي (SpeechToTextEngine) ═══════════════

class SpeechToTextEngine implements ASREngine {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isReady = false;
  DateTime? _listenStart;

  // للتحكم في الاستماع الواحد
  Completer<ASRResult>? _activeCompleter;
  Timer? _listenTimeout;

  @override
  bool get isReady => _isReady;

  @override
  String get engineName => 'Speech To Text (ar-SA)';

  @override
  Future<bool> initialize() async {
    try {
      _isReady = await _speech.initialize(
        onError: (error) {
          if (kDebugMode) debugPrint('❌ STT Error: ${error.errorMsg}');
          _activeCompleter?.complete(ASRError(error.errorMsg));
          _activeCompleter = null;
          _listenTimeout?.cancel();
        },
        onStatus: (status) {
          if (kDebugMode) debugPrint('ℹ️ STT Status: $status');
          if (status == 'notListening' || status == 'done') {
            if (_activeCompleter != null && !_activeCompleter!.isCompleted) {
              _activeCompleter!.complete(const ASREmpty());
              _activeCompleter = null;
              _listenTimeout?.cancel();
            }
          }
        },
        debugLogging: kDebugMode,
      );
      if (kDebugMode) {
        debugPrint(_isReady
            ? '✅ SpeechToText initialized'
            : '⚠️ SpeechToText not available');
      }
      return _isReady;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ STT init error: $e');
      _isReady = false;
      return false;
    }
  }

  /// يبدأ الاستماع ويعود بالنتيجة فور انتهاء الكلام أو timeout 8 ثوانٍ
  @override
  Future<ASRResult> recognize(List<double> audioData) async {
    if (!_isReady) return const ASRError('المحرك غير مهيّأ');

    // إلغاء أي جلسة سابقة
    _listenTimeout?.cancel();
    _activeCompleter = Completer<ASRResult>();
    _listenStart = DateTime.now();

    try {
      await _speech.listen(
        localeId: 'ar-SA',
        listenFor: const Duration(seconds: 8),
        pauseFor: const Duration(milliseconds: 800),
        onResult: (SpeechRecognitionResult result) {
          if (!result.finalResult) return;

          final elapsed =
              DateTime.now().difference(_listenStart!).inMilliseconds;
          final text = result.recognizedWords.trim();
          final confidence = result.confidence > 0 ? result.confidence : 0.75;

          if (kDebugMode) debugPrint('🎤 STT result: "$text" (${confidence.toStringAsFixed(2)})');

          final asrResult = text.isEmpty
              ? const ASREmpty()
              : confidence < RecitationConstants.asrMinConfidence
                  ? ASRLowConfidence(text: text, confidence: confidence)
                  : ASRSuccess(
                      text: text,
                      confidence: confidence,
                      processingTimeMs: elapsed,
                    );

          if (_activeCompleter != null && !_activeCompleter!.isCompleted) {
            _activeCompleter!.complete(asrResult);
            _activeCompleter = null;
            _listenTimeout?.cancel();
          }
        },
        listenOptions: SpeechListenOptions(
          cancelOnError: true,
          partialResults: false,
        ),
      );

      // timeout إضافي للأمان (10 ثوانٍ)
      _listenTimeout = Timer(const Duration(seconds: 10), () {
        if (_activeCompleter != null && !_activeCompleter!.isCompleted) {
          _activeCompleter!.complete(const ASREmpty());
          _activeCompleter = null;
        }
      });

      return _activeCompleter!.future;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ STT listen error: $e');
      return ASRError('خطأ في التسجيل: $e');
    }
  }

  @override
  Future<void> dispose() async {
    _listenTimeout?.cancel();
    await _speech.stop();
    _isReady = false;
  }

  /// إيقاف الاستماع يدوياً (مثلاً عند الضغط على زر الإيقاف)
  Future<void> stopListening() async {
    _listenTimeout?.cancel();
    await _speech.stop();
  }

  /// هل المحرك يدعم العربية؟
  Future<bool> supportsArabic() async {
    final locales = await _speech.locales();
    return locales.any((l) => l.localeId.startsWith('ar'));
  }
}

// ═══════════════ محرك محاكاة للاختبار (MockASREngine) ═══════════════

class MockASREngine implements ASREngine {
  bool _isReady = false;
  final Random _random = Random();

  static const List<String> _quranWords = [
    'بِسْمِ', 'اللَّهِ', 'الرَّحْمَٰنِ', 'الرَّحِيمِ',
    'الْحَمْدُ', 'لِلَّهِ', 'رَبِّ', 'الْعَالَمِينَ',
    'مَالِكِ', 'يَوْمِ', 'الدِّينِ', 'إِيَّاكَ',
    'نَعْبُدُ', 'وَإِيَّاكَ', 'نَسْتَعِينُ', 'اهْدِنَا',
    'الصِّرَاطَ', 'الْمُسْتَقِيمَ', 'صِرَاطَ', 'الَّذِينَ',
  ];

  @override
  bool get isReady => _isReady;

  @override
  String get engineName => 'Mock ASR (للاختبار)';

  @override
  Future<bool> initialize() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _isReady = true;
    return true;
  }

  @override
  Future<ASRResult> recognize(List<double> audioData) async {
    await Future.delayed(Duration(milliseconds: 400 + _random.nextInt(400)));

    // احتمال 15% يرجع فارغاً
    if (_random.nextDouble() < 0.15) return const ASREmpty();

    final confidence = 0.65 + _random.nextDouble() * 0.30;
    final text = _quranWords[_random.nextInt(_quranWords.length)];

    if (confidence < RecitationConstants.asrMinConfidence) {
      return ASRLowConfidence(text: text, confidence: confidence);
    }
    return ASRSuccess(
      text: text,
      confidence: confidence,
      processingTimeMs: 400 + _random.nextInt(400),
    );
  }

  @override
  Future<void> dispose() async {
    _isReady = false;
  }
}

// ═══════════════ محرك احتياطي (FallbackASREngine) ═══════════════
// يُستخدم عند فشل SpeechToText (هواتف ضعيفة أو لا يدعم العربية)

class FallbackASREngine implements ASREngine {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isReady = false;
  Completer<ASRResult>? _activeCompleter;
  Timer? _timeout;
  DateTime? _listenStart;

  @override
  bool get isReady => _isReady;

  @override
  String get engineName => 'Fallback STT (عام)';

  @override
  Future<bool> initialize() async {
    try {
      _isReady = await _speech.initialize(debugLogging: false);
      return _isReady;
    } catch (_) {
      _isReady = false;
      return false;
    }
  }

  @override
  Future<ASRResult> recognize(List<double> audioData) async {
    if (!_isReady) return const ASRError('Fallback ASR غير متاح');
    _timeout?.cancel();
    _activeCompleter = Completer<ASRResult>();
    _listenStart = DateTime.now();

    try {
      await _speech.listen(
        listenFor: const Duration(seconds: 8),
        pauseFor: const Duration(milliseconds: 1000),
        onResult: (SpeechRecognitionResult result) {
          if (!result.finalResult) return;
          final elapsed =
              DateTime.now().difference(_listenStart!).inMilliseconds;
          final text = result.recognizedWords.trim();
          final confidence = result.confidence > 0 ? result.confidence : 0.7;
          final asrResult = text.isEmpty
              ? const ASREmpty()
              : ASRSuccess(
                  text: text,
                  confidence: confidence,
                  processingTimeMs: elapsed,
                );
          if (_activeCompleter != null && !_activeCompleter!.isCompleted) {
            _activeCompleter!.complete(asrResult);
            _activeCompleter = null;
            _timeout?.cancel();
          }
        },
        listenOptions: SpeechListenOptions(
          cancelOnError: true,
          partialResults: false,
        ),
      );
      _timeout = Timer(const Duration(seconds: 10), () {
        if (_activeCompleter != null && !_activeCompleter!.isCompleted) {
          _activeCompleter!.complete(const ASREmpty());
          _activeCompleter = null;
        }
      });
      return _activeCompleter!.future;
    } catch (e) {
      return ASRError('خطأ fallback: $e');
    }
  }

  @override
  Future<void> dispose() async {
    _timeout?.cancel();
    await _speech.stop();
    _isReady = false;
  }
}
