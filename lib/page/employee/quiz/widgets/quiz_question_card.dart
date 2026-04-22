import 'package:flutter/material.dart';
import 'package:smet/model/Employee_quiz_model.dart';
import 'package:smet/page/employee/quiz/widgets/quiz_option_item.dart';
import 'package:smet/page/employee/quiz/widgets/quiz_exam_theme.dart';

class QuizQuestionCard extends StatelessWidget {
  final QuizQuestion question;
  final int questionIndex;
  final int totalQuestions;
  final List<String> selectedOptionIds;
  final QuestionDisplayMode mode;
  final bool showResult;
  final Function(String) onOptionSelected;
  final bool isFlagged;
  final VoidCallback onToggleFlag;

  const QuizQuestionCard({
    super.key,
    required this.question,
    required this.questionIndex,
    required this.totalQuestions,
    required this.selectedOptionIds,
    required this.mode,
    this.showResult = false,
    required this.onOptionSelected,
    required this.isFlagged,
    required this.onToggleFlag,
  });

  String get _questionTypeLabel {
    switch (mode) {
      case QuestionDisplayMode.single:
        return 'SINGLECHOICE';
      case QuestionDisplayMode.multiple:
        return 'MULTIPLECHOICE';
      case QuestionDisplayMode.trueFalse:
        return 'TRUEFALSE';
    }
  }

  String get _questionTypeHint {
    switch (mode) {
      case QuestionDisplayMode.single:
        return 'Chọn 1 đáp án đúng';
      case QuestionDisplayMode.multiple:
        return 'Chọn tất cả đáp án đúng';
      case QuestionDisplayMode.trueFalse:
        return 'Chọn Đúng hoặc Sai';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: QuizExamTheme.surfaceContainerLowest,
        borderRadius: QuizExamTheme.cardRadius,
        boxShadow: [QuizExamTheme.cardShadowLight],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  question.content,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: QuizExamTheme.onSurface,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                ...question.options.asMap().entries.map((entry) {
                  final index = entry.key;
                  final option = entry.value;
                  final isSelected = selectedOptionIds.contains(option.id);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: QuizOptionItem(
                      optionId: option.id,
                      content: option.content,
                      isSelected: isSelected,
                      isCorrect: option.isCorrect,
                      showResult: showResult,
                      mode: mode,
                      optionIndex: index,
                      onTap: () => onOptionSelected(option.id),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: QuizExamTheme.outlineVariant, width: 1),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: QuizExamTheme.primaryFixed,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'CÂU ${questionIndex + 1} ($_questionTypeLabel)',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: QuizExamTheme.primary,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              _questionTypeHint,
              style: const TextStyle(
                fontSize: 13,
                color: QuizExamTheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 16),
            _buildProgressIndicator(),
            const SizedBox(width: 12),
            IconButton(
              onPressed: onToggleFlag,
              icon: Icon(
                isFlagged ? Icons.flag : Icons.flag_outlined,
                color: isFlagged ? QuizExamTheme.tertiary : QuizExamTheme.onSurfaceVariant,
              ),
              tooltip: isFlagged ? 'Bỏ đánh dấu' : 'Đánh dấu để xem lại',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    final percent = ((questionIndex + 1) / totalQuestions * 100).round();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 100,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (questionIndex + 1) / totalQuestions,
              minHeight: 6,
              backgroundColor: QuizExamTheme.secondaryContainer,
              valueColor: const AlwaysStoppedAnimation<Color>(QuizExamTheme.primary),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$percent%',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: QuizExamTheme.primary,
          ),
        ),
      ],
    );
  }
}
