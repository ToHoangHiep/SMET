import 'package:flutter/material.dart';
import 'package:smet/model/Employee_quiz_model.dart';
import 'package:smet/page/employee/quiz/widgets/quiz_exam_theme.dart';

class QuizResultDialog extends StatelessWidget {
  final QuizResult result;
  final VoidCallback onRetry;
  final VoidCallback onClose;

  const QuizResultDialog({
    super.key,
    required this.result,
    required this.onRetry,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        decoration: BoxDecoration(
          color: QuizExamTheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.16),
              blurRadius: 32,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(context),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                children: [
                  _buildScoreSection(context),
                  const SizedBox(height: 20),
                  _buildStats(),
                  const SizedBox(height: 24),
                  _buildActions(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors:
              result.passed
                  ? [QuizExamTheme.primary, QuizExamTheme.primaryContainer]
                  : [QuizExamTheme.error, const Color(0xFFD32F2F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              result.passed ? Icons.emoji_events : Icons.refresh,
              size: 36,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            result.passed ? 'Chúc mừng!' : 'Chưa đạt',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            result.passed
                ? 'Bạn đã hoàn thành bài quiz!'
                : 'Hãy thử lại để cải thiện điểm số',
            style: const TextStyle(fontSize: 14, color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildScoreSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          Text(
            '${result.percentage.toStringAsFixed(0)}%',
            style: TextStyle(
              fontSize: 52,
              fontWeight: FontWeight.w800,
              color:
                  result.passed ? QuizExamTheme.primary : QuizExamTheme.error,
              height: 1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${result.totalScore}/${result.maxScore} điểm',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: QuizExamTheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: QuizExamTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _statItem(
              Icons.check_circle_outline,
              '${result.correctCount}/${result.totalQuestions}',
              'Câu đúng',
              QuizExamTheme.answeredGreen,
            ),
            Container(
              width: 1,
              height: 40,
              color: QuizExamTheme.outlineVariant,
            ),
            _statItem(
              Icons.timer_outlined,
              _formatDuration(result.timeSpent),
              'Thời gian',
              QuizExamTheme.primary,
            ),
            Container(
              width: 1,
              height: 40,
              color: QuizExamTheme.outlineVariant,
            ),
            _statItem(
              Icons.trending_up,
              '${result.percentage.toStringAsFixed(0)}%',
              'Tỷ lệ',
              result.passed ? QuizExamTheme.answeredGreen : QuizExamTheme.error,
            ),
          ],
        ),
      ),
    );
  }

  Widget _statItem(IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: QuizExamTheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes}m ${seconds}s';
  }

  Widget _buildActions(BuildContext context) {
    return Row(
      children: [
        if (!result.passed) ...[
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Làm lại'),
              style: OutlinedButton.styleFrom(
                foregroundColor: QuizExamTheme.primary,
                side: const BorderSide(
                  color: QuizExamTheme.primary,
                  width: 1.5,
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: ElevatedButton(
            onPressed: onClose,
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  result.passed
                      ? QuizExamTheme.primary
                      : QuizExamTheme.secondary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              result.passed ? 'Tiếp tục' : 'Đóng',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }
}
