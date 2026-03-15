// lib/data/remote/quran_api_service.dart
// خدمة Quran.Foundation API — بدون مصادقة
// Base: https://api.qurancdn.com/api/qdc
// المعامل الصحيح لجلب الكلمات: words=true

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/quran_word.dart';

class QuranApiService {
  // ─── ثوابت ───────────────────────────────────────────────
  static const String _baseUrl = 'https://api.qurancdn.com/api/qdc';
  static const Duration _timeout = Duration(seconds: 25);
  static const int _maxRetries = 3;

  // Singleton
  static final QuranApiService _instance = QuranApiService._();
  factory QuranApiService() => _instance;
  QuranApiService._();

  final http.Client _client = http.Client();

  // ═══════════════════════════════════════════════════════════
  // جلب كلمات صفحة كاملة
  //   words=true        → يُرجع مصفوفة words داخل كل آية
  //   word_fields=...   → يُحدد الحقول المطلوبة داخل كل كلمة
  // ═══════════════════════════════════════════════════════════
  Future<List<QuranWord>> fetchPageWords(int pageNumber) async {
    if (pageNumber < 1 || pageNumber > 604) {
      throw ArgumentError('رقم الصفحة يجب بين 1 و 604');
    }

    final uri = Uri.parse(
      '$_baseUrl/verses/by_page/$pageNumber'
      '?words=true'
      '&word_fields=text_uthmani,text_imlaei,page_number,line_number,char_type_name'
      '&fields=text_uthmani'
      '&per_page=50',
    );

    if (kDebugMode) debugPrint('📡 QuranAPI page → $uri');

    Exception? lastError;
    for (int attempt = 1; attempt <= _maxRetries; attempt++) {
      try {
        final response = await _client.get(uri).timeout(_timeout);
        if (response.statusCode == 200) {
          final data = json.decode(response.body) as Map<String, dynamic>;
          final words = _parseResponse(data, defaultPage: pageNumber);
          if (kDebugMode) {
            debugPrint(
              '✅ page $pageNumber → ${words.length} words (attempt $attempt)',
            );
          }
          return words;
        }
        lastError = Exception('HTTP ${response.statusCode}');
        if (kDebugMode) {
          debugPrint('⚠️ attempt $attempt: ${response.statusCode}');
        }
      } catch (e) {
        lastError = Exception('Network: $e');
        if (kDebugMode) debugPrint('⚠️ attempt $attempt exception: $e');
        if (attempt < _maxRetries) {
          await Future.delayed(Duration(milliseconds: 600 * attempt));
        }
      }
    }
    throw lastError ?? Exception('فشل جلب الصفحة $pageNumber');
  }

  // ═══════════════════════════════════════════════════════════
  // جلب كلمات سورة كاملة
  // ═══════════════════════════════════════════════════════════
  Future<List<QuranWord>> fetchSuraWords(int suraNumber) async {
    if (suraNumber < 1 || suraNumber > 114) {
      throw ArgumentError('رقم السورة يجب بين 1 و 114');
    }

    final uri = Uri.parse(
      '$_baseUrl/verses/by_chapter/$suraNumber'
      '?words=true'
      '&word_fields=text_uthmani,text_imlaei,page_number,line_number,char_type_name'
      '&fields=text_uthmani'
      '&per_page=286',
    );

    if (kDebugMode) debugPrint('📡 QuranAPI sura $suraNumber → $uri');

    Exception? lastError;
    for (int attempt = 1; attempt <= _maxRetries; attempt++) {
      try {
        final response = await _client.get(uri).timeout(_timeout);
        if (response.statusCode == 200) {
          final data = json.decode(response.body) as Map<String, dynamic>;
          final words = _parseResponse(data, defaultPage: null);
          if (kDebugMode) {
            debugPrint('✅ sura $suraNumber → ${words.length} words');
          }
          return words;
        }
        lastError = Exception('HTTP ${response.statusCode}');
      } catch (e) {
        lastError = Exception('Network: $e');
        if (attempt < _maxRetries) {
          await Future.delayed(Duration(milliseconds: 600 * attempt));
        }
      }
    }
    throw lastError ?? Exception('فشل جلب السورة $suraNumber');
  }

  // ═══════════════════════════════════════════════════════════
  // تحليل استجابة JSON → List<QuranWord>
  //
  //  مسار أساسي: verse.words[] — كلمة بكلمة مع page_number / line_number
  //  مسار بديل:  verse.text_uthmani — تقسيم بالمسافة (حال غياب words)
  // ═══════════════════════════════════════════════════════════
  List<QuranWord> _parseResponse(
    Map<String, dynamic> data, {
    required int? defaultPage,
  }) {
    final verses = data['verses'] as List<dynamic>? ?? [];
    final result = <QuranWord>[];
    int globalId = 1;

    for (final verseJson in verses) {
      final verse = verseJson as Map<String, dynamic>;
      final verseKey = verse['verse_key'] as String? ?? '';
      final parts = verseKey.split(':');
      final suraNum = int.tryParse(parts.isNotEmpty ? parts[0] : '0') ?? 0;
      final ayaNum = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;

      final versePageNum =
          verse['page_number'] as int? ?? defaultPage ?? 1;

      // ── مسار أساسي: words array ──────────────────────────
      final wordsJson = verse['words'] as List<dynamic>?;

      if (wordsJson != null && wordsJson.isNotEmpty) {
        // اجمع كلمات النوع "word" فقط (تجاهل "end" و "pause")
        final wordTokens = wordsJson
            .cast<Map<String, dynamic>>()
            .where((w) => (w['char_type_name'] as String? ?? 'word') == 'word')
            .toList();

        for (int i = 0; i < wordTokens.length; i++) {
          final w = wordTokens[i];
          final textUthmani =
              (w['text_uthmani'] as String? ?? w['text'] as String? ?? '')
                  .trim();
          if (textUthmani.isEmpty) continue;

          final textImlaei =
              (w['text_imlaei'] as String? ?? '').trim();
          final pageNum = w['page_number'] as int? ?? versePageNum;
          final lineNum = w['line_number'] as int? ?? 1;

          result.add(QuranWord(
            id: globalId++,
            verseKey: verseKey,
            suraNumber: suraNum,
            ayaNumber: ayaNum,
            wordPosition: i,
            textUthmani: textUthmani,
            textSimple: textImlaei.isNotEmpty
                ? textImlaei
                : _removeDiacritics(textUthmani),
            pageNumber: pageNum,
            lineNumber: lineNum,
            isLastInAya: i == wordTokens.length - 1,
          ));
        }
      } else {
        // ── مسار بديل: قسّم نص الآية بالمسافة ───────────────
        final verseText =
            (verse['text_uthmani'] as String? ?? '').trim();
        if (verseText.isEmpty) continue;

        final tokens =
            verseText.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();

        for (int i = 0; i < tokens.length; i++) {
          result.add(QuranWord(
            id: globalId++,
            verseKey: verseKey,
            suraNumber: suraNum,
            ayaNumber: ayaNum,
            wordPosition: i,
            textUthmani: tokens[i],
            textSimple: _removeDiacritics(tokens[i]),
            pageNumber: versePageNum,
            lineNumber: 1,
            isLastInAya: i == tokens.length - 1,
          ));
        }
      }
    }

    return result;
  }

  // ─── مساعد: إزالة التشكيل ────────────────────────────────
  static String _removeDiacritics(String text) {
    return text.replaceAll(
      RegExp(
        r'[\u064B-\u065F\u0670\u0610-\u061A\u06D6-\u06DC\u06DF-\u06E4\u06E7-\u06E8\u06EA-\u06ED]',
      ),
      '',
    );
  }

  void dispose() => _client.close();
}
