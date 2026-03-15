// lib/core/constants/quran_constants.dart

class QuranConstants {
  static const int totalSuras = 114;
  static const int totalPages = 604;
  static const int totalVerses = 6236;
  static const int totalWords = 77430;
  static const String bismillahVerseKey = '1:1';
  static const String quranDbName = 'quran_words.db';
  static const int quranDbVersion = 1;

  // Sura metadata: [name, ayah count, revelation type (M=Meccan/L=Medinan), page]
  static const List<Map<String, dynamic>> suraList = [
    {'number': 1, 'name': 'الفاتحة', 'nameEn': 'Al-Fatiha', 'ayahs': 7, 'type': 'M', 'page': 1},
    {'number': 2, 'name': 'البقرة', 'nameEn': 'Al-Baqara', 'ayahs': 286, 'type': 'L', 'page': 2},
    {'number': 3, 'name': 'آل عمران', 'nameEn': 'Ali \'Imran', 'ayahs': 200, 'type': 'L', 'page': 50},
    {'number': 4, 'name': 'النساء', 'nameEn': 'An-Nisa', 'ayahs': 176, 'type': 'L', 'page': 77},
    {'number': 5, 'name': 'المائدة', 'nameEn': 'Al-Ma\'ida', 'ayahs': 120, 'type': 'L', 'page': 106},
    {'number': 6, 'name': 'الأنعام', 'nameEn': 'Al-An\'am', 'ayahs': 165, 'type': 'M', 'page': 128},
    {'number': 7, 'name': 'الأعراف', 'nameEn': 'Al-A\'raf', 'ayahs': 206, 'type': 'M', 'page': 151},
    {'number': 8, 'name': 'الأنفال', 'nameEn': 'Al-Anfal', 'ayahs': 75, 'type': 'L', 'page': 177},
    {'number': 9, 'name': 'التوبة', 'nameEn': 'At-Tawba', 'ayahs': 129, 'type': 'L', 'page': 187},
    {'number': 10, 'name': 'يونس', 'nameEn': 'Yunus', 'ayahs': 109, 'type': 'M', 'page': 208},
    {'number': 11, 'name': 'هود', 'nameEn': 'Hud', 'ayahs': 123, 'type': 'M', 'page': 221},
    {'number': 12, 'name': 'يوسف', 'nameEn': 'Yusuf', 'ayahs': 111, 'type': 'M', 'page': 235},
    {'number': 13, 'name': 'الرعد', 'nameEn': 'Ar-Ra\'d', 'ayahs': 43, 'type': 'L', 'page': 249},
    {'number': 14, 'name': 'إبراهيم', 'nameEn': 'Ibrahim', 'ayahs': 52, 'type': 'M', 'page': 255},
    {'number': 15, 'name': 'الحجر', 'nameEn': 'Al-Hijr', 'ayahs': 99, 'type': 'M', 'page': 262},
    {'number': 16, 'name': 'النحل', 'nameEn': 'An-Nahl', 'ayahs': 128, 'type': 'M', 'page': 267},
    {'number': 17, 'name': 'الإسراء', 'nameEn': 'Al-Isra', 'ayahs': 111, 'type': 'M', 'page': 282},
    {'number': 18, 'name': 'الكهف', 'nameEn': 'Al-Kahf', 'ayahs': 110, 'type': 'M', 'page': 293},
    {'number': 19, 'name': 'مريم', 'nameEn': 'Maryam', 'ayahs': 98, 'type': 'M', 'page': 305},
    {'number': 20, 'name': 'طه', 'nameEn': 'Ta-Ha', 'ayahs': 135, 'type': 'M', 'page': 312},
    {'number': 21, 'name': 'الأنبياء', 'nameEn': 'Al-Anbiya', 'ayahs': 112, 'type': 'M', 'page': 322},
    {'number': 22, 'name': 'الحج', 'nameEn': 'Al-Hajj', 'ayahs': 78, 'type': 'L', 'page': 332},
    {'number': 23, 'name': 'المؤمنون', 'nameEn': 'Al-Mu\'minun', 'ayahs': 118, 'type': 'M', 'page': 342},
    {'number': 24, 'name': 'النور', 'nameEn': 'An-Nur', 'ayahs': 64, 'type': 'L', 'page': 350},
    {'number': 25, 'name': 'الفرقان', 'nameEn': 'Al-Furqan', 'ayahs': 77, 'type': 'M', 'page': 359},
    {'number': 26, 'name': 'الشعراء', 'nameEn': 'Ash-Shu\'ara', 'ayahs': 227, 'type': 'M', 'page': 367},
    {'number': 27, 'name': 'النمل', 'nameEn': 'An-Naml', 'ayahs': 93, 'type': 'M', 'page': 377},
    {'number': 28, 'name': 'القصص', 'nameEn': 'Al-Qasas', 'ayahs': 88, 'type': 'M', 'page': 385},
    {'number': 29, 'name': 'العنكبوت', 'nameEn': 'Al-\'Ankabut', 'ayahs': 69, 'type': 'M', 'page': 396},
    {'number': 30, 'name': 'الروم', 'nameEn': 'Ar-Rum', 'ayahs': 60, 'type': 'M', 'page': 404},
    {'number': 31, 'name': 'لقمان', 'nameEn': 'Luqman', 'ayahs': 34, 'type': 'M', 'page': 411},
    {'number': 32, 'name': 'السجدة', 'nameEn': 'As-Sajda', 'ayahs': 30, 'type': 'M', 'page': 415},
    {'number': 33, 'name': 'الأحزاب', 'nameEn': 'Al-Ahzab', 'ayahs': 73, 'type': 'L', 'page': 418},
    {'number': 34, 'name': 'سبأ', 'nameEn': 'Saba', 'ayahs': 54, 'type': 'M', 'page': 428},
    {'number': 35, 'name': 'فاطر', 'nameEn': 'Fatir', 'ayahs': 45, 'type': 'M', 'page': 434},
    {'number': 36, 'name': 'يس', 'nameEn': 'Ya-Sin', 'ayahs': 83, 'type': 'M', 'page': 440},
    {'number': 37, 'name': 'الصافات', 'nameEn': 'As-Saffat', 'ayahs': 182, 'type': 'M', 'page': 446},
    {'number': 38, 'name': 'ص', 'nameEn': 'Sad', 'ayahs': 88, 'type': 'M', 'page': 453},
    {'number': 39, 'name': 'الزمر', 'nameEn': 'Az-Zumar', 'ayahs': 75, 'type': 'M', 'page': 458},
    {'number': 40, 'name': 'غافر', 'nameEn': 'Ghafir', 'ayahs': 85, 'type': 'M', 'page': 467},
    {'number': 41, 'name': 'فصلت', 'nameEn': 'Fussilat', 'ayahs': 54, 'type': 'M', 'page': 477},
    {'number': 42, 'name': 'الشورى', 'nameEn': 'Ash-Shura', 'ayahs': 53, 'type': 'M', 'page': 483},
    {'number': 43, 'name': 'الزخرف', 'nameEn': 'Az-Zukhruf', 'ayahs': 89, 'type': 'M', 'page': 489},
    {'number': 44, 'name': 'الدخان', 'nameEn': 'Ad-Dukhan', 'ayahs': 59, 'type': 'M', 'page': 496},
    {'number': 45, 'name': 'الجاثية', 'nameEn': 'Al-Jathiya', 'ayahs': 37, 'type': 'M', 'page': 499},
    {'number': 46, 'name': 'الأحقاف', 'nameEn': 'Al-Ahqaf', 'ayahs': 35, 'type': 'M', 'page': 502},
    {'number': 47, 'name': 'محمد', 'nameEn': 'Muhammad', 'ayahs': 38, 'type': 'L', 'page': 507},
    {'number': 48, 'name': 'الفتح', 'nameEn': 'Al-Fath', 'ayahs': 29, 'type': 'L', 'page': 511},
    {'number': 49, 'name': 'الحجرات', 'nameEn': 'Al-Hujurat', 'ayahs': 18, 'type': 'L', 'page': 515},
    {'number': 50, 'name': 'ق', 'nameEn': 'Qaf', 'ayahs': 45, 'type': 'M', 'page': 518},
    {'number': 51, 'name': 'الذاريات', 'nameEn': 'Adh-Dhariyat', 'ayahs': 60, 'type': 'M', 'page': 520},
    {'number': 52, 'name': 'الطور', 'nameEn': 'At-Tur', 'ayahs': 49, 'type': 'M', 'page': 523},
    {'number': 53, 'name': 'النجم', 'nameEn': 'An-Najm', 'ayahs': 62, 'type': 'M', 'page': 526},
    {'number': 54, 'name': 'القمر', 'nameEn': 'Al-Qamar', 'ayahs': 55, 'type': 'M', 'page': 528},
    {'number': 55, 'name': 'الرحمن', 'nameEn': 'Ar-Rahman', 'ayahs': 78, 'type': 'L', 'page': 531},
    {'number': 56, 'name': 'الواقعة', 'nameEn': 'Al-Waqi\'a', 'ayahs': 96, 'type': 'M', 'page': 534},
    {'number': 57, 'name': 'الحديد', 'nameEn': 'Al-Hadid', 'ayahs': 29, 'type': 'L', 'page': 537},
    {'number': 58, 'name': 'المجادلة', 'nameEn': 'Al-Mujadila', 'ayahs': 22, 'type': 'L', 'page': 542},
    {'number': 59, 'name': 'الحشر', 'nameEn': 'Al-Hashr', 'ayahs': 24, 'type': 'L', 'page': 545},
    {'number': 60, 'name': 'الممتحنة', 'nameEn': 'Al-Mumtahana', 'ayahs': 13, 'type': 'L', 'page': 549},
    {'number': 61, 'name': 'الصف', 'nameEn': 'As-Saf', 'ayahs': 14, 'type': 'L', 'page': 551},
    {'number': 62, 'name': 'الجمعة', 'nameEn': 'Al-Jumu\'a', 'ayahs': 11, 'type': 'L', 'page': 553},
    {'number': 63, 'name': 'المنافقون', 'nameEn': 'Al-Munafiqun', 'ayahs': 11, 'type': 'L', 'page': 554},
    {'number': 64, 'name': 'التغابن', 'nameEn': 'At-Taghabun', 'ayahs': 18, 'type': 'L', 'page': 556},
    {'number': 65, 'name': 'الطلاق', 'nameEn': 'At-Talaq', 'ayahs': 12, 'type': 'L', 'page': 558},
    {'number': 66, 'name': 'التحريم', 'nameEn': 'At-Tahrim', 'ayahs': 12, 'type': 'L', 'page': 560},
    {'number': 67, 'name': 'الملك', 'nameEn': 'Al-Mulk', 'ayahs': 30, 'type': 'M', 'page': 562},
    {'number': 68, 'name': 'القلم', 'nameEn': 'Al-Qalam', 'ayahs': 52, 'type': 'M', 'page': 564},
    {'number': 69, 'name': 'الحاقة', 'nameEn': 'Al-Haqqah', 'ayahs': 52, 'type': 'M', 'page': 566},
    {'number': 70, 'name': 'المعارج', 'nameEn': 'Al-Ma\'arij', 'ayahs': 44, 'type': 'M', 'page': 568},
    {'number': 71, 'name': 'نوح', 'nameEn': 'Nuh', 'ayahs': 28, 'type': 'M', 'page': 570},
    {'number': 72, 'name': 'الجن', 'nameEn': 'Al-Jinn', 'ayahs': 28, 'type': 'M', 'page': 572},
    {'number': 73, 'name': 'المزمل', 'nameEn': 'Al-Muzzammil', 'ayahs': 20, 'type': 'M', 'page': 574},
    {'number': 74, 'name': 'المدثر', 'nameEn': 'Al-Muddaththir', 'ayahs': 56, 'type': 'M', 'page': 575},
    {'number': 75, 'name': 'القيامة', 'nameEn': 'Al-Qiyama', 'ayahs': 40, 'type': 'M', 'page': 577},
    {'number': 76, 'name': 'الإنسان', 'nameEn': 'Al-Insan', 'ayahs': 31, 'type': 'L', 'page': 578},
    {'number': 77, 'name': 'المرسلات', 'nameEn': 'Al-Mursalat', 'ayahs': 50, 'type': 'M', 'page': 580},
    {'number': 78, 'name': 'النبأ', 'nameEn': 'An-Naba', 'ayahs': 40, 'type': 'M', 'page': 582},
    {'number': 79, 'name': 'النازعات', 'nameEn': 'An-Nazi\'at', 'ayahs': 46, 'type': 'M', 'page': 583},
    {'number': 80, 'name': 'عبس', 'nameEn': '\'Abasa', 'ayahs': 42, 'type': 'M', 'page': 585},
    {'number': 81, 'name': 'التكوير', 'nameEn': 'At-Takwir', 'ayahs': 29, 'type': 'M', 'page': 586},
    {'number': 82, 'name': 'الانفطار', 'nameEn': 'Al-Infitar', 'ayahs': 19, 'type': 'M', 'page': 587},
    {'number': 83, 'name': 'المطففين', 'nameEn': 'Al-Mutaffifin', 'ayahs': 36, 'type': 'M', 'page': 587},
    {'number': 84, 'name': 'الانشقاق', 'nameEn': 'Al-Inshiqaq', 'ayahs': 25, 'type': 'M', 'page': 589},
    {'number': 85, 'name': 'البروج', 'nameEn': 'Al-Buruj', 'ayahs': 22, 'type': 'M', 'page': 590},
    {'number': 86, 'name': 'الطارق', 'nameEn': 'At-Tariq', 'ayahs': 17, 'type': 'M', 'page': 591},
    {'number': 87, 'name': 'الأعلى', 'nameEn': 'Al-A\'la', 'ayahs': 19, 'type': 'M', 'page': 591},
    {'number': 88, 'name': 'الغاشية', 'nameEn': 'Al-Ghashiya', 'ayahs': 26, 'type': 'M', 'page': 592},
    {'number': 89, 'name': 'الفجر', 'nameEn': 'Al-Fajr', 'ayahs': 30, 'type': 'M', 'page': 593},
    {'number': 90, 'name': 'البلد', 'nameEn': 'Al-Balad', 'ayahs': 20, 'type': 'M', 'page': 594},
    {'number': 91, 'name': 'الشمس', 'nameEn': 'Ash-Shams', 'ayahs': 15, 'type': 'M', 'page': 595},
    {'number': 92, 'name': 'الليل', 'nameEn': 'Al-Layl', 'ayahs': 21, 'type': 'M', 'page': 595},
    {'number': 93, 'name': 'الضحى', 'nameEn': 'Ad-Duha', 'ayahs': 11, 'type': 'M', 'page': 596},
    {'number': 94, 'name': 'الشرح', 'nameEn': 'Ash-Sharh', 'ayahs': 8, 'type': 'M', 'page': 596},
    {'number': 95, 'name': 'التين', 'nameEn': 'At-Tin', 'ayahs': 8, 'type': 'M', 'page': 597},
    {'number': 96, 'name': 'العلق', 'nameEn': 'Al-\'Alaq', 'ayahs': 19, 'type': 'M', 'page': 597},
    {'number': 97, 'name': 'القدر', 'nameEn': 'Al-Qadr', 'ayahs': 5, 'type': 'M', 'page': 598},
    {'number': 98, 'name': 'البينة', 'nameEn': 'Al-Bayyina', 'ayahs': 8, 'type': 'L', 'page': 598},
    {'number': 99, 'name': 'الزلزلة', 'nameEn': 'Az-Zalzala', 'ayahs': 8, 'type': 'L', 'page': 599},
    {'number': 100, 'name': 'العاديات', 'nameEn': 'Al-\'Adiyat', 'ayahs': 11, 'type': 'M', 'page': 599},
    {'number': 101, 'name': 'القارعة', 'nameEn': 'Al-Qari\'a', 'ayahs': 11, 'type': 'M', 'page': 600},
    {'number': 102, 'name': 'التكاثر', 'nameEn': 'At-Takathur', 'ayahs': 8, 'type': 'M', 'page': 600},
    {'number': 103, 'name': 'العصر', 'nameEn': 'Al-\'Asr', 'ayahs': 3, 'type': 'M', 'page': 601},
    {'number': 104, 'name': 'الهمزة', 'nameEn': 'Al-Humaza', 'ayahs': 9, 'type': 'M', 'page': 601},
    {'number': 105, 'name': 'الفيل', 'nameEn': 'Al-Fil', 'ayahs': 5, 'type': 'M', 'page': 601},
    {'number': 106, 'name': 'قريش', 'nameEn': 'Quraysh', 'ayahs': 4, 'type': 'M', 'page': 602},
    {'number': 107, 'name': 'الماعون', 'nameEn': 'Al-Ma\'un', 'ayahs': 7, 'type': 'M', 'page': 602},
    {'number': 108, 'name': 'الكوثر', 'nameEn': 'Al-Kawthar', 'ayahs': 3, 'type': 'M', 'page': 602},
    {'number': 109, 'name': 'الكافرون', 'nameEn': 'Al-Kafirun', 'ayahs': 6, 'type': 'M', 'page': 603},
    {'number': 110, 'name': 'النصر', 'nameEn': 'An-Nasr', 'ayahs': 3, 'type': 'L', 'page': 603},
    {'number': 111, 'name': 'المسد', 'nameEn': 'Al-Masad', 'ayahs': 5, 'type': 'M', 'page': 603},
    {'number': 112, 'name': 'الإخلاص', 'nameEn': 'Al-Ikhlas', 'ayahs': 4, 'type': 'M', 'page': 604},
    {'number': 113, 'name': 'الفلق', 'nameEn': 'Al-Falaq', 'ayahs': 5, 'type': 'M', 'page': 604},
    {'number': 114, 'name': 'الناس', 'nameEn': 'An-Nas', 'ayahs': 6, 'type': 'M', 'page': 604},
  ];

  static String getSuraName(int suraNumber) {
    if (suraNumber < 1 || suraNumber > 114) return '';
    return suraList[suraNumber - 1]['name'] as String;
  }

  static int getSuraAyahCount(int suraNumber) {
    if (suraNumber < 1 || suraNumber > 114) return 0;
    return suraList[suraNumber - 1]['ayahs'] as int;
  }

  static int getSuraPage(int suraNumber) {
    if (suraNumber < 1 || suraNumber > 114) return 1;
    return suraList[suraNumber - 1]['page'] as int;
  }

  // Juz boundaries [sura, ayah]
  static const List<List<int>> juzBoundaries = [
    [1, 1], [2, 142], [2, 253], [3, 93], [4, 24],
    [4, 148], [5, 82], [6, 111], [7, 88], [8, 41],
    [9, 93], [11, 6], [12, 53], [15, 1], [17, 1],
    [18, 75], [21, 1], [23, 1], [25, 21], [27, 56],
    [29, 46], [33, 31], [36, 28], [39, 32], [41, 47],
    [46, 1], [51, 31], [58, 14], [67, 1], [78, 1],
  ];
}
