import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:smet/model/Employee_quiz_model.dart';
import 'package:smet/page/shared/widgets/app_toast.dart';
import 'package:smet/service/employee/quiz_service.dart';
import 'package:smet/page/employee/quiz/widgets/quiz_exam_theme.dart';
import 'package:smet/page/employee/quiz/widgets/quiz_question_card.dart';
import 'package:smet/page/employee/quiz/widgets/quiz_timer.dart';
import 'package:smet/page/employee/quiz/widgets/quiz_progress_bar.dart';
import 'package:smet/page/employee/quiz/widgets/quiz_result_dialog.dart';

// ──────────────────────────────────────────────────────────────────────────────
// ENTRY POINTS
// ──────────────────────────────────────────────────────────────────────────────

class QuizPage extends StatelessWidget {
  final String quizId;
  final String? courseId;
  final String? attemptId; // Thêm: để resume attempt cũ

  const QuizPage({
    super.key,
    required this.quizId,
    this.courseId,
    this.attemptId,
  });

  @override
  Widget build(BuildContext context) {
    final isWebOrDesktop = kIsWeb ||
        MediaQuery.of(context).size.width >= 768 ||
        !Platform.isAndroid && !Platform.isIOS;

    return QuizBasePage(
      quizId: quizId,
      isWebLayout: isWebOrDesktop,
      courseId: courseId,
      resumeAttemptId: attemptId,
    );
  }
}

class QuizBasePage extends StatefulWidget {
  final String quizId;
  final bool isWebLayout;
  final String? courseId;
  final String? resumeAttemptId; // Thêm: attempt cần resume

  const QuizBasePage({
    super.key,
    required this.quizId,
    this.isWebLayout = false,
    this.courseId,
    this.resumeAttemptId,
  });

  @override
  State<QuizBasePage> createState() => _QuizBasePageState();
}

class _QuizBasePageState extends State<QuizBasePage> {
  late final QuizInternalController _controller;

  @override
  void initState() {
    super.initState();
    _controller = QuizInternalController(
      quizId: widget.quizId,
      courseId: widget.courseId,
      resumeAttemptId: widget.resumeAttemptId,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, child) {
        if (widget.isWebLayout) {
          return _QuizWebView(controller: _controller);
        }
        return _QuizMobileView(controller: _controller);
      },
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// TOP NAVBAR
// ──────────────────────────────────────────────────────────────────────────────

class _QuizTopNavBar extends StatelessWidget {
  final String? quizTitle;

  const _QuizTopNavBar({this.quizTitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: QuizExamTheme.surfaceContainerLowest.withValues(alpha: 0.85),
        border: const Border(
          bottom: BorderSide(color: QuizExamTheme.outlineVariant, width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: QuizExamTheme.onSurfaceVariant,
            ),
            tooltip: 'Quay lại',
          ),
          if (quizTitle != null) ...[
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                quizTitle!,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: QuizExamTheme.onSurface,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ] else
            const Spacer(),
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.notifications_outlined,
              color: QuizExamTheme.onSurfaceVariant,
              size: 22,
            ),
            tooltip: 'Thông báo',
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// WEB LAYOUT
// ──────────────────────────────────────────────────────────────────────────────

class _QuizWebView extends StatelessWidget {
  final QuizInternalController controller;

  const _QuizWebView({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QuizExamTheme.background,
      body: Column(
        children: [
          _QuizTopNavBar(quizTitle: controller.quiz?.title),
          Expanded(
            child: ListenableBuilder(
              listenable: controller,
              builder: (context, child) {
                if (controller.isLoading && controller.quiz == null) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: QuizExamTheme.primary,
                    ),
                  );
                }

                if (controller.error != null) {
                  return _buildErrorState(context);
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Left: Quiz Content ──────────────────────────────
                    Expanded(
                      flex: 8,
                      child: _QuizMainContent(controller: controller),
                    ),
                    // ── Right: Sidebar ───────────────────────────────────
                    Container(
                      width: 320,
                      margin: const EdgeInsets.only(top: 24, bottom: 24, right: 24),
                      child: _QuizSidebar(controller: controller),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    final isResetProgress = controller.error == 'RESET_PROGRESS';

    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          color: QuizExamTheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isResetProgress
                ? QuizExamTheme.tertiary.withValues(alpha: 0.5)
                : QuizExamTheme.error.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isResetProgress ? Icons.replay_rounded : Icons.error_outline,
              size: 56,
              color: isResetProgress ? QuizExamTheme.tertiary : QuizExamTheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              isResetProgress
                  ? 'Bạn cần học lại bài học'
                  : (controller.error ?? 'Đã xảy ra lỗi'),
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: QuizExamTheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              isResetProgress
                  ? 'Bạn đã hết lượt thi và tiến trình đã được reset. Vui lòng học lại các bài học trước khi làm bài kiểm tra.'
                  : 'Vui lòng thử lại sau.',
              style: TextStyle(
                fontSize: 14,
                color: QuizExamTheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (isResetProgress) ...[
              // Nút quay về khóa học
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Quay về learning workspace
                    GoRouter.of(context).go(
                      '/employee/learn/${controller.courseId ?? ''}',
                    );
                  },
                  icon: const Icon(Icons.school_rounded, size: 20),
                  label: const Text(' Quay về khóa học'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: QuizExamTheme.tertiary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Nút tải lại trang
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    GoRouter.of(context).go(
                      '/employee/quiz-detail/${controller.quizId}?courseId=${controller.courseId ?? ''}',
                    );
                  },
                  icon: const Icon(Icons.refresh, size: 20),
                  label: const Text(' Kiểm tra lại'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: QuizExamTheme.onSurface,
                    side: const BorderSide(color: QuizExamTheme.outlineVariant),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ] else ...[
              ElevatedButton.icon(
                onPressed: controller.loadQuiz,
                icon: const Icon(Icons.refresh),
                label: const Text('Thử lại'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: QuizExamTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// MAIN CONTENT (Web)
// ──────────────────────────────────────────────────────────────────────────────

class _QuizMainContent extends StatelessWidget {
  final QuizInternalController controller;

  const _QuizMainContent({required this.controller});

  @override
  Widget build(BuildContext context) {
    final question = controller.currentQuestion;
    if (question == null) return const SizedBox();

    final selectedIds = controller.getSelectedOptions(question.id);

    QuestionDisplayMode displayMode;
    switch (question.type) {
      case QuestionType.single:
        displayMode = QuestionDisplayMode.single;
        break;
      case QuestionType.multiple:
        displayMode = QuestionDisplayMode.multiple;
        break;
      case QuestionType.trueFalse:
        displayMode = QuestionDisplayMode.trueFalse;
        break;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Question Header ────────────────────────────────────────────
          _buildQuestionHeader(context, question),
          const SizedBox(height: 20),
          // ── Progress Bar ──────────────────────────────────────────────
          _buildProgressBar(context),
          const SizedBox(height: 20),
          // ── Question Card ──────────────────────────────────────────────
          QuizQuestionCard(
            question: question,
            questionIndex: controller.currentIndex,
            totalQuestions: controller.quiz!.questions.length,
            selectedOptionIds: selectedIds,
            mode: displayMode,
            showResult: false,
            onOptionSelected: controller.selectOption,
            isFlagged: controller.isCurrentFlagged,
            onToggleFlag: controller.toggleFlag,
          ),
          const SizedBox(height: 20),
          // ── Navigation Buttons ──────────────────────────────────────────
          _buildNavButtons(context),
        ],
      ),
    );
  }

  Widget _buildQuestionHeader(BuildContext context, QuizQuestion question) {
    final isFlagged = controller.isCurrentFlagged;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Type badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: QuizExamTheme.primaryFixed,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              _questionTypeBadge(question.type),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: QuizExamTheme.primary,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Quiz title (question topic)
          if (controller.quiz?.title != null)
            Flexible(
              child: Text(
                controller.quiz!.title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: QuizExamTheme.onSurface,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          const SizedBox(width: 16),
          // Timer
          if (controller.quiz != null)
            QuizTimer(
              totalSeconds: controller.quiz!.timeLimitMinutes * 60,
              onTimeUp: () => controller.handleAutoSubmit(context),
            ),
          const SizedBox(width: 12),
          // Flag button
          IconButton(
            onPressed: controller.toggleFlag,
            icon: Icon(
              isFlagged ? Icons.flag : Icons.flag_outlined,
              color: isFlagged ? QuizExamTheme.tertiary : QuizExamTheme.onSurfaceVariant,
            ),
            tooltip: isFlagged ? 'Bỏ đánh dấu' : 'Đánh dấu để xem lại',
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(BuildContext context) {
    return QuizProgressBar(
      currentIndex: controller.currentIndex,
      totalQuestions: controller.quiz!.questions.length,
      answeredQuestions: controller.answeredQuestions,
      flaggedQuestions: controller.flaggedQuestions,
    );
  }

  Widget _buildNavButtons(BuildContext context) {
    final isFirst = controller.currentIndex == 0;
    final isLast = controller.isLastQuestion;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Previous
          _QuizNavButton(
            label: 'Trước',
            icon: Icons.arrow_back_rounded,
            outlined: true,
            enabled: !isFirst,
            onPressed: controller.previousQuestion,
          ),
          const SizedBox(width: 12),
          // Reload
          _QuizNavButton(
            label: 'Tải lại',
            icon: Icons.refresh_rounded,
            outlined: true,
            color: QuizExamTheme.onSurfaceVariant,
            enabled: true,
            onPressed: () => _showReloadDialog(context),
          ),
          const SizedBox(width: 12),
          // Next
          _QuizNavButton(
            label: 'Tiếp theo',
            icon: Icons.arrow_forward_rounded,
            outlined: false,
            enabled: !isLast,
            onPressed: controller.nextQuestion,
          ),
        ],
      ),
    );
  }

  String _questionTypeBadge(QuestionType type) {
    switch (type) {
      case QuestionType.single:
        return 'SINGLECHOICE';
      case QuestionType.multiple:
        return 'MULTIPLECHOICE';
      case QuestionType.trueFalse:
        return 'TRUEFALSE';
    }
  }

  void _showReloadDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: QuizExamTheme.surfaceContainerLowest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Tải lại bài?'),
        content: const Text(
          'Tiến trình hiện tại sẽ bị mất. Bạn có chắc muốn tải lại bài?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              controller.reset();
              controller.loadQuiz();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: QuizExamTheme.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Tải lại'),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// SIDEBAR (Web)
// ──────────────────────────────────────────────────────────────────────────────

class _QuizSidebar extends StatelessWidget {
  final QuizInternalController controller;

  const _QuizSidebar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Question Map ────────────────────────────────────────────────
        _buildQuestionMapCard(context),
        const SizedBox(height: 12),
        // ── Action Buttons ─────────────────────────────────────────────
        _buildActionButtons(context),
        const SizedBox(height: 12),
        // ── Legend ─────────────────────────────────────────────────────
        _buildLegendCard(context),
      ],
    );
  }

  Widget _buildQuestionMapCard(BuildContext context) {
    final total = controller.quiz?.questions.length ?? 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: QuizExamTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [QuizExamTheme.cardShadowLight],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Question Map',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: QuizExamTheme.onSurface,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemCount: total,
            itemBuilder: (context, index) {
              return _buildQuestionDot(context, index);
            },
          ),
          const SizedBox(height: 16),
          // Progress summary
          _buildProgressSummary(),
        ],
      ),
    );
  }

  Widget _buildQuestionDot(BuildContext context, int index) {
    final isAnswered = controller.answeredQuestions.contains(index);
    final isFlagged = controller.flaggedQuestions.contains(index);
    final isCurrent = index == controller.currentIndex;

    Color bgColor;
    Color borderColor;
    Color textColor;

    if (isCurrent) {
      bgColor = Colors.transparent;
      borderColor = QuizExamTheme.primary;
      textColor = QuizExamTheme.primary;
    } else if (isAnswered) {
      bgColor = QuizExamTheme.answeredGreen;
      borderColor = QuizExamTheme.answeredGreen;
      textColor = Colors.white;
    } else {
      bgColor = QuizExamTheme.surfaceContainerHighest;
      borderColor = Colors.transparent;
      textColor = QuizExamTheme.onSurfaceVariant;
    }

    return InkWell(
      onTap: () => controller.goToQuestion(index),
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor, width: isCurrent ? 2 : 0),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              '${index + 1}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: isCurrent || isAnswered ? FontWeight.w700 : FontWeight.w500,
                color: textColor,
              ),
            ),
            if (isFlagged)
              Positioned(
                top: 2,
                right: 2,
                child: Icon(
                  Icons.star,
                  size: 10,
                  color: QuizExamTheme.flaggedOrange,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressSummary() {
    final answered = controller.answeredCount;
    final total = controller.quiz?.questions.length ?? 0;
    final remaining = total - answered;

    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: QuizExamTheme.answeredGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Text(
                  '$answered',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: QuizExamTheme.answeredGreen,
                  ),
                ),
                const Text(
                  'Đã trả lời',
                  style: TextStyle(fontSize: 11, color: QuizExamTheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: QuizExamTheme.tertiaryFixed.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Text(
                  '$remaining',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: QuizExamTheme.tertiary,
                  ),
                ),
                const Text(
                  'Chưa trả lời',
                  style: TextStyle(fontSize: 11, color: QuizExamTheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        // Save Draft
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _handleSaveDraft(context),
            icon: const Icon(Icons.save_outlined, size: 20),
            label: const Text('Lưu bài làm'),
            style: OutlinedButton.styleFrom(
              foregroundColor: QuizExamTheme.onSurface,
              side: const BorderSide(color: QuizExamTheme.outlineVariant),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              backgroundColor: QuizExamTheme.surfaceContainerLowest,
            ),
          ),
        ),
        const SizedBox(height: 10),
        // Submit
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _showSubmitDialog(context),
            icon: Icon(
              Icons.task_alt_rounded,
              size: 20,
              color: Colors.white.withValues(alpha: 0.9),
            ),
            label: const Text(
              'Nộp bài',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: QuizExamTheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLegendCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: QuizExamTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Chú thích',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: QuizExamTheme.onSurface,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 12),
          _legendItem(QuizExamTheme.primary, Colors.transparent, 'Câu đang xem', isBorder: true),
          const SizedBox(height: 8),
          _legendItem(QuizExamTheme.answeredGreen, Colors.transparent, 'Câu đã trả lời'),
          const SizedBox(height: 8),
          _legendItem(QuizExamTheme.surfaceContainerHighest, Colors.transparent, 'Câu chưa trả lời'),
          const SizedBox(height: 8),
          _legendItem(QuizExamTheme.tertiary, Colors.transparent, 'Câu đánh dấu', hasStar: true),
        ],
      ),
    );
  }

  Widget _legendItem(Color bg, Color border, String label, {bool isBorder = false, bool hasStar = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: hasStar ? Colors.transparent : bg,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isBorder ? QuizExamTheme.primary : border,
              width: isBorder ? 2 : 0,
            ),
          ),
          child: hasStar
              ? const Icon(Icons.star, size: 14, color: QuizExamTheme.tertiary)
              : isBorder
                  ? Center(
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: bg,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1),
                        ),
                      ),
                    )
                  : null,
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: QuizExamTheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  void _showSubmitDialog(BuildContext context) {
    final unanswered = (controller.quiz?.questions.length ?? 0) - controller.answeredCount;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: QuizExamTheme.surfaceContainerLowest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.task_alt_rounded, color: QuizExamTheme.primary),
            const SizedBox(width: 10),
            const Text('Nộp bài?'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bạn đã trả lời ${controller.answeredCount}/${controller.quiz?.questions.length ?? 0} câu.'),
            if (unanswered > 0) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: QuizExamTheme.errorContainer.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: QuizExamTheme.error.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        size: 18, color: QuizExamTheme.error),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Còn $unanswered câu chưa trả lời!',
                        style: const TextStyle(
                          color: QuizExamTheme.error,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              controller.submitQuizWithConfirm(context);
            },
            icon: const Icon(Icons.send, size: 18),
            label: const Text('Nộp bài'),
            style: ElevatedButton.styleFrom(
              backgroundColor: QuizExamTheme.answeredGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleSaveDraft(BuildContext context) {
    context.showAppToast('Đã lưu bài làm');
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// NAV BUTTON (Web)
// ──────────────────────────────────────────────────────────────────────────────

class _QuizNavButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool outlined;
  final bool enabled;
  final VoidCallback onPressed;
  final Color? color;

  const _QuizNavButton({
    required this.label,
    required this.icon,
    required this.outlined,
    this.enabled = true,
    required this.onPressed,
    this.color,
  });

  @override
  State<_QuizNavButton> createState() => _QuizNavButtonState();
}

class _QuizNavButtonState extends State<_QuizNavButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = widget.color ?? (widget.outlined ? QuizExamTheme.primary : Colors.white);

    if (widget.outlined) {
      return GestureDetector(
        onTapDown: widget.enabled ? (_) => setState(() => _isPressed = true) : null,
        onTapUp: widget.enabled ? (_) => setState(() => _isPressed = false) : null,
        onTapCancel: widget.enabled ? () => setState(() => _isPressed = false) : null,
        onTap: widget.enabled ? widget.onPressed : null,
        child: AnimatedScale(
          scale: _isPressed ? 0.95 : 1.0,
          duration: const Duration(milliseconds: 100),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: _isPressed
                  ? QuizExamTheme.primaryFixed
                  : QuizExamTheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: widget.enabled
                    ? effectiveColor.withValues(alpha: 0.6)
                    : QuizExamTheme.outlineVariant,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.icon,
                  size: 18,
                  color: widget.enabled
                      ? effectiveColor
                      : QuizExamTheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: widget.enabled
                        ? effectiveColor
                        : QuizExamTheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return GestureDetector(
      onTapDown: widget.enabled ? (_) => setState(() => _isPressed = true) : null,
      onTapUp: widget.enabled ? (_) => setState(() => _isPressed = false) : null,
      onTapCancel: widget.enabled ? () => setState(() => _isPressed = false) : null,
      onTap: widget.enabled ? widget.onPressed : null,
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            gradient: widget.enabled
                ? const LinearGradient(
                    colors: [QuizExamTheme.primary, QuizExamTheme.primaryContainer],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: widget.enabled ? null : QuizExamTheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(24),
            boxShadow: widget.enabled && !_isPressed
                ? [
                    BoxShadow(
                      color: QuizExamTheme.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: widget.enabled
                      ? Colors.white
                      : QuizExamTheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                widget.icon,
                size: 18,
                color: widget.enabled
                    ? Colors.white.withValues(alpha: 0.9)
                    : QuizExamTheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// MOBILE LAYOUT
// ──────────────────────────────────────────────────────────────────────────────

class _QuizMobileView extends StatelessWidget {
  final QuizInternalController controller;

  const _QuizMobileView({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QuizExamTheme.background,
      appBar: AppBar(
        backgroundColor: QuizExamTheme.surfaceContainerLowest,
        elevation: 0,
        scrolledUnderElevation: 1,
        automaticallyImplyLeading: false,
        title: const SizedBox.shrink(),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.notifications_outlined,
              color: QuizExamTheme.onSurfaceVariant,
              size: 22,
            ),
            tooltip: 'Thông báo',
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: controller,
        builder: (context, child) {
          if (controller.isLoading && controller.quiz == null) {
            return const Center(
              child: CircularProgressIndicator(color: QuizExamTheme.primary),
            );
          }

          if (controller.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(controller.error!),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: controller.loadQuiz,
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }

          final question = controller.currentQuestion;
          if (question == null) return const SizedBox();

          final selectedIds = controller.getSelectedOptions(question.id);

          QuestionDisplayMode displayMode;
          switch (question.type) {
            case QuestionType.single:
              displayMode = QuestionDisplayMode.single;
              break;
            case QuestionType.multiple:
              displayMode = QuestionDisplayMode.multiple;
              break;
            case QuestionType.trueFalse:
              displayMode = QuestionDisplayMode.trueFalse;
              break;
          }

          return Column(
            children: [
              // Progress
              Container(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: QuizProgressBar(
                  currentIndex: controller.currentIndex,
                  totalQuestions: controller.quiz!.questions.length,
                  answeredQuestions: controller.answeredQuestions,
                  flaggedQuestions: controller.flaggedQuestions,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: QuizTimer(
                    totalSeconds: controller.quiz!.timeLimitMinutes * 60,
                    onTimeUp: () => controller.handleAutoSubmit(context),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Question Card
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: QuizQuestionCard(
                    question: question,
                    questionIndex: controller.currentIndex,
                    totalQuestions: controller.quiz!.questions.length,
                    selectedOptionIds: selectedIds,
                    mode: displayMode,
                    showResult: false,
                    onOptionSelected: controller.selectOption,
                    isFlagged: controller.isCurrentFlagged,
                    onToggleFlag: controller.toggleFlag,
                  ),
                ),
              ),
              // Bottom Nav
              _MobileNavBar(controller: controller),
            ],
          );
        },
      ),
    );
  }
}

class _MobileNavBar extends StatelessWidget {
  final QuizInternalController controller;

  const _MobileNavBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    final isFirst = controller.currentIndex == 0;
    final isLast = controller.isLastQuestion;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: QuizExamTheme.surfaceContainerLowest,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (!isFirst)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: controller.previousQuestion,
                  icon: const Icon(Icons.arrow_back_rounded, size: 18),
                  label: const Text('Trước'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: QuizExamTheme.primary,
                    side: const BorderSide(color: QuizExamTheme.primary, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              )
            else
              const Spacer(),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: isLast
                    ? () => controller.submitQuizWithConfirm(context)
                    : controller.nextQuestion,
                icon: Icon(
                  isLast ? Icons.task_alt_rounded : Icons.arrow_forward_rounded,
                  size: 18,
                ),
                label: Text(
                  isLast ? 'Nộp bài' : 'Tiếp theo',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isLast ? QuizExamTheme.answeredGreen : QuizExamTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// CONTROLLER (unchanged logic)
// ──────────────────────────────────────────────────────────────────────────────

class QuizInternalController extends ChangeNotifier {
  final String quizId;
  final String? courseId;
  final String? resumeAttemptId;
  String? _attemptId;
  Quiz? _quiz;
  bool _isLoading = true;
  String? _error;
  int _currentIndex = 0;
  Map<String, List<String>> _answers = {};
  Set<int> _flaggedQuestions = {};
  Set<int> _answeredQuestions = {};
  DateTime? _startTime;
  bool _showResult = false;
  QuizResult? _quizResult;

  QuizInternalController({
    required this.quizId,
    this.courseId,
    this.resumeAttemptId,
  }) {
    loadQuiz();
  }

  Quiz? get quiz => _quiz;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get currentIndex => _currentIndex;
  Set<int> get flaggedQuestions => _flaggedQuestions;
  Set<int> get answeredQuestions => _answeredQuestions;
  int get answeredCount => _answeredQuestions.length;
  bool get isCurrentFlagged => _flaggedQuestions.contains(_currentIndex);
  String? get attemptId => _attemptId;

  QuizQuestion? get currentQuestion =>
      _quiz != null && _currentIndex < _quiz!.questions.length
          ? _quiz!.questions[_currentIndex]
          : null;

  bool get isLastQuestion =>
      _quiz != null && _currentIndex == _quiz!.questions.length - 1;

  List<String> getSelectedOptions(String questionId) => _answers[questionId] ?? [];

  Future<void> loadQuiz() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      String? activeAttemptId = resumeAttemptId;

      // Nếu không có attemptId được truyền vào → kiểm tra attempt đang làm
      if (activeAttemptId == null) {
        final activeAttempt = await QuizService.getActiveAttempt(quizId);
        activeAttemptId = activeAttempt?.attemptId;
      }

      // Bước 1: Start attempt (hoặc lấy attempt đang làm)
      final startResult = await QuizService.startAttempt(quizId);
      _attemptId = startResult.attemptId;

      // Bước 2: Lấy câu hỏi của attempt
      _quiz = await QuizService.getAttemptQuestions(_attemptId!, startResult.quizId);

      // Bước 3: Tính thời gian bắt đầu
      _startTime = DateTime.now();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      // Xử lý lỗi cụ thể
      final errorMsg = e.toString().toLowerCase();
      
      if (errorMsg.contains('required lessons') || 
          errorMsg.contains('must complete')) {
        // User bị reset progress → cần học lại bài
        _error = 'RESET_PROGRESS';
      } else {
        _error = 'Không thể tải bài quiz: $e';
      }
      notifyListeners();
    }
  }

  void selectOption(String optionId) {
    if (_quiz == null || _showResult) return;

    final question = currentQuestion;
    if (question == null) return;

    final currentAnswers = _answers[question.id] ?? [];

    if (question.type == QuestionType.single ||
        question.type == QuestionType.trueFalse) {
      _answers[question.id] = [optionId];
    } else {
      if (currentAnswers.contains(optionId)) {
        _answers[question.id] = currentAnswers.where((id) => id != optionId).toList();
      } else {
        _answers[question.id] = [...currentAnswers, optionId];
      }
    }

    if (_answers[question.id]?.isNotEmpty == true) {
      _answeredQuestions.add(_currentIndex);
    } else {
      _answeredQuestions.remove(_currentIndex);
    }

    if (_attemptId != null) {
      final selected = _answers[question.id] ?? [];
      QuizService.saveAnswer(_attemptId!, question.id, selected);
    }

    notifyListeners();
  }

  void toggleFlag() {
    if (_flaggedQuestions.contains(_currentIndex)) {
      _flaggedQuestions.remove(_currentIndex);
    } else {
      _flaggedQuestions.add(_currentIndex);
    }
    notifyListeners();
  }

  void goToQuestion(int index) {
    if (_quiz == null) return;
    if (index >= 0 && index < _quiz!.questions.length) {
      _currentIndex = index;
      notifyListeners();
    }
  }

  void previousQuestion() {
    if (_currentIndex > 0) {
      goToQuestion(_currentIndex - 1);
    }
  }

  void nextQuestion() {
    if (_quiz != null && _currentIndex < _quiz!.questions.length - 1) {
      goToQuestion(_currentIndex + 1);
    }
  }

  Future<void> submitQuizWithConfirm(BuildContext context) async {
    if (_quiz == null || _startTime == null) return;

    final timeSpent = DateTime.now().difference(_startTime!);

    _isLoading = true;
    notifyListeners();

    try {
      _quizResult = await QuizService.submitAttempt(
        _attemptId ?? 'mock_attempt_${_quiz!.id}',
        _quiz!.id,
        _answers,
        timeSpent,
        questionCountFallback: _quiz!.questions.length,
      );
      _showResult = true;

      _isLoading = false;
      notifyListeners();

      if (context.mounted) {
        _showResultDialog(context);
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      if (context.mounted) {
        context.showAppToast('Nộp bài thất bại: $e', variant: AppToastVariant.error);
      }
    }
  }

  /// Xử lý auto-submit khi hết giờ (không cần confirm dialog)
  Future<void> handleAutoSubmit(BuildContext context) async {
    if (_quiz == null || _startTime == null) return;

    final timeSpent = DateTime.now().difference(_startTime!);

    _isLoading = true;
    notifyListeners();

    try {
      _quizResult = await QuizService.autoSubmit(
        _attemptId ?? 'mock_attempt_${_quiz!.id}',
        _quiz!.id,
        _answers,
        timeSpent,
        questionCountFallback: _quiz!.questions.length,
      );
      _showResult = true;

      _isLoading = false;
      notifyListeners();

      if (context.mounted) {
        _showResultDialog(context, isAutoSubmit: true);
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      if (context.mounted) {
        context.showAppToast('Auto submit thất bại: $e', variant: AppToastVariant.error);
      }
    }
  }

  void _showResultDialog(BuildContext context, {bool isAutoSubmit = false}) {
    if (_quizResult == null || !context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => QuizResultDialog(
        result: _quizResult!,
        courseId: courseId,
        isAutoSubmit: isAutoSubmit,
        onRetry: () {
          Navigator.pop(ctx);
          _handleRetry(context);
        },
        onClose: () {
          Navigator.pop(ctx);
          _navigateBackToWorkspace(context);
        },
        onViewCertificate: courseId != null
            ? () {
                Navigator.pop(ctx);
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!context.mounted) return;
                  GoRouter.of(context).go('/employee/certificates?courseId=$courseId');
                });
              }
            : null,
      ),
    );
  }

  void _handleRetry(BuildContext context) async {
    final eligibility = await QuizService.checkQuizEligibility(quizId);
    if (!eligibility.canStart) {
      if (context.mounted) {
        context.showAppToast(
          'Bạn đã hết lượt thi!',
          variant: AppToastVariant.error,
        );
        _navigateBackToWorkspace(context);
      }
      return;
    }
    reset();
    loadQuiz();
  }

  void _navigateBackToWorkspace(BuildContext context) {
    if (!context.mounted) return;
    if (courseId != null) {
      GoRouter.of(context).go('/employee/learn/$courseId');
    } else {
      GoRouter.of(context).pop();
    }
  }

  void reset() {
    _currentIndex = 0;
    _answers = {};
    _flaggedQuestions = {};
    _answeredQuestions = {};
    _startTime = DateTime.now();
    _showResult = false;
    _quizResult = null;
    notifyListeners();
  }
}
