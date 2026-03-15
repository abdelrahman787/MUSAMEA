// lib/presentation/theme/quran_text_styles.dart
// أنماط نصية قرآنية موحّدة مع fallback للويب

import 'package:flutter/material.dart';
import 'color.dart';

/// أنماط نص المصحف — تضمن عرض الخط على الويب وأندرويد
class QuranTextStyles {
  // خطوط الاحتياط للويب
  static const List<String> _quranFontFallback = ['Amiri', 'serif'];

  // ─── نص الكلمة القرآنية (الحجم الطبيعي) ───
  static const TextStyle wordNormal = TextStyle(
    fontFamily: 'AmiriQuran',
    fontFamilyFallback: _quranFontFallback,
    fontSize: 22,
    height: 2.2,
    color: AppColors.textPrimary,
  );

  // ─── كلمة كبيرة (في شريط التسميع الرئيسي) ───
  static const TextStyle wordLarge = TextStyle(
    fontFamily: 'AmiriQuran',
    fontFamilyFallback: _quranFontFallback,
    fontSize: 28,
    height: 2.4,
    color: AppColors.textPrimary,
    fontWeight: FontWeight.w500,
  );

  // ─── كلمة صغيرة (للتلميحات والإحصاءات) ───
  static const TextStyle wordSmall = TextStyle(
    fontFamily: 'AmiriQuran',
    fontFamilyFallback: _quranFontFallback,
    fontSize: 16,
    height: 2.0,
    color: AppColors.textSecondary,
  );

  // ─── رأس السورة / البسملة ───
  static const TextStyle surahHeader = TextStyle(
    fontFamily: 'AmiriQuran',
    fontFamilyFallback: _quranFontFallback,
    fontSize: 24,
    height: 2.5,
    color: Colors.white,
    fontWeight: FontWeight.bold,
  );

  // ─── اسم السورة ───
  static const TextStyle surahName = TextStyle(
    fontFamily: 'Amiri',
    fontFamilyFallback: ['Scheherazade', 'serif'],
    fontSize: 20,
    color: AppColors.primary,
    fontWeight: FontWeight.bold,
  );

  // ─── نص عربي عام (Amiri) ───
  static const TextStyle arabic = TextStyle(
    fontFamily: 'Amiri',
    fontFamilyFallback: ['Scheherazade', 'serif'],
    fontSize: 15,
    color: AppColors.textPrimary,
  );

  /// دمج style مخصص مع الخطوط الاحتياطية
  static TextStyle custom({
    required TextStyle base,
    bool quranFont = true,
  }) {
    return base.copyWith(
      fontFamilyFallback:
          quranFont ? _quranFontFallback : ['Amiri', 'Scheherazade', 'serif'],
    );
  }
}
