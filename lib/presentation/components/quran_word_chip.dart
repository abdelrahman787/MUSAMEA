// lib/presentation/components/quran_word_chip.dart

import 'package:flutter/material.dart';
import '../theme/color.dart';
import '../screens/recitation/recitation_state.dart';

class QuranWordChip extends StatefulWidget {
  final String word;
  final WordDisplayState displayState;
  final double fontSize;
  final VoidCallback? onTap;

  const QuranWordChip({
    super.key,
    required this.word,
    required this.displayState,
    this.fontSize = 22.0,
    this.onTap,
  });

  @override
  State<QuranWordChip> createState() => _QuranWordChipState();
}

class _QuranWordChipState extends State<QuranWordChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (widget.displayState == WordDisplayState.waiting) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(QuranWordChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.displayState == WordDisplayState.waiting) {
      _pulseController.repeat(reverse: true);
    } else {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          return Transform.scale(
            scale: widget.displayState == WordDisplayState.waiting
                ? _pulseAnimation.value
                : 1.0,
            child: _buildWordWidget(),
          );
        },
      ),
    );
  }

  Widget _buildWordWidget() {
    switch (widget.displayState) {
      case WordDisplayState.hidden:
        return _buildHiddenWord();
      case WordDisplayState.waiting:
        return _buildWaitingWord();
      case WordDisplayState.correct:
        return _buildColoredWord(
          AppColors.wordCorrect,
          backgroundColor: AppColors.wordCorrectBg,
        );
      case WordDisplayState.wrongDiacritics:
        return _buildColoredWord(
          AppColors.wordWrongDiac,
          backgroundColor: AppColors.wordWrongDiacBg,
          hasUnderline: true,
        );
      case WordDisplayState.wrongWord:
        return _buildColoredWord(
          AppColors.wordWrongWord,
          backgroundColor: AppColors.wordWrongWordBg,
          hasStrikethrough: true,
        );
      case WordDisplayState.forgotten:
        return _buildColoredWord(
          AppColors.wordForgotten,
          backgroundColor: AppColors.wordForgottenBg,
        );
      case WordDisplayState.visibleHint:
        return _buildHintWord();
      case WordDisplayState.skipped:
        return _buildColoredWord(
          AppColors.textHint,
          backgroundColor: AppColors.wordHidden,
        );
    }
  }

  Widget _buildHiddenWord() {
    // كلمة مخفية: مستطيل رمادي بنفس عرض الكلمة تقريباً
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.wordHidden,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        widget.word,
        style: TextStyle(
          fontFamily: 'AmiriQuran',
          fontSize: widget.fontSize,
          color: Colors.transparent,
          height: 2.0,
        ),
        textDirection: TextDirection.rtl,
      ),
    );
  }

  Widget _buildWaitingWord() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.wordHidden,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.wordWaitingBorder,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Text(
        '؟',
        style: TextStyle(
          fontFamily: 'AmiriQuran',
          fontSize: widget.fontSize * 0.8,
          color: AppColors.primary,
          height: 2.0,
        ),
        textDirection: TextDirection.rtl,
      ),
    );
  }

  Widget _buildColoredWord(
    Color textColor, {
    Color? backgroundColor,
    bool hasUnderline = false,
    bool hasStrikethrough = false,
  }) {
    TextDecoration? decoration;
    if (hasUnderline && hasStrikethrough) {
      decoration = TextDecoration.combine([
        TextDecoration.underline,
        TextDecoration.lineThrough,
      ]);
    } else if (hasUnderline) {
      decoration = TextDecoration.underline;
    } else if (hasStrikethrough) {
      decoration = TextDecoration.lineThrough;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.transparent,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        widget.word,
        style: TextStyle(
          fontFamily: 'AmiriQuran',
          fontSize: widget.fontSize,
          color: textColor,
          height: 2.0,
          decoration: decoration,
          decorationColor: textColor,
          decorationThickness: 2,
        ),
        textDirection: TextDirection.rtl,
      ),
    );
  }

  Widget _buildHintWord() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Text(
        widget.word,
        style: TextStyle(
          fontFamily: 'AmiriQuran',
          fontSize: widget.fontSize,
          color: AppColors.wordHint.withValues(alpha: 0.5),
          height: 2.0,
        ),
        textDirection: TextDirection.rtl,
      ),
    );
  }
}
