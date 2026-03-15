// lib/di/app_providers.dart
// حقن التبعيات — يختار محرك ASR المناسب تلقائياً

import 'package:flutter/foundation.dart';
import '../data/local/db/quran_database.dart';
import '../data/local/db/app_database.dart';
import '../services/text/quran_word_matcher.dart';
import '../services/audio/audio_service.dart';
import '../services/asr/asr_services.dart';

class AppDependencies {
  static AppDependencies? _instance;
  static AppDependencies get instance {
    _instance ??= AppDependencies._();
    return _instance!;
  }

  AppDependencies._();

  final QuranDatabase quranDb = QuranDatabase.instance;
  final AppDatabase appDb = AppDatabase.instance;
  final QuranWordMatcher wordMatcher = QuranWordMatcher();
  final AudioService audioService = AudioService.instance;

  late final ASREngine asrEngine;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    // على الويب: استخدم المحاكاة (speech_to_text لا يدعم الويب بالكامل)
    if (kIsWeb) {
      asrEngine = MockASREngine();
      await asrEngine.initialize();
      if (kDebugMode) debugPrint('🌐 Web: using MockASREngine');
    } else if (kDebugMode) {
      // في وضع التطوير: جرّب المحرك الحقيقي أولاً
      final realEngine = SpeechToTextEngine();
      final ready = await realEngine.initialize();
      if (ready) {
        // تحقق من دعم العربية
        final hasArabic = await realEngine.supportsArabic();
        if (hasArabic) {
          asrEngine = realEngine;
          if (kDebugMode) debugPrint('✅ Debug: using SpeechToTextEngine (ar-SA)');
        } else {
          await realEngine.dispose();
          asrEngine = FallbackASREngine();
          await asrEngine.initialize();
          if (kDebugMode) debugPrint('⚠️ Debug: Arabic not supported, using FallbackASREngine');
        }
      } else {
        await realEngine.dispose();
        asrEngine = MockASREngine();
        await asrEngine.initialize();
        if (kDebugMode) debugPrint('⚠️ Debug: STT unavailable, using MockASREngine');
      }
    } else {
      // في الإنتاج: المحرك الحقيقي
      final realEngine = SpeechToTextEngine();
      final ready = await realEngine.initialize();
      if (ready) {
        asrEngine = realEngine;
      } else {
        await realEngine.dispose();
        // fallback للهواتف التي لا تدعم ar-SA
        final fallback = FallbackASREngine();
        await fallback.initialize();
        asrEngine = fallback;
      }
    }

    _initialized = true;
    if (kDebugMode) {
      debugPrint('✅ AppDependencies initialized: ${asrEngine.engineName}');
    }
  }

  Future<void> dispose() async {
    await asrEngine.dispose();
    await audioService.dispose();
    await quranDb.close();
    await appDb.close();
    _initialized = false;
    _instance = null;
  }
}
