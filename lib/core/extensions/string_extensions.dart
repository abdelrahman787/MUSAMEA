// lib/core/extensions/string_extensions.dart

extension StringExtensions on String {
  /// إزالة التشكيل الكامل من النص العربي
  String removeArabicDiacritics() {
    // التشكيل: فتحة، ضمة، كسرة، شدة، سكون، تنوين (فتح، ضم، كسر)، مد، الوصلة
    return replaceAll(
      RegExp(
        r'[\u064B-\u065F\u0670\u0671]',
      ),
      '',
    );
  }

  /// تطبيع الألف (أ، إ، آ → ا)
  String normalizeAlef() {
    return replaceAll(RegExp(r'[أإآ]'), 'ا');
  }

  /// توحيد التاء المربوطة والهاء في نهاية الكلمة
  String normalizeTaMarbuta() {
    return replaceAll('ة', 'ه');
  }

  /// توحيد الياء (ى → ي)
  String normalizeYa() {
    return replaceAll('ى', 'ي');
  }

  /// تطبيع شامل للنص القرآني
  String normalizeArabicFull() {
    return removeArabicDiacritics()
        .normalizeAlef()
        .normalizeTaMarbuta()
        .normalizeYa()
        .trim();
  }

  /// حساب مسافة Levenshtein بين نصين
  int levenshteinDistance(String other) {
    if (this == other) return 0;
    if (isEmpty) return other.length;
    if (other.isEmpty) return length;

    final matrix = List.generate(
      length + 1,
      (i) => List.generate(other.length + 1, (j) => 0),
    );

    for (int i = 0; i <= length; i++) {
      matrix[i][0] = i;
    }
    for (int j = 0; j <= other.length; j++) {
      matrix[0][j] = j;
    }

    for (int i = 1; i <= length; i++) {
      for (int j = 1; j <= other.length; j++) {
        final cost = this[i - 1] == other[j - 1] ? 0 : 1;
        matrix[i][j] = [
          matrix[i - 1][j] + 1,
          matrix[i][j - 1] + 1,
          matrix[i - 1][j - 1] + cost,
        ].reduce((a, b) => a < b ? a : b);
      }
    }

    return matrix[length][other.length];
  }

  /// حساب نسبة التشابه بين نصين (0.0 إلى 1.0)
  double similarityTo(String other) {
    if (this == other) return 1.0;
    if (isEmpty && other.isEmpty) return 1.0;
    if (isEmpty || other.isEmpty) return 0.0;

    final maxLen = length > other.length ? length : other.length;
    final distance = levenshteinDistance(other);
    return 1.0 - (distance / maxLen);
  }

  /// هل النص عربي
  bool get isArabic =>
      contains(RegExp(r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF]'));

  /// إزالة المسافات المتعددة
  String normalizeSpaces() {
    return replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}
