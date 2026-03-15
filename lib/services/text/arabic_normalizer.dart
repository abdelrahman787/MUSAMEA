// lib/services/text/arabic_normalizer.dart

class ArabicNormalizer {
  /// حروف التشكيل
  static const String diacritics = '\u064B\u064C\u064D\u064E\u064F\u0650\u0651\u0652\u0653\u0654\u0655\u0656\u0657\u0658\u0659\u065A\u065B\u065C\u065D\u065E\u065F\u0670';

  /// الوصلة
  static const String tatweel = '\u0640';

  /// إزالة التشكيل
  static String removeDiacritics(String text) {
    return text.replaceAll(RegExp('[$diacritics]'), '');
  }

  /// إزالة التطويل
  static String removeTatweel(String text) {
    return text.replaceAll(tatweel, '');
  }

  /// توحيد الألف
  static String normalizeAlef(String text) {
    return text
        .replaceAll('\u0623', '\u0627') // أ → ا
        .replaceAll('\u0625', '\u0627') // إ → ا
        .replaceAll('\u0622', '\u0627') // آ → ا
        .replaceAll('\u0671', '\u0627') // ٱ → ا (الألف الوصل)
        .replaceAll('\u0672', '\u0627') // ٲ → ا
        .replaceAll('\u0673', '\u0627') // ٳ → ا
        .replaceAll('\u0675', '\u0627'); // ٵ → ا
  }

  /// توحيد الياء
  static String normalizeYa(String text) {
    return text
        .replaceAll('\u0649', '\u064A') // ى → ي
        .replaceAll('\u0678', '\u064A'); // ٸ → ي
  }

  /// توحيد الواو
  static String normalizeWaw(String text) {
    return text
        .replaceAll('\u0624', '\u0648'); // ؤ → و
  }

  /// توحيد الهاء والتاء المربوطة
  static String normalizeTaMarbuta(String text) {
    // فقط في نهاية الكلمة
    return text.replaceAll(RegExp('[\u0629](?=\s|\$)'), '\u0647');
  }

  /// توحيد الهمزة
  static String normalizeHamza(String text) {
    return text
        .replaceAll('\u0621', '') // ء → حذف
        .replaceAll('\u0626', '\u064A'); // ئ → ي
  }

  /// تطبيع كامل للكلمة
  static String normalizeWord(String word) {
    String result = word.trim();
    result = removeTatweel(result);
    result = removeDiacritics(result);
    result = normalizeAlef(result);
    result = normalizeYa(result);
    result = normalizeWaw(result);
    return result.trim();
  }

  /// تطبيع كامل مشدد (يوحّد التاء والهمزة أيضاً)
  static String normalizeWordStrict(String word) {
    String result = normalizeWord(word);
    result = normalizeTaMarbuta(result);
    return result;
  }

  /// استخراج حروف التشكيل من نص
  static Map<int, List<String>> extractDiacritics(String text) {
    final result = <int, List<String>>{};
    final diacriticSet = Set<String>.from(diacritics.split(''));
    int nonDiacriticIndex = 0;

    for (int i = 0; i < text.length; i++) {
      if (diacriticSet.contains(text[i])) {
        result.putIfAbsent(nonDiacriticIndex - 1, () => []).add(text[i]);
      } else {
        nonDiacriticIndex++;
      }
    }
    return result;
  }

  /// مقارنة التشكيل بين كلمتين
  static DiacriticsComparison compareDiacritics(
    String expected,
    String spoken,
  ) {
    final expectedDiac = extractDiacritics(expected);
    final spokenDiac = extractDiacritics(spoken);
    final missingDiac = <String>[];
    final wrongDiac = <String>[];

    for (final entry in expectedDiac.entries) {
      final spokenAtPos = spokenDiac[entry.key] ?? [];
      for (final diac in entry.value) {
        if (!spokenAtPos.contains(diac)) {
          missingDiac.add(diac);
        }
      }
    }

    for (final entry in spokenDiac.entries) {
      final expectedAtPos = expectedDiac[entry.key] ?? [];
      for (final diac in entry.value) {
        if (!expectedAtPos.contains(diac)) {
          wrongDiac.add(diac);
        }
      }
    }

    return DiacriticsComparison(
      missingDiacritics: missingDiac,
      wrongDiacritics: wrongDiac,
      isExact: missingDiac.isEmpty && wrongDiac.isEmpty,
    );
  }
}

class DiacriticsComparison {
  final List<String> missingDiacritics;
  final List<String> wrongDiacritics;
  final bool isExact;

  const DiacriticsComparison({
    required this.missingDiacritics,
    required this.wrongDiacritics,
    required this.isExact,
  });
}
