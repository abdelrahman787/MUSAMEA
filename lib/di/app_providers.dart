// lib/di/app_providers.dart

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

    asrEngine = kDebugMode
        ? MockASREngine()
        : GoogleSpeechEngine();

    await asrEngine.initialize();
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
  }
}
