// lib/presentation/components/ui_components.dart
// مكونات UI المشتركة للتطبيق

import 'package:flutter/material.dart';
import '../theme/color.dart';
import '../screens/recitation/recitation_state.dart';

// ═══════════════ Recording Pulse Button ═══════════════
class RecordingPulseButton extends StatefulWidget {
  final RecordingPhase phase;
  final VoidCallback? onTap;
  final double size;

  const RecordingPulseButton({
    super.key,
    required this.phase,
    this.onTap,
    this.size = 80,
  });

  @override
  State<RecordingPulseButton> createState() => _RecordingPulseButtonState();
}

class _RecordingPulseButtonState extends State<RecordingPulseButton>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _waveController;
  late Animation<double> _pulseAnim;
  late Animation<double> _waveAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _waveController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _waveAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _waveController, curve: Curves.easeInOut),
    );
    _updateAnimation();
  }

  @override
  void didUpdateWidget(RecordingPulseButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.phase != oldWidget.phase) {
      _updateAnimation();
    }
  }

  void _updateAnimation() {
    switch (widget.phase) {
      case RecordingPhase.idle:
        _pulseController.stop();
        _waveController.stop();
        _pulseController.reset();
        _waveController.reset();
        break;
      case RecordingPhase.recording:
        _pulseController.repeat(reverse: true);
        _waveController.stop();
        break;
      case RecordingPhase.listening:
        _pulseController.stop();
        _waveController.repeat(reverse: true);
        break;
      case RecordingPhase.processing:
        _pulseController.stop();
        _waveController.stop();
        break;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  Color get _buttonColor {
    switch (widget.phase) {
      case RecordingPhase.idle: return AppColors.recordingIdle;
      case RecordingPhase.recording: return AppColors.recordingActive;
      case RecordingPhase.listening: return AppColors.recordingListening;
      case RecordingPhase.processing: return AppColors.recordingProcessing;
    }
  }

  IconData get _buttonIcon {
    switch (widget.phase) {
      case RecordingPhase.idle: return Icons.mic_rounded;
      case RecordingPhase.recording: return Icons.mic_rounded;
      case RecordingPhase.listening: return Icons.graphic_eq_rounded;
      case RecordingPhase.processing: return Icons.sync_rounded;
    }
  }

  String get _buttonLabel {
    switch (widget.phase) {
      case RecordingPhase.idle: return 'ابدأ التسميع';
      case RecordingPhase.recording: return 'يستمع...';
      case RecordingPhase.listening: return 'يسمع الكلام';
      case RecordingPhase.processing: return 'يعالج...';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: Listenable.merge([_pulseController, _waveController]),
          builder: (context, child) {
            return Stack(
              alignment: Alignment.center,
              children: [
                if (widget.phase == RecordingPhase.recording)
                  Transform.scale(
                    scale: _pulseAnim.value * 1.3,
                    child: Container(
                      width: widget.size,
                      height: widget.size,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _buttonColor.withValues(alpha: 0.15),
                      ),
                    ),
                  ),
                if (widget.phase == RecordingPhase.listening)
                  ...[1.4, 1.6].map(
                    (scale) => Transform.scale(
                      scale: scale * (0.9 + _waveAnim.value * 0.2),
                      child: Container(
                        width: widget.size,
                        height: widget.size,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.recordingListening.withValues(
                            alpha: 0.1 * (2 - scale),
                          ),
                        ),
                      ),
                    ),
                  ),
                GestureDetector(
                  onTap: widget.onTap,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: widget.size,
                    height: widget.size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _buttonColor,
                      boxShadow: [
                        BoxShadow(
                          color: _buttonColor.withValues(alpha: 0.4),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: widget.phase == RecordingPhase.processing
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                          )
                        : Icon(
                            _buttonIcon,
                            color: Colors.white,
                            size: widget.size * 0.45,
                          ),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 8),
        Text(
          _buttonLabel,
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

// ═══════════════ Error Feedback Banner ═══════════════
class ErrorFeedbackBanner extends StatelessWidget {
  final FeedbackState? feedback;
  final VoidCallback? onDismiss;

  const ErrorFeedbackBanner({
    super.key,
    this.feedback,
    this.onDismiss,
  });

  Color get _bgColor {
    switch (feedback?.type) {
      case FeedbackType.success: return AppColors.feedbackSuccessBg;
      case FeedbackType.wrongDiac: return AppColors.feedbackDiacriticsBg;
      case FeedbackType.wrongWord: return AppColors.feedbackErrorBg;
      case FeedbackType.forgotten: return AppColors.feedbackForgottenBg;
      case FeedbackType.skipped: return AppColors.wordHidden;
      case null: return Colors.transparent;
    }
  }

  Color get _borderColor {
    switch (feedback?.type) {
      case FeedbackType.success: return AppColors.feedbackSuccess;
      case FeedbackType.wrongDiac: return AppColors.feedbackDiacritics;
      case FeedbackType.wrongWord: return AppColors.feedbackError;
      case FeedbackType.forgotten: return AppColors.feedbackForgotten;
      case FeedbackType.skipped: return AppColors.textHint;
      case null: return Colors.transparent;
    }
  }

  Color get _textColor {
    switch (feedback?.type) {
      case FeedbackType.success: return AppColors.feedbackSuccess;
      case FeedbackType.wrongDiac: return AppColors.feedbackDiacritics;
      case FeedbackType.wrongWord: return AppColors.feedbackError;
      case FeedbackType.forgotten: return AppColors.feedbackForgotten;
      case FeedbackType.skipped: return AppColors.textSecondary;
      case null: return Colors.transparent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        );
      },
      child: feedback != null
          ? _buildBanner()
          : const SizedBox.shrink(),
    );
  }

  Widget _buildBanner() {
    return GestureDetector(
      onTap: onDismiss,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: _bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _borderColor, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: _borderColor.withValues(alpha: 0.2),
              blurRadius: 8,
            ),
          ],
        ),
        child: Row(
          textDirection: TextDirection.rtl,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    feedback!.message,
                    style: TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 14,
                      color: _textColor,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                  ),
                  if (feedback!.expectedWord.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      feedback!.expectedWord,
                      style: const TextStyle(
                        fontFamily: 'AmiriQuran',
                        fontSize: 18,
                        color: AppColors.textQuran,
                        height: 1.8,
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(_getIcon(), color: _borderColor, size: 26),
          ],
        ),
      ),
    );
  }

  IconData _getIcon() {
    switch (feedback?.type) {
      case FeedbackType.success: return Icons.check_circle_rounded;
      case FeedbackType.wrongDiac: return Icons.text_fields_rounded;
      case FeedbackType.wrongWord: return Icons.cancel_rounded;
      case FeedbackType.forgotten: return Icons.pause_circle_rounded;
      case FeedbackType.skipped: return Icons.skip_next_rounded;
      case null: return Icons.info_rounded;
    }
  }
}
