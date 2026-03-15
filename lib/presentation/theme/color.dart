// lib/presentation/theme/color.dart

import 'package:flutter/material.dart';

class AppColors {
  // ═══════════ الألوان الرئيسية ═══════════
  static const Color primary = Color(0xFF1B5E20);         // أخضر إسلامي غامق
  static const Color primaryLight = Color(0xFF4CAF50);    // أخضر فاتح
  static const Color primaryDark = Color(0xFF0A3D0A);     // أخضر داكن جداً
  static const Color secondary = Color(0xFFD4AF37);       // ذهبي
  static const Color secondaryLight = Color(0xFFFFF8DC);  // كريمي فاتح
  static const Color accent = Color(0xFF8B4513);          // بني خشبي

  // ═══════════ ألوان الخلفية ═══════════
  static const Color background = Color(0xFFF5F0E8);      // بيج كريمي (ورق مصحف)
  static const Color backgroundDark = Color(0xFF1A1A1A);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF2C2C2C);
  static const Color card = Color(0xFFFFFBF0);            // بطاقة كريمية
  static const Color cardDark = Color(0xFF333333);

  // ═══════════ ألوان حالات الكلمات ═══════════
  static const Color wordCorrect = Color(0xFF2E7D32);     // أخضر غامق
  static const Color wordCorrectBg = Color(0xFFE8F5E9);   // أخضر شفاف
  static const Color wordWrongDiac = Color(0xFFE65100);   // برتقالي
  static const Color wordWrongDiacBg = Color(0xFFFFF3E0); // برتقالي شفاف
  static const Color wordWrongWord = Color(0xFFC62828);   // أحمر فاتح
  static const Color wordWrongWordBg = Color(0xFFFFEBEE); // أحمر شفاف جداً
  static const Color wordForgotten = Color(0xFF6A1A1A);   // أحمر غامق
  static const Color wordForgottenBg = Color(0xFFFFCDD2); // أحمر فاتح
  static const Color wordWaiting = Color(0xFF424242);     // رمادي داكن (كلمة منتظرة)
  static const Color wordWaitingBorder = Color(0xFF1B5E20); // إطار أخضر للكلمة المنتظرة
  static const Color wordHint = Color(0xFF9E9E9E);        // رمادي (تلميح)
  static const Color wordHidden = Color(0xFFEEEEEE);      // رمادي فاتح (مخفي)

  // ═══════════ ألوان الإحصاءات ═══════════
  static const Color statCorrect = Color(0xFF2E7D32);
  static const Color statError = Color(0xFFC62828);
  static const Color statForgotten = Color(0xFF6A1B9A);  // بنفسجي
  static const Color statWarning = Color(0xFFE65100);

  // ═══════════ ألوان التغذية الراجعة ═══════════
  static const Color feedbackSuccess = Color(0xFF1B5E20);
  static const Color feedbackSuccessBg = Color(0xFFE8F5E9);
  static const Color feedbackError = Color(0xFFB71C1C);
  static const Color feedbackErrorBg = Color(0xFFFFEBEE);
  static const Color feedbackDiacritics = Color(0xFFE65100);
  static const Color feedbackDiacriticsBg = Color(0xFFFFF3E0);
  static const Color feedbackForgotten = Color(0xFF4A148C);
  static const Color feedbackForgottenBg = Color(0xFFF3E5F5);

  // ═══════════ ألوان النص ═══════════
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF616161);
  static const Color textHint = Color(0xFF9E9E9E);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textQuran = Color(0xFF1A237E);      // أزرق داكن للنص القرآني

  // ═══════════ ألوان التسجيل ═══════════
  static const Color recordingIdle = Color(0xFF1B5E20);
  static const Color recordingActive = Color(0xFF1565C0);    // أزرق (ينتظر)
  static const Color recordingListening = Color(0xFF2E7D32); // أخضر (يسمع)
  static const Color recordingProcessing = Color(0xFFE65100); // برتقالي (يعالج)

  // ═══════════ التدرجات ═══════════
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient mushafahBackground = LinearGradient(
    colors: [Color(0xFFFFFBF0), Color(0xFFF5F0E0)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
