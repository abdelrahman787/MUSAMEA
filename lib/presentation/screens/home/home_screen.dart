// lib/presentation/screens/home/home_screen.dart

import 'package:flutter/material.dart';
import '../../theme/color.dart';
import '../../../core/constants/quran_constants.dart';
import '../../../data/local/db/app_database.dart';
import '../sura_list/sura_list_screen.dart';
import '../recitation/recitation_screen.dart';
import '../reports/reports_screen.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? _lastSession;
  Map<String, dynamic> _overallStats = {};
  bool _isLoading = true;
  int _selectedNavIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final db = AppDatabase.instance;
      final lastSession = await db.getLastSession();
      final stats = await db.getOverallStats();
      if (mounted) {
        setState(() {
          _lastSession = lastSession;
          _overallStats = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.menu_book_rounded, color: Colors.white, size: 24),
              SizedBox(width: 8),
              Text('مُسَمِّع'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined, color: Colors.white),
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.settings_outlined, color: Colors.white),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              ),
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // بطاقة الترحيب
                      _WelcomeCard(lastSession: _lastSession),
                      const SizedBox(height: 16),

                      // إحصاءات سريعة
                      _QuickStats(stats: _overallStats),
                      const SizedBox(height: 16),

                      // إجراءات سريعة
                      _QuickActions(onNavigate: _navigate),
                      const SizedBox(height: 16),

                      // آخر جلسة
                      if (_lastSession != null) ...[
                        _SectionTitle(title: 'آخر جلسة'),
                        _LastSessionCard(session: _lastSession!),
                        const SizedBox(height: 16),
                      ],

                      // اختيار سريع من السور الشائعة
                      _SectionTitle(title: 'السور القصيرة (مُقترحة)'),
                      _QuickSuraList(
                        onSuraSelected: (suraNumber) =>
                            _startRecitation(context, suraNumber),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedNavIndex,
          onTap: (index) {
            setState(() => _selectedNavIndex = index);
            _navigate(index);
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: 'الرئيسية',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.menu_book_rounded),
              label: 'السور',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.mic_rounded),
              label: 'تسميع',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_rounded),
              label: 'التقارير',
            ),
          ],
        ),
      ),
    );
  }

  void _navigate(int index) {
    switch (index) {
      case 0:
        break; // الرئيسية - لا تنقل
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SuraListScreen()),
        );
        break;
      case 2:
        _startRecitationFromBeginning();
        break;
      case 3:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ReportsScreen()),
        ).then((_) => _loadData());
        break;
    }
  }

  void _startRecitationFromBeginning() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const RecitationScreen(pageNumber: 1),
      ),
    ).then((_) => _loadData());
  }

  void _startRecitation(BuildContext context, int suraNumber) {
    final pageNumber = QuranConstants.getSuraPage(suraNumber);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RecitationScreen(pageNumber: pageNumber),
      ),
    ).then((_) => _loadData());
  }
}

// ═══════════════ بطاقة الترحيب ═══════════════
class _WelcomeCard extends StatelessWidget {
  final Map<String, dynamic>? lastSession;

  const _WelcomeCard({this.lastSession});

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    String greeting;
    if (hour < 12) {
      greeting = 'صباح النور';
    } else if (hour < 17) {
      greeting = 'مساء الخير';
    } else {
      greeting = 'أهلاً وسهلاً';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            greeting,
            style: const TextStyle(
              fontFamily: 'Amiri',
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'بِسۡمِ ٱللَّهِ ٱلرَّحۡمَٰنِ ٱلرَّحِيمِ',
            style: TextStyle(
              fontFamily: 'AmiriQuran',
              fontSize: 22,
              color: Colors.white,
              height: 2.0,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'لنبدأ جلسة التسميع اليوم',
            style: TextStyle(
              fontFamily: 'Amiri',
              fontSize: 15,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (lastSession != null) ...[
            const SizedBox(height: 8),
            Text(
              'آخر جلسة: ${lastSession!['sura_name']} — دقة ${(lastSession!['accuracy_percent'] as double).toStringAsFixed(1)}%',
              style: const TextStyle(
                fontFamily: 'Amiri',
                fontSize: 12,
                color: Colors.white70,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ═══════════════ إحصاءات سريعة ═══════════════
class _QuickStats extends StatelessWidget {
  final Map<String, dynamic> stats;

  const _QuickStats({required this.stats});

  @override
  Widget build(BuildContext context) {
    final totalSessions = stats['total_sessions'] ?? 0;
    final avgAccuracy = (stats['avg_accuracy'] as num?)?.toStringAsFixed(1) ?? '0';
    final totalMinutes = ((stats['total_duration'] as int?) ?? 0) ~/ 60;

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            value: '$totalSessions',
            label: 'جلسة',
            icon: Icons.history_rounded,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            value: '$avgAccuracy%',
            label: 'متوسط الدقة',
            icon: Icons.track_changes_rounded,
            color: AppColors.statCorrect,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            value: '$totalMinutes',
            label: 'دقيقة',
            icon: Icons.timer_outlined,
            color: AppColors.secondary,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontFamily: 'Amiri',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Amiri',
                fontSize: 11,
                color: AppColors.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════ إجراءات سريعة ═══════════════
class _QuickActions extends StatelessWidget {
  final Function(int) onNavigate;

  const _QuickActions({required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => onNavigate(2),
            icon: const Icon(Icons.mic_rounded),
            label: const Text('ابدأ التسميع'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => onNavigate(3),
            icon: const Icon(Icons.bar_chart_rounded),
            label: const Text('التقارير'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════ آخر جلسة ═══════════════
class _LastSessionCard extends StatelessWidget {
  final Map<String, dynamic> session;

  const _LastSessionCard({required this.session});

  @override
  Widget build(BuildContext context) {
    final accuracy = (session['accuracy_percent'] as double? ?? 0.0);
    final dateMs = session['date_time_ms'] as int? ?? 0;
    final date = DateTime.fromMillisecondsSinceEpoch(dateMs);
    final duration = session['duration_seconds'] as int? ?? 0;

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primaryLight.withValues(alpha: 0.2),
          child: const Icon(Icons.menu_book_rounded, color: AppColors.primary),
        ),
        title: Text(
          '${session['sura_name']} — آية ${session['start_aya']}',
          style: const TextStyle(
            fontFamily: 'Amiri',
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          '${_formatDate(date)} • ${duration ~/ 60} دقيقة',
          style: const TextStyle(fontFamily: 'Amiri', fontSize: 12),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: accuracy >= 80
                ? AppColors.statCorrect.withValues(alpha: 0.1)
                : AppColors.statWarning.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '${accuracy.toStringAsFixed(1)}%',
            style: TextStyle(
              fontFamily: 'Amiri',
              fontWeight: FontWeight.bold,
              color: accuracy >= 80 ? AppColors.statCorrect : AppColors.statWarning,
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return 'اليوم';
    if (diff.inDays == 1) return 'أمس';
    return '${diff.inDays} أيام';
  }
}

// ═══════════════ السور المقترحة ═══════════════
class _QuickSuraList extends StatelessWidget {
  final Function(int) onSuraSelected;

  const _QuickSuraList({required this.onSuraSelected});

  static const List<int> _shortSuras = [1, 112, 113, 114, 110, 108, 103, 102, 97];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        reverse: true,
        itemCount: _shortSuras.length,
        itemBuilder: (context, index) {
          final suraNumber = _shortSuras[index];
          final suraName = QuranConstants.getSuraName(suraNumber);
          final ayahCount = QuranConstants.getSuraAyahCount(suraNumber);

          return GestureDetector(
            onTap: () => onSuraSelected(suraNumber),
            child: Container(
              width: 90,
              margin: const EdgeInsets.only(left: 8),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    suraName,
                    style: const TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    '$ayahCount آية',
                    style: const TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 11,
                      color: AppColors.textHint,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Amiri',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
