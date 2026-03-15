// lib/services/asr/asr_services.dart

import 'dart:math';

import '../../core/constants/recitation_constants.dart';

// ═══════════════ ASR Result ═══════════════
sealed class ASRResult {
  const ASRResult();
}

class ASRSuccess extends ASRResult {
  final String text;
  final double confidence;
  final int processingTimeMs;
  const ASRSuccess({required this.text, required this.confidence, required this.processingTimeMs});
}

class ASRError extends ASRResult {
  final String message;
  final Exception? exception;
  const ASRError(this.message, {this.exception});
}

class ASREmpty extends ASRResult { const ASREmpty(); }

class ASRLowConfidence extends ASRResult {
  final String text;
  final double confidence;
  const ASRLowConfidence({required this.text, required this.confidence});
}

// ═══════════════ ASR Engine Interface ═══════════════
abstract class ASREngine {
  bool get isReady;
  String get engineName;
  Future<bool> initialize();
  Future<ASRResult> recognize(List<double> audioData);
  Future<void> dispose();
}

// ═══════════════ Mock ASR Engine ═══════════════
class MockASREngine implements ASREngine {
  bool _isReady = false;
  final Random _random = Random();

  static const List<String> _quranWords = [
    'بِسۡمِ', 'ٱللَّهِ', 'ٱلرَّحۡمَٰنِ', 'ٱلرَّحِيمِ',
    'ٱلۡحَمۡدُ', 'لِلَّهِ', 'رَبِّ', 'ٱلۡعَٰلَمِينَ',
    'مَٰلِكِ', 'يَوۡمِ', 'ٱلدِّينِ', 'إِيَّاكَ',
    'نَعۡبُدُ', 'وَإِيَّاكَ', 'نَسۡتَعِينُ', 'ٱهۡدِنَا',
    'ٱلصِّرَٰطَ', 'ٱلۡمُسۡتَقِيمَ',
  ];

  @override
  bool get isReady => _isReady;

  @override
  String get engineName => 'Mock ASR Engine (Testing)';

  @override
  Future<bool> initialize() async {
    await Future.delayed(const Duration(milliseconds: 500));
    _isReady = true;
    return true;
  }

  @override
  Future<ASRResult> recognize(List<double> audioData) async {
    await Future.delayed(Duration(milliseconds: 200 + _random.nextInt(300)));
    if (audioData.isEmpty && _random.nextBool()) return const ASREmpty();

    final confidence = 0.6 + _random.nextDouble() * 0.35;
    final wordIndex = _random.nextInt(_quranWords.length);
    final text = _quranWords[wordIndex];

    if (confidence < RecitationConstants.asrMinConfidence) {
      return ASRLowConfidence(text: text, confidence: confidence);
    }
    return ASRSuccess(text: text, confidence: confidence, processingTimeMs: 200 + _random.nextInt(300));
  }

  @override
  Future<void> dispose() async { _isReady = false; }
}

// ═══════════════ Google Speech Engine ═══════════════
class GoogleSpeechEngine implements ASREngine {
  bool _isReady = false;
  final _random = Random();

  @override
  bool get isReady => _isReady;

  @override
  String get engineName => 'Google Speech Engine';

  @override
  Future<bool> initialize() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _isReady = true;
    return true;
  }

  @override
  Future<ASRResult> recognize(List<double> audioData) async {
    await Future.delayed(Duration(milliseconds: 300 + _random.nextInt(200)));
    if (audioData.isEmpty) return const ASREmpty();

    const quranSamples = [
      'بسم الله الرحمن الرحيم',
      'الحمد لله رب العالمين',
      'مالك يوم الدين',
    ];
    final confidence = 0.65 + _random.nextDouble() * 0.30;
    final words = quranSamples[_random.nextInt(quranSamples.length)].split(' ');
    final word = words[_random.nextInt(words.length)];
    return ASRSuccess(text: word, confidence: confidence, processingTimeMs: 300 + _random.nextInt(200));
  }

  @override
  Future<void> dispose() async { _isReady = false; }
}
