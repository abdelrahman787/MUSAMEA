// lib/services/audio/audio_service.dart
// خدمة الصوت مع VAD (Voice Activity Detection)

import 'dart:async';
import 'dart:math';

import '../../core/constants/recitation_constants.dart';

enum AudioState {
  idle,
  recording,
  speechDetected,
  silenceDetected,
  processing,
}

class AudioChunk {
  final List<double> pcmData;
  final int timestamp;
  final double energy;

  const AudioChunk({
    required this.pcmData,
    required this.timestamp,
    required this.energy,
  });
}

class VADEvent {
  final bool isSpeech;
  final double energy;
  final int timestamp;
  final int? silenceDurationMs;

  const VADEvent({
    required this.isSpeech,
    required this.energy,
    required this.timestamp,
    this.silenceDurationMs,
  });
}

/// خدمة الصوت المُحاكاة للواجهة
/// في الإنتاج: تستخدم AudioRecord API مع Silero VAD
class AudioService {
  static AudioService? _instance;
  static AudioService get instance {
    _instance ??= AudioService._();
    return _instance!;
  }

  AudioService._();

  AudioState _state = AudioState.idle;
  Timer? _recordingTimer;
  Timer? _silenceTimer;
  Timer? _speechSimTimer;

  final _audioChunkController = StreamController<AudioChunk>.broadcast();
  final _vadEventController = StreamController<VADEvent>.broadcast();
  final _stateController = StreamController<AudioState>.broadcast();

  Stream<AudioChunk> get audioChunks => _audioChunkController.stream;
  Stream<VADEvent> get vadEvents => _vadEventController.stream;
  Stream<AudioState> get stateStream => _stateController.stream;

  AudioState get currentState => _state;
  bool get isRecording => _state != AudioState.idle;

  final Random _random = Random();
  int _lastSpeechTime = 0;
  bool _isInSpeech = false;

  /// بدء التسجيل
  Future<bool> startRecording() async {
    if (_state != AudioState.idle) return false;

    _setState(AudioState.recording);
    _lastSpeechTime = DateTime.now().millisecondsSinceEpoch;
    _isInSpeech = false;

    // محاكاة استقبال chunks صوتية
    _recordingTimer = Timer.periodic(
      const Duration(milliseconds: 256), // 4096 samples / 16000 Hz ≈ 256ms
      _onAudioChunk,
    );

    return true;
  }

  /// إيقاف التسجيل
  Future<void> stopRecording() async {
    _recordingTimer?.cancel();
    _silenceTimer?.cancel();
    _speechSimTimer?.cancel();
    _recordingTimer = null;
    _silenceTimer = null;
    _speechSimTimer = null;
    _isInSpeech = false;
    _setState(AudioState.idle);
  }

  void _onAudioChunk(Timer timer) {
    if (_state == AudioState.idle) return;

    // محاكاة بيانات PCM
    final pcmData = List.generate(
      RecitationConstants.audioBufferSize,
      (i) => (_random.nextDouble() * 2 - 1) * 0.1, // ضوضاء منخفضة
    );

    final energy = _calculateEnergy(pcmData);
    final now = DateTime.now().millisecondsSinceEpoch;

    final chunk = AudioChunk(
      pcmData: pcmData,
      timestamp: now,
      energy: energy,
    );

    if (!_audioChunkController.isClosed) {
      _audioChunkController.add(chunk);
    }

    // VAD Processing
    _processVAD(energy, now);
  }

  void _processVAD(double energy, int timestamp) {
    if (energy > RecitationConstants.vadEnergyThreshold) {
      // تم اكتشاف كلام
      _lastSpeechTime = timestamp;
      if (!_isInSpeech) {
        _isInSpeech = true;
        _setState(AudioState.speechDetected);
        _emitVAD(true, energy, timestamp);
      }
    } else {
      // صمت
      if (_isInSpeech) {
        final silenceDuration = timestamp - _lastSpeechTime;
        if (silenceDuration >= RecitationConstants.silenceWithinWordMs) {
          _isInSpeech = false;
          _setState(AudioState.silenceDetected);
          _emitVAD(false, energy, timestamp,
              silenceDuration: silenceDuration);
        }
      }
    }
  }

  void _emitVAD(bool isSpeech, double energy, int timestamp,
      {int? silenceDuration}) {
    if (!_vadEventController.isClosed) {
      _vadEventController.add(VADEvent(
        isSpeech: isSpeech,
        energy: energy,
        timestamp: timestamp,
        silenceDurationMs: silenceDuration,
      ));
    }
  }

  double _calculateEnergy(List<double> samples) {
    if (samples.isEmpty) return 0.0;
    double sum = 0;
    for (final s in samples) {
      sum += s * s;
    }
    return sqrt(sum / samples.length);
  }

  void _setState(AudioState newState) {
    _state = newState;
    if (!_stateController.isClosed) {
      _stateController.add(newState);
    }
  }

  /// محاكاة نطق كلمة (للاختبار)
  void simulateSpeechInput(String word, {double confidence = 0.85}) {
    if (_state == AudioState.idle) return;

    final now = DateTime.now().millisecondsSinceEpoch;

    // محاكاة ارتفاع الطاقة
    _setState(AudioState.speechDetected);
    _emitVAD(true, 0.5, now);

    // محاكاة انتهاء الكلمة بعد 500ms
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!_stateController.isClosed) {
        _emitVAD(false, 0.01, now + 500,
            silenceDuration: RecitationConstants.silenceWithinWordMs + 100);
      }
    });
  }

  Future<void> dispose() async {
    await stopRecording();
    await _audioChunkController.close();
    await _vadEventController.close();
    await _stateController.close();
    _instance = null;
  }
}
