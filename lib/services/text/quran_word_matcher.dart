// lib/services/text/quran_word_matcher.dart
// خوارزمية مطابقة الكلمات القرآنية

import 'arabic_normalizer.dart';
import '../../core/constants/recitation_constants.dart';

/// نتيجة المطابقة
sealed class MatchResult {
  const MatchResult();
}

class MatchCorrect extends MatchResult {
  const MatchCorrect();
}

class MatchWrongDiacritics extends MatchResult {
  final String expected;
  final String spoken;
  final List<String> missingDiac;
  final List<String> wrongDiac;
  const MatchWrongDiacritics({
    required this.expected,
    required this.spoken,
    required this.missingDiac,
    required this.wrongDiac,
  });
}

class MatchWrongWord extends MatchResult {
  final String expected;
  final String spoken;
  final double similarity;
  const MatchWrongWord({
    required this.expected,
    required this.spoken,
    required this.similarity,
  });
}

class MatchForgotten extends MatchResult {
  const MatchForgotten();
}

class MatchTooSilent extends MatchResult {
  const MatchTooSilent();
}

class QuranWordMatcher {
  /// المطابقة الرئيسية
  MatchResult matchWord(String expected, String? spoken) {
    // الخطوة 1: إذا spoken فارغ أو null → Forgotten
    if (spoken == null || spoken.trim().isEmpty) {
      return const MatchForgotten();
    }

    final spokenTrimmed = spoken.trim();

    // الخطوة 2: تطبيع الكلمتين
    final expectedNorm = ArabicNormalizer.normalizeWord(expected);
    final spokenNorm = ArabicNormalizer.normalizeWord(spokenTrimmed);

    if (expectedNorm.isEmpty || spokenNorm.isEmpty) {
      return const MatchForgotten();
    }

    // الخطوة 3A: إذا النص المُطبَّع متطابق
    if (expectedNorm == spokenNorm) {
      // قارن التشكيل الأصلي
      final diacComp = ArabicNormalizer.compareDiacritics(expected, spokenTrimmed);
      if (diacComp.isExact) {
        return const MatchCorrect();
      } else {
        return MatchWrongDiacritics(
          expected: expected,
          spoken: spokenTrimmed,
          missingDiac: diacComp.missingDiacritics,
          wrongDiac: diacComp.wrongDiacritics,
        );
      }
    }

    // الخطوة 3B: غير متطابق - احسب Levenshtein
    final distance = _levenshteinDistance(expectedNorm, spokenNorm);
    final maxLen = expectedNorm.length > spokenNorm.length
        ? expectedNorm.length
        : spokenNorm.length;
    final similarity = maxLen == 0 ? 1.0 : 1.0 - (distance / maxLen);

    if (similarity >= RecitationConstants.similarityDiacThreshold) {
      // نطق مقارب = خطأ تشكيل غالباً
      final diacComp = ArabicNormalizer.compareDiacritics(expected, spokenTrimmed);
      return MatchWrongDiacritics(
        expected: expected,
        spoken: spokenTrimmed,
        missingDiac: diacComp.missingDiacritics,
        wrongDiac: diacComp.wrongDiacritics,
      );
    } else {
      return MatchWrongWord(
        expected: expected,
        spoken: spokenTrimmed,
        similarity: similarity,
      );
    }
  }

  /// حساب مسافة Levenshtein
  int _levenshteinDistance(String s1, String s2) {
    if (s1 == s2) return 0;
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;

    final dp = List.generate(
      s1.length + 1,
      (i) => List.generate(s2.length + 1, (j) => 0),
    );

    for (int i = 0; i <= s1.length; i++) dp[i][0] = i;
    for (int j = 0; j <= s2.length; j++) dp[0][j] = j;

    for (int i = 1; i <= s1.length; i++) {
      for (int j = 1; j <= s2.length; j++) {
        final cost = s1[i - 1] == s2[j - 1] ? 0 : 1;
        dp[i][j] = _min3(
          dp[i - 1][j] + 1,
          dp[i][j - 1] + 1,
          dp[i - 1][j - 1] + cost,
        );
      }
    }
    return dp[s1.length][s2.length];
  }

  int _min3(int a, int b, int c) {
    if (a <= b && a <= c) return a;
    if (b <= c) return b;
    return c;
  }

  /// مطابقة مع تحمل للاختلاف في التنوين والمد
  MatchResult matchWordRelaxed(String expected, String? spoken) {
    if (spoken == null || spoken.trim().isEmpty) {
      return const MatchForgotten();
    }

    // طبّق تطبيعاً أكثر تساهلاً
    final expectedStrict = ArabicNormalizer.normalizeWordStrict(expected);
    final spokenStrict = ArabicNormalizer.normalizeWordStrict(spoken.trim());

    if (expectedStrict == spokenStrict) {
      return const MatchCorrect();
    }

    return matchWord(expected, spoken);
  }

  /// اختبار جملة كاملة (لاختبار الوحدة)
  List<MatchResult> matchSentence(
    List<String> expectedWords,
    List<String?> spokenWords,
  ) {
    final results = <MatchResult>[];
    final len = expectedWords.length < spokenWords.length
        ? expectedWords.length
        : spokenWords.length;

    for (int i = 0; i < len; i++) {
      results.add(matchWord(expectedWords[i], spokenWords[i]));
    }
    return results;
  }
}
