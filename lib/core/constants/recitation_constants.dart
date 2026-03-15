// lib/core/constants/recitation_constants.dart

class RecitationConstants {
  // زمن الصمت
  static const int silenceWithinWordMs = 600;      // صمت داخل الكلمة (نهاية الكلمة)
  static const int forgettingThresholdMs = 3000;   // صمت طويل = نسيان
  static const int wrongDiacAdvanceDelayMs = 2000; // تأخير الانتقال بعد خطأ تشكيل

  // ASR
  static const double asrMinConfidence = 0.55;
  static const double similarityDiacThreshold = 0.75;
  static const int maxAttemptsPerWord = 5;

  // VAD
  static const double vadEnergyThreshold = 0.02;

  // Audio
  static const int audioSampleRate = 16000;
  static const int audioBufferSize = 4096;

  // UI Timings
  static const int feedbackDisplayMs = 2500;
  static const int correctAnimationMs = 500;
  static const int pulseAnimationMs = 1200;

  // Session modes
  static const String modeHidden = 'HIDDEN';
  static const String modeVisible = 'VISIBLE';
}
