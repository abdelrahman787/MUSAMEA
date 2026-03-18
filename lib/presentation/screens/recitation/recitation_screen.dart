// lib/presentation/screens/recitation/recitation_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/color.dart';
import '../../components/quran_word_chip.dart';
import '../../components/ui_components.dart';
import '../../../data/models/quran_verse.dart';
import '../../../core/constants/quran_constants.dart';
import '../../../di/app_providers.dart';
import 'recitation_state.dart';
import 'recitation_view_model.dart';

class RecitationScreen extends StatefulWidget {
  final int pageNumber;
  final RecitationMode mode;

  const RecitationScreen({
    super.key,
    required this.pageNumber,
    this.mode = RecitationMode.hidden,
  });

  @override
  State<RecitationScreen> createState() => _RecitationScreenState();
}

class _RecitationScreenState extends State<RecitationScreen> {
  late RecitationViewModel _vm;

  @override
  void initState() {
    super.initState();
    final deps = AppDependencies.instance;
    _vm = RecitationViewModel(
      quranDb: deps.quranDb,
      appDb: deps.appDb,
      wordMatcher: deps.wordMatcher,
      audioService: deps.audioService,
      asrEngine: deps.asrEngine,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _vm.startSession(pageNumber: widget.pageNumber, mode: widget.mode);
    });
  }

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _vm,
      child: const _RecitationView(),
    );
  }
}

class _RecitationView extends StatelessWidget {
  const _RecitationView();

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Consumer<RecitationViewModel>(
          builder: (context, vm, _) {
            final state = vm.state;

            if (state.isSessionComplete) {
              return _SessionCompleteView(vm: vm);
            }

            return Column(
              children: [
                // ١. شريط العنوان
                _RecitationAppBar(state: state, vm: vm),

                // ٢. منطقة المصحف (70% من الشاشة)
                Expanded(
                  flex: 7,
                  child: _MushafArea(state: state),
                ),

                // ٣. شريط الإحصاءات (10%)
                _StatsBar(state: state),

                // ٤. التغذية الراجعة
                ErrorFeedbackBanner(
                  feedback: state.feedback,
                  onDismiss: vm.dismissFeedback,
                ),

                // ٥. شريط التحكم السفلي (20%)
                _ControlBar(state: state, vm: vm),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ═══════════════ AppBar ═══════════════
class _RecitationAppBar extends StatelessWidget implements PreferredSizeWidget {
  final RecitationUiState state;
  final RecitationViewModel vm;

  const _RecitationAppBar({required this.state, required this.vm});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final currentWord = state.currentWord;
    final suraName = currentWord != null
        ? QuranConstants.getSuraName(currentWord.suraNumber)
        : 'التسميع';
    final pageNum = state.currentPage?.pageNumber ?? 0;

    return SafeArea(
      child: Container(
        height: 56,
        decoration: const BoxDecoration(
          color: AppColors.primary,
          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
        ),
        child: Row(
          children: [
            // زر الرجوع
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios, color: Colors.white),
              onPressed: () {
                vm.endSession();
                Navigator.of(context).pop();
              },
              tooltip: 'رجوع',
            ),

            // العنوان
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    suraName,
                    style: const TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  if (pageNum > 0)
                    Text(
                      'صفحة $pageNum',
                      style: const TextStyle(
                        fontFamily: 'Amiri',
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                ],
              ),
            ),

            // تبديل الوضع
            IconButton(
              icon: Icon(
                state.mode == RecitationMode.hidden
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
                color: Colors.white,
              ),
              onPressed: vm.toggleMode,
              tooltip: state.mode == RecitationMode.hidden ? 'إظهار' : 'إخفاء',
            ),

            // الإعدادات
            IconButton(
              icon: const Icon(Icons.settings_rounded, color: Colors.white),
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════ منطقة المصحف ═══════════════
class _MushafArea extends StatelessWidget {
  final RecitationUiState state;

  const _MushafArea({required this.state});

  @override
  Widget build(BuildContext context) {
    final page = state.currentPage;

    // ─── حالة التحميل ───────────────────────────────
    if (state.isLoading) {
      return Container(
        decoration: const BoxDecoration(gradient: AppColors.mushafahBackground),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: AppColors.primary, strokeWidth: 3),
              const SizedBox(height: 16),
              Text(
                state.loadingMessage ?? 'جاري تحميل الصفحة…',
                style: const TextStyle(
                  fontFamily: 'Amiri', fontSize: 18, color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'يتم جلب البيانات من الخادم',
                style: TextStyle(
                  fontFamily: 'Amiri', fontSize: 13, color: AppColors.textHint,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // ─── حالة الخطأ ──────────────────────────────────
    if (state.error != null && page == null) {
      return Container(
        decoration: const BoxDecoration(gradient: AppColors.mushafahBackground),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.wifi_off_rounded, size: 56, color: AppColors.statError),
                const SizedBox(height: 16),
                Text(
                  state.error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Amiri', fontSize: 16, color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // ─── لا شيء بعد ──────────────────────────────────
    if (page == null) {
      return Container(
        decoration: const BoxDecoration(gradient: AppColors.mushafahBackground),
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.mushafahBackground,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: page.verses
              .map((verse) => _VerseRow(
                    verse: verse,
                    wordStates: state.wordStates,
                    currentWordKey: state.currentWordKey,
                  ))
              .toList(),
        ),
      ),
    );
  }
}

class _VerseRow extends StatelessWidget {
  final QuranVerse verse;
  final Map<String, WordDisplayState> wordStates;
  final String? currentWordKey;

  const _VerseRow({
    required this.verse,
    required this.wordStates,
    required this.currentWordKey,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // رقم الآية
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _VerseNumberBadge(verseKey: verse.verseKey),
              const SizedBox(),
            ],
          ),
          // كلمات الآية - مرتبة RTL
          Directionality(
            textDirection: TextDirection.rtl,
            child: Wrap(
              alignment: WrapAlignment.start,
              textDirection: TextDirection.rtl,
              children: verse.words.map((word) {
                final displayState =
                    wordStates[word.wordKey] ?? WordDisplayState.hidden;
                return QuranWordChip(
                  word: word.textUthmani,
                  displayState: displayState,
                  fontSize: 22,
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _VerseNumberBadge extends StatelessWidget {
  final String verseKey;

  const _VerseNumberBadge({required this.verseKey});

  @override
  Widget build(BuildContext context) {
    final parts = verseKey.split(':');
    final ayaNumber = parts.length > 1 ? parts[1] : '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.secondary.withValues(alpha: 0.5),
        ),
      ),
      child: Text(
        '﴿$ayaNumber﴾',
        style: const TextStyle(
          fontFamily: 'Amiri',
          fontSize: 12,
          color: AppColors.secondary,
        ),
      ),
    );
  }
}

// ═══════════════ شريط الإحصاءات ═══════════════
class _StatsBar extends StatelessWidget {
  final RecitationUiState state;

  const _StatsBar({required this.state});

  @override
  Widget build(BuildContext context) {
    final stats = state.sessionStats;
    final total = state.allWords.length;
    final progress = state.progressPercent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _StatBadge(
                value: stats.correctWords,
                label: 'صحيح',
                color: AppColors.statCorrect,
                icon: Icons.check_circle_outline,
              ),
              _StatBadge(
                value: stats.wrongWordErrors + stats.diacriticsErrors,
                label: 'خطأ',
                color: AppColors.statError,
                icon: Icons.error_outline,
              ),
              _StatBadge(
                value: stats.forgottenWords,
                label: 'منسي',
                color: AppColors.statForgotten,
                icon: Icons.hourglass_empty,
              ),
              _StatBadge(
                value: total,
                label: 'إجمالي',
                color: AppColors.textSecondary,
                icon: Icons.format_list_numbered,
              ),
            ],
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: AppColors.wordHidden,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            minHeight: 4,
            borderRadius: BorderRadius.circular(2),
          ),
          const SizedBox(height: 2),
          Text(
            '${(progress * 100).toInt()}% مكتمل',
            style: const TextStyle(
              fontFamily: 'Amiri',
              fontSize: 11,
              color: AppColors.textHint,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final int value;
  final String label;
  final Color color;
  final IconData icon;

  const _StatBadge({
    required this.value,
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 3),
            Text(
              '$value',
              style: TextStyle(
                fontFamily: 'Amiri',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
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
    );
  }
}

// ═══════════════ شريط التحكم السفلي ═══════════════
class _ControlBar extends StatelessWidget {
  final RecitationUiState state;
  final RecitationViewModel vm;

  const _ControlBar({required this.state, required this.vm});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // زر التلميح (يسار)
            _SmallActionButton(
              icon: Icons.lightbulb_outline,
              label: 'تلميح',
              color: AppColors.secondary,
              onTap: vm.showHint,
            ),

            const SizedBox(width: 16),

            // الزر الرئيسي
            RecordingPulseButton(
              phase: state.recordingPhase,
              onTap: () {
                if (!state.isRecording) {
                  vm.startSession(
                    pageNumber: state.currentPage?.pageNumber ?? 1,
                    mode: state.mode,
                  );
                }
              },
              size: 72,
            ),

            const SizedBox(width: 16),

            // زر التخطي (يمين)
            _SmallActionButton(
              icon: Icons.skip_next_rounded,
              label: 'تخطّي',
              color: AppColors.textSecondary,
              onTap: vm.skipCurrentWord,
            ),
          ],
        ),
      ),
    );
  }
}

class _SmallActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _SmallActionButton({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Amiri',
              fontSize: 11,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════ شاشة اكتمال الجلسة ═══════════════
class _SessionCompleteView extends StatelessWidget {
  final RecitationViewModel vm;

  const _SessionCompleteView({required this.vm});

  @override
  Widget build(BuildContext context) {
    final stats = vm.state.sessionStats;
    final accuracy = stats.accuracyPercent;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 32),
              // أيقونة النجاح
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  size: 60,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'أحسنتَ! اكتملت الجلسة',
                style: TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 32),

              // بطاقة الإحصاءات
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _ResultStat(
                            value: '${accuracy.toStringAsFixed(1)}%',
                            label: 'الدقة',
                            color: accuracy >= 80
                                ? AppColors.statCorrect
                                : accuracy >= 60
                                    ? AppColors.statWarning
                                    : AppColors.statError,
                          ),
                          _ResultStat(
                            value: '${stats.correctWords}',
                            label: 'صحيح',
                            color: AppColors.statCorrect,
                          ),
                          _ResultStat(
                            value: '${stats.forgottenWords}',
                            label: 'منسي',
                            color: AppColors.statForgotten,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      LinearProgressIndicator(
                        value: accuracy / 100,
                        backgroundColor: AppColors.wordHidden,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          accuracy >= 80
                              ? AppColors.statCorrect
                              : accuracy >= 60
                                  ? AppColors.statWarning
                                  : AppColors.statError,
                        ),
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // أزرار الإجراء
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.home_rounded),
                      label: const Text('العودة للرئيسية'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        vm.endSession();
                        // إعادة بدء الجلسة
                        vm.startSession(
                          pageNumber: vm.state.currentPage?.pageNumber ?? 1,
                          mode: vm.state.mode,
                        );
                      },
                      icon: const Icon(Icons.replay_rounded),
                      label: const Text('تكرار الصفحة'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultStat extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _ResultStat({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Amiri',
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Amiri',
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
