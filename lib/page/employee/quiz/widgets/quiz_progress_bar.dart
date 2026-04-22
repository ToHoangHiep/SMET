import 'package:flutter/material.dart';
import 'package:smet/page/employee/quiz/widgets/quiz_exam_theme.dart';

class QuizProgressBar extends StatelessWidget {
  final int currentIndex;
  final int totalQuestions;
  final Set<int> answeredQuestions;
  final Set<int> flaggedQuestions;

  const QuizProgressBar({
    super.key,
    required this.currentIndex,
    required this.totalQuestions,
    required this.answeredQuestions,
    required this.flaggedQuestions,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (currentIndex + 1) / totalQuestions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Câu ${currentIndex + 1}/$totalQuestions',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: QuizExamTheme.onSurface,
              ),
            ),
            Text(
              '${(progress * 100).round()}% Complete',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: QuizExamTheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: QuizExamTheme.secondaryContainer,
            valueColor: const AlwaysStoppedAnimation<Color>(QuizExamTheme.primary),
          ),
        ),
      ],
    );
  }
}
