// lib/presentation/screens/reports/reports_screen.dart

import 'package:flutter/material.dart';
import '../../theme/color.dart';
import '../../../data/local/db/app_database.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _recentSessions = [];
  List<Map<String, dynamic>> _weakPoints = [];
  List<Map<String, dynamic>> _progressData = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final db = AppDatabase.instance;
      final fromDate = DateTime.now()
          .subtract(const Duration(days: 30))
          .millisecondsSinceEpoch;

      final sessions = await db.getRecentSessions(limit: 20);
      final weakPoints = await db.getWeakPointsAggregated();
      final progress = await db.getProgressData(
        suraFilter: -1,
        fromDate: fromDate,
      );

      if (mounted) {
        setState(() {
          _recentSessions = sessions;
          _weakPoints = weakPoints;
          _progressData = progress;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('التقارير والإحصاءات'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: () => Navigator.pop(context),
          ),
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'ملخص الجلسة'),
              Tab(text: 'نقاط الضعف'),
              Tab(text: 'منحنى التقدم'),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                controller: _tabController,
                children: [
                  _SessionSummaryTab(sessions: _recentSessions),
                  _WeakPointsTab(weakPoints: _weakPoints),
                  _ProgressTab(progressData: _progressData),
                ],
              ),
      ),
    );
  }
}

// ═══════════════ تبويب ملخص الجلسة ═══════════════
class _SessionSummaryTab extends StatelessWidget {
  final List<Map<String, dynamic>> sessions;

  const _SessionSummaryTab({required this.sessions});

  @override
  Widget build(BuildContext context) {
    if (sessions.isEmpty) {
      return _EmptyState(
        icon: Icons.history_rounded,
        message: 'لا توجد جلسات مسجلة حتى الآن\nابدأ جلسة تسميع جديدة!',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sessions.length,
      itemBuilder: (context, index) {
        return _SessionCard(session: sessions[index]);
      },
    );
  }
}

class _SessionCard extends StatelessWidget {
  final Map<String, dynamic> session;

  const _SessionCard({required this.session});

  @override
  Widget build(BuildContext context) {
    final accuracy = (session['accuracy_percent'] as double? ?? 0.0);
    final dateMs = session['date_time_ms'] as int? ?? 0;
    final date = DateTime.fromMillisecondsSinceEpoch(dateMs);
    final duration = session['duration_seconds'] as int? ?? 0;
    final totalWords = session['total_words'] as int? ?? 0;
    final correctWords = session['correct_words'] as int? ?? 0;
    final forgottenWords = session['forgotten_words'] as int? ?? 0;
    final wrongWordErrors = session['wrong_word_errors'] as int? ?? 0;
    final diacriticsErrors = session['diacritics_errors'] as int? ?? 0;

    Color accuracyColor = accuracy >= 80
        ? AppColors.statCorrect
        : accuracy >= 60
            ? AppColors.statWarning
            : AppColors.statError;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // العنوان والتاريخ
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '${session['sura_name']} ← الآية ${session['start_aya']}',
                    style: const TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: accuracyColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: accuracyColor),
                  ),
                  child: Text(
                    '${accuracy.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontFamily: 'Amiri',
                      fontWeight: FontWeight.bold,
                      color: accuracyColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.access_time, size: 13, color: AppColors.textHint),
                const SizedBox(width: 4),
                Text(
                  '${duration ~/ 60} دقيقة',
                  style: const TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 12,
                    color: AppColors.textHint,
                  ),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.calendar_today, size: 13, color: AppColors.textHint),
                const SizedBox(width: 4),
                Text(
                  _formatDate(date),
                  style: const TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 12,
                    color: AppColors.textHint,
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            // إحصاءات الكلمات
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _MiniStat(
                  value: correctWords,
                  label: 'صحيح',
                  color: AppColors.statCorrect,
                ),
                _MiniStat(
                  value: forgottenWords,
                  label: 'منسي',
                  color: AppColors.statForgotten,
                ),
                _MiniStat(
                  value: wrongWordErrors,
                  label: 'خطأ كلمة',
                  color: AppColors.statError,
                ),
                _MiniStat(
                  value: diacriticsErrors,
                  label: 'خطأ تشكيل',
                  color: AppColors.statWarning,
                ),
              ],
            ),
            const SizedBox(height: 10),
            // شريط التقدم
            LinearProgressIndicator(
              value: totalWords > 0 ? correctWords / totalWords : 0,
              backgroundColor: AppColors.wordHidden,
              valueColor: AlwaysStoppedAnimation<Color>(accuracyColor),
              minHeight: 6,
              borderRadius: BorderRadius.circular(3),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class _MiniStat extends StatelessWidget {
  final int value;
  final String label;
  final Color color;

  const _MiniStat({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '$value',
          style: TextStyle(
            fontFamily: 'Amiri',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Amiri',
            fontSize: 10,
            color: AppColors.textHint,
          ),
        ),
      ],
    );
  }
}

// ═══════════════ تبويب نقاط الضعف ═══════════════
class _WeakPointsTab extends StatelessWidget {
  final List<Map<String, dynamic>> weakPoints;

  const _WeakPointsTab({required this.weakPoints});

  @override
  Widget build(BuildContext context) {
    if (weakPoints.isEmpty) {
      return _EmptyState(
        icon: Icons.emoji_events_rounded,
        message: 'ممتاز! لا توجد نقاط ضعف مسجلة\nاستمر في التسميع!',
        iconColor: AppColors.secondary,
      );
    }

    // فصل الأخطاء حسب النوع
    final forgottenWords = weakPoints
        .where((w) => (w['forgotten_count'] as int? ?? 0) > 0)
        .toList()
      ..sort((a, b) =>
          (b['forgotten_count'] as int).compareTo(a['forgotten_count'] as int));

    final diacriticsErrors = weakPoints
        .where((w) => (w['diac_count'] as int? ?? 0) > 0)
        .toList()
      ..sort((a, b) =>
          (b['diac_count'] as int).compareTo(a['diac_count'] as int));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // نقاط النسيان
          if (forgottenWords.isNotEmpty) ...[
            _SectionHeader(
              title: 'أكثر الكلمات التي تنساها',
              icon: Icons.hourglass_empty_rounded,
              color: AppColors.statForgotten,
            ),
            const SizedBox(height: 8),
            ...forgottenWords.take(10).map((w) => _WeakWordCard(
              word: w,
              primaryCount: w['forgotten_count'] as int? ?? 0,
              primaryLabel: 'نسيان',
              primaryColor: AppColors.statForgotten,
            )),
            const SizedBox(height: 20),
          ],

          // أخطاء التشكيل
          if (diacriticsErrors.isNotEmpty) ...[
            _SectionHeader(
              title: 'أخطاء التشكيل المتكررة',
              icon: Icons.text_fields_rounded,
              color: AppColors.statWarning,
            ),
            const SizedBox(height: 8),
            ...diacriticsErrors.take(10).map((w) => _WeakWordCard(
              word: w,
              primaryCount: w['diac_count'] as int? ?? 0,
              primaryLabel: 'خطأ تشكيل',
              primaryColor: AppColors.statWarning,
            )),
          ],
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;

  const _SectionHeader({
    required this.title,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontFamily: 'Amiri',
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _WeakWordCard extends StatelessWidget {
  final Map<String, dynamic> word;
  final int primaryCount;
  final String primaryLabel;
  final Color primaryColor;

  const _WeakWordCard({
    required this.word,
    required this.primaryCount,
    required this.primaryLabel,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final wordText = word['word_text'] as String? ??
        word['expected_word_uthmani'] as String? ?? '';
    final totalErrors = word['total_errors'] as int? ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$primaryCount',
              style: TextStyle(
                fontFamily: 'Amiri',
                fontWeight: FontWeight.bold,
                color: primaryColor,
                fontSize: 16,
              ),
            ),
          ),
        ),
        title: Text(
          wordText,
          style: const TextStyle(
            fontFamily: 'AmiriQuran',
            fontSize: 20,
            color: AppColors.textQuran,
            height: 1.8,
          ),
          textDirection: TextDirection.rtl,
        ),
        subtitle: Text(
          'السورة ${word['sura_number']}: آية ${word['aya_number']} — $primaryLabel',
          style: const TextStyle(fontFamily: 'Amiri', fontSize: 12),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'إجمالي',
              style: const TextStyle(
                fontFamily: 'Amiri',
                fontSize: 10,
                color: AppColors.textHint,
              ),
            ),
            Text(
              '$totalErrors',
              style: const TextStyle(
                fontFamily: 'Amiri',
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════ تبويب منحنى التقدم ═══════════════
class _ProgressTab extends StatelessWidget {
  final List<Map<String, dynamic>> progressData;

  const _ProgressTab({required this.progressData});

  @override
  Widget build(BuildContext context) {
    if (progressData.isEmpty) {
      return _EmptyState(
        icon: Icons.show_chart_rounded,
        message: 'سجّل جلسات أكثر لعرض منحنى التقدم',
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // الرسم البياني البسيط (بدون مكتبة خارجية)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'منحنى الدقة — آخر 30 يوم',
                    style: TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: _SimpleLineChart(data: progressData),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // قائمة الجلسات
          ...progressData.reversed.take(10).map(
            (session) => _ProgressSessionTile(session: session),
          ),
        ],
      ),
    );
  }
}

class _SimpleLineChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;

  const _SimpleLineChart({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox();

    final values = data.map((d) => (d['accuracy_percent'] as double? ?? 0.0)).toList();
    final maxVal = values.reduce((a, b) => a > b ? a : b);
    final minVal = values.reduce((a, b) => a < b ? a : b);

    return CustomPaint(
      painter: _LineChartPainter(
        values: values,
        maxVal: maxVal == minVal ? maxVal + 10 : maxVal,
        minVal: minVal > 10 ? minVal - 10 : 0,
      ),
      size: const Size(double.infinity, 200),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<double> values;
  final double maxVal;
  final double minVal;

  _LineChartPainter({
    required this.values,
    required this.maxVal,
    required this.minVal,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final paint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final dotPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.fill;

    final gridPaint = Paint()
      ..color = AppColors.wordHidden
      ..strokeWidth = 1;

    // رسم شبكة الخلفية
    for (int i = 0; i <= 4; i++) {
      final y = size.height * (i / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // رسم الخط
    final path = Path();
    for (int i = 0; i < values.length; i++) {
      final x = values.length == 1 ? size.width / 2 : size.width * (i / (values.length - 1));
      final normalized = maxVal == minVal
          ? 0.5
          : (values[i] - minVal) / (maxVal - minVal);
      final y = size.height * (1 - normalized);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }

      // نقطة البيانات
      canvas.drawCircle(Offset(x, y), 4, dotPaint);
    }

    canvas.drawPath(path, paint);

    // الأرقام المحورية
    final textStyle = const TextStyle(
      color: AppColors.textHint,
      fontSize: 10,
      fontFamily: 'Amiri',
    );
    final textPainter = TextPainter(
      textDirection: TextDirection.rtl,
    );

    for (int i = 0; i <= 4; i++) {
      final val = minVal + (maxVal - minVal) * ((4 - i) / 4);
      textPainter.text = TextSpan(
        text: '${val.toStringAsFixed(0)}%',
        style: textStyle,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(0, size.height * (i / 4)));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _ProgressSessionTile extends StatelessWidget {
  final Map<String, dynamic> session;

  const _ProgressSessionTile({required this.session});

  @override
  Widget build(BuildContext context) {
    final accuracy = session['accuracy_percent'] as double? ?? 0.0;
    final dateMs = session['date_time_ms'] as int? ?? 0;
    final date = DateTime.fromMillisecondsSinceEpoch(dateMs);
    final suraName = session['sura_name'] as String? ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        leading: CircleAvatar(
          radius: 18,
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          child: Text(
            '${accuracy.toInt()}',
            style: const TextStyle(
              fontFamily: 'Amiri',
              fontSize: 12,
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          suraName,
          style: const TextStyle(fontFamily: 'Amiri', fontSize: 14),
        ),
        subtitle: Text(
          '${date.day}/${date.month}/${date.year}',
          style: const TextStyle(fontFamily: 'Amiri', fontSize: 11),
        ),
        trailing: LinearProgressIndicator(
          value: accuracy / 100,
          backgroundColor: AppColors.wordHidden,
          valueColor: AlwaysStoppedAnimation<Color>(
            accuracy >= 80 ? AppColors.statCorrect : AppColors.statWarning,
          ),
          minHeight: 6,
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    );
  }
}

// ═══════════════ حالة فارغة ═══════════════
class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final Color? iconColor;

  const _EmptyState({
    required this.icon,
    required this.message,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: iconColor ?? AppColors.textHint,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              fontFamily: 'Amiri',
              fontSize: 16,
              color: AppColors.textHint,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
