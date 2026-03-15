// lib/data/remote/quran_api_service.dart
// خدمة Quran.Foundation API — بدون مصادقة
// Base URL: https://api.qurancdn.com/api/qdc
// Endpoint: GET /verses/by_page/{page}?fields=text_uthmani,text_imlaei&word_fields=text_uthmani,text_imlaei,page_number,line_number,char_type_name

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/quran_word.dart';

class QuranApiService {
  // ─── ثوابت ───────────────────────────────────────────────
  static const String _baseUrl = 'https://api.qurancdn.com/api/qdc';
  static const Duration _timeout = Duration(seconds: 20);
  static const int _maxRetries = 3;

  // Singleton
  static final QuranApiService _instance = QuranApiService._();
  factory QuranApiService() => _instance;
  QuranApiService._();

  // ─── HTTP client (قابل للاستبدال في الاختبارات) ──────────
  final http.Client _client = http.Client();

  // ═══════════════════════════════════════════════════════════
  // جلب كلمات صفحة كاملة
  // ═══════════════════════════════════════════════════════════
  Future<List<QuranWord>> fetchPageWords(int pageNumber) async {
    if (pageNumber < 1 || pageNumber > 604) {
      throw ArgumentError('رقم الصفحة يجب أن يكون بين 1 و 604');
    }

    final uri = Uri.parse(
      '$_baseUrl/verses/by_page/$pageNumber'
      '?fields=text_uthmani,text_imlaei'
      '&word_fields=text_uthmani,text_imlaei,page_number,line_number,char_type_name'
      '&per_page=50'
      '&page=1',
    );

    if (kDebugMode) debugPrint('📡 QuranAPI → $uri');

    Exception? lastError;
    for (int attempt = 1; attempt <= _maxRetries; attempt++) {
      try {
        final response = await _client.get(uri).timeout(_timeout);

        if (response.statusCode == 200) {
          final data = json.decode(response.body) as Map<String, dynamic>;
          final words = _parseResponse(data, pageNumber);
          if (kDebugMode) {
            debugPrint(
              '✅ QuranAPI page $pageNumber → ${words.length} words (attempt $attempt)',
            );
          }
          return words;
        } else {
          lastError = Exception(
            'HTTP ${response.statusCode}: ${response.reasonPhrase}',
          );
          if (kDebugMode) {
            debugPrint(
              '⚠️  QuranAPI attempt $attempt failed: ${response.statusCode}',
            );
          }
        }
      } catch (e) {
        lastError = Exception('Network error: $e');
        if (kDebugMode) {
          debugPrint('⚠️  QuranAPI attempt $attempt exception: $e');
        }
        if (attempt < _maxRetries) {
          await Future.delayed(Duration(milliseconds: 500 * attempt));
        }
      }
    }
    throw lastError ?? Exception('فشل جلب بيانات الصفحة $pageNumber');
  }

  // ═══════════════════════════════════════════════════════════
  // جلب كلمات سورة كاملة (بجمع الصفحات المتعددة)
  // ═══════════════════════════════════════════════════════════
  Future<List<QuranWord>> fetchSuraWords(int suraNumber) async {
    if (suraNumber < 1 || suraNumber > 114) {
      throw ArgumentError('رقم السورة يجب أن يكون بين 1 و 114');
    }

    final uri = Uri.parse(
      '$_baseUrl/verses/by_chapter/$suraNumber'
      '?fields=text_uthmani,text_imlaei'
      '&word_fields=text_uthmani,text_imlaei,page_number,line_number,char_type_name'
      '&per_page=286'
      '&page=1',
    );

    if (kDebugMode) debugPrint('📡 QuranAPI sura $suraNumber → $uri');

    final response = await _client.get(uri).timeout(_timeout);
    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode} for sura $suraNumber');
    }

    final data = json.decode(response.body) as Map<String, dynamic>;
    return _parseResponse(data, null);
  }

  // ═══════════════════════════════════════════════════════════
  // تحليل استجابة JSON → List<QuranWord>
  // ═══════════════════════════════════════════════════════════
  List<QuranWord> _parseResponse(
    Map<String, dynamic> data,
    int? defaultPage,
  ) {
    final verses = data['verses'] as List<dynamic>? ?? [];
    final result = <QuranWord>[];
    int globalId = 1;

    for (final verseJson in verses) {
      final verse = verseJson as Map<String, dynamic>;
      final verseKey = verse['verse_key'] as String? ?? '';
      final parts = verseKey.split(':');
      final suraNum = int.tryParse(parts.isNotEmpty ? parts[0] : '0') ?? 0;
      final ayaNum = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;

      final wordsJson = verse['words'] as List<dynamic>? ?? [];
      final wordCount = wordsJson.length;

      for (int i = 0; i < wordCount; i++) {
        final w = wordsJson[i] as Map<String, dynamic>;

        // تصفية العلامات (verse_end, end) — نأخذ word فقط
        final charType = w['char_type_name'] as String? ?? 'word';
        if (charType == 'end') continue;

        final textUthmani = w['text_uthmani'] as String? ??
            w['text'] as String? ??
            '';
        if (textUthmani.isEmpty) continue;

        final textImlaei = w['text_imlaei'] as String? ?? '';
        final pageNum = w['page_number'] as int? ??
            defaultPage ??
            1;
        final lineNum = w['line_number'] as int? ?? 1;

        // هل هذه آخر كلمة (word) في الآية؟
        bool isLast = false;
        if (i == wordCount - 1) {
          isLast = true;
        } else {
          // قد يكون العنصر التالي علامة "end" — نعتبر هذه الكلمة آخر كلمة
          final nextType =
              (wordsJson[i + 1] as Map<String, dynamic>)['char_type_name']
                  as String? ??
              'word';
          isLast = nextType == 'end';
        }

        result.add(QuranWord(
          id: globalId++,
          verseKey: verseKey,
          suraNumber: suraNum,
          ayaNumber: ayaNum,
          wordPosition: i,
          textUthmani: textUthmani,
          textSimple: textImlaei.isNotEmpty
              ? textImlaei
              : _removeArabicDiacritics(textUthmani),
          pageNumber: pageNum,
          lineNumber: lineNum,
          isLastInAya: isLast,
        ));
      }
    }

    return result;
  }

  // ─── مساعد: إزالة التشكيل ───────────────────────────────
  static String _removeArabicDiacritics(String text) {
    return text.replaceAll(
      RegExp(
        r'[\u064B-\u065F\u0670\u0610-\u061A\u06D6-\u06DC\u06DF-\u06E4\u06E7-\u06E8\u06EA-\u06ED]',
      ),
      '',
    );
  }

  void dispose() => _client.close();
}
