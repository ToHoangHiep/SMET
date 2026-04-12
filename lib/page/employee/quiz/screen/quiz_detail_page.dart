import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:smet/page/employee/quiz/widgets/quiz_exam_theme.dart';
import 'package:smet/service/employee/quiz_service.dart';

// ============================================================
// QUIZ DETAIL PAGE
// Hiển thị thông tin quiz: tên, thời gian, số câu, mô tả
// Có nút "Bắt đầu làm bài" để vào QuizPage thực sự
// ============================================================

class QuizDetailPage extends StatefulWidget {
  final String quizId;
  final String? courseId;

  const QuizDetailPage({
    super.key,
    required this.quizId,
    this.courseId,
  });

  @override
  State<QuizDetailPage> createState() => _QuizDetailPageState();
}

class _QuizDetailPageState extends State<QuizDetailPage> {
  QuizInfo? _quizInfo;
  QuizEligibility? _eligibility;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadQuizData();
  }

  Future<void> _loadQuizData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Load quiz info và eligibility song song
      final results = await Future.wait([
        QuizService.getQuizInfo(widget.quizId),
        QuizService.checkQuizEligibility(widget.quizId),
      ]);

      setState(() {
        _quizInfo = results[0] as QuizInfo;
        _eligibility = results[1] as QuizEligibility;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Không thể tải thông tin bài quiz';
        _isLoading = false;
      });
    }
  }

  void _onStartQuiz() {
    context.go(
      '/employee/quiz/${widget.quizId}?courseId=${widget.courseId ?? ''}',
    );
  }

  void _onResumeQuiz() {
    if (_eligibility?.activeAttemptId != null) {
      context.go(
        '/employee/quiz/${widget.quizId}?courseId=${widget.courseId ?? ''}&attemptId=${_eligibility!.activeAttemptId}',
      );
    } else {
      _onStartQuiz();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWebOrDesktop = kIsWeb ||
        MediaQuery.of(context).size.width >= 768 ||
        !Platform.isAndroid && !Platform.isIOS;

    if (isWebOrDesktop) {
      return _QuizDetailWebView(
        quizInfo: _quizInfo,
        eligibility: _eligibility,
        isLoading: _isLoading,
        error: _error,
        quizId: widget.quizId,
        onRetry: _loadQuizData,
        onStartQuiz: _onStartQuiz,
        onResumeQuiz: _onResumeQuiz,
      );
    }

    return _QuizDetailMobileView(
      quizInfo: _quizInfo,
      eligibility: _eligibility,
      isLoading: _isLoading,
      error: _error,
      quizId: widget.quizId,
      onRetry: _loadQuizData,
      onStartQuiz: _onStartQuiz,
      onResumeQuiz: _onResumeQuiz,
    );
  }
}

// ============================================================
// WEB LAYOUT
// ============================================================

class _QuizDetailWebView extends StatelessWidget {
  final QuizInfo? quizInfo;
  final QuizEligibility? eligibility;
  final bool isLoading;
  final String? error;
  final String quizId;
  final VoidCallback onRetry;
  final VoidCallback onStartQuiz;
  final VoidCallback onResumeQuiz;

  const _QuizDetailWebView({
    required this.quizInfo,
    required this.eligibility,
    required this.isLoading,
    required this.error,
    required this.quizId,
    required this.onRetry,
    required this.onStartQuiz,
    required this.onResumeQuiz,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QuizExamTheme.background,
      body: Column(
        children: [
          _QuizDetailTopNavBar(
            quizTitle: quizInfo?.title ?? 'Bài kiểm tra',
            onBack: () => context.pop(),
          ),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(32),
                  child: _buildContent(context),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: QuizExamTheme.primary),
      );
    }

    if (error != null) {
      return _buildErrorState(context);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context),
        const SizedBox(height: 24),
        _buildInfoCards(context),
        const SizedBox(height: 24),
        _buildDescription(context),
        const SizedBox(height: 32),
        _buildStartButton(context),
        const SizedBox(height: 16),
        _buildHistoryButton(context),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (quizInfo?.isFinalQuiz == true)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: QuizExamTheme.tertiaryFixed,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.star_rounded,
                  size: 14,
                  color: QuizExamTheme.tertiary,
                ),
                const SizedBox(width: 6),
                Text(
                  'BÀI KIỂM TRA CUỐI KHÓA',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: QuizExamTheme.tertiary,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        if (quizInfo?.isFinalQuiz == true) const SizedBox(height: 12),
        Text(
          quizInfo?.title ?? 'Bài kiểm tra',
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: QuizExamTheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Kiểm tra kiến thức của bạn về chủ đề này',
          style: TextStyle(
            fontSize: 15,
            color: QuizExamTheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCards(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _InfoCard(
            icon: Icons.schedule_rounded,
            label: 'Thời gian',
            value: '${quizInfo?.timeLimitMinutes ?? 10} phút',
            color: QuizExamTheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _InfoCard(
            icon: Icons.quiz_rounded,
            label: 'Số câu hỏi',
            value: '${quizInfo?.questionCount ?? 0} câu',
            color: QuizExamTheme.secondary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _InfoCard(
            icon: Icons.grade_rounded,
            label: 'Điểm đạt',
            value: '${quizInfo?.passingScore ?? 70}%',
            color: QuizExamTheme.answeredGreen,
          ),
        ),
      ],
    );
  }

  Widget _buildDescription(BuildContext context) {
    final desc = quizInfo?.description ?? '';
    if (desc.isEmpty) return const SizedBox();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: QuizExamTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [QuizExamTheme.cardShadowLight],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.description_rounded,
                size: 18,
                color: QuizExamTheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              const Text(
                'Mô tả',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: QuizExamTheme.onSurface,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            desc,
            style: TextStyle(
              fontSize: 14,
              height: 1.6,
              color: QuizExamTheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStartButton(BuildContext context) {
    // Nếu có active attempt → hiển thị nút Resume
    if (eligibility?.hasActiveAttempt == true) {
      return Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: QuizExamTheme.tertiaryFixed,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: QuizExamTheme.tertiary.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.pending_actions_rounded, color: QuizExamTheme.tertiary, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bài thi chưa hoàn thành',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: QuizExamTheme.tertiary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Bạn có một bài thi đang dở. Tiếp tục làm bài?',
                        style: TextStyle(
                          fontSize: 12,
                          color: QuizExamTheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: onResumeQuiz,
              icon: Icon(
                Icons.play_arrow_rounded,
                size: 22,
                color: Colors.white.withValues(alpha: 0.9),
              ),
              label: const Text(
                'Tiếp tục làm bài',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: QuizExamTheme.tertiary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      );
    }

    // Nếu không thể start (hết lượt hoặc lỗi)
    if (eligibility?.canStart == false) {
      return Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: QuizExamTheme.errorContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: QuizExamTheme.error.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.block_rounded, color: QuizExamTheme.error, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Không thể làm bài',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: QuizExamTheme.error,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        eligibility?.maxAttempts != null
                            ? 'Bạn đã sử dụng hết ${eligibility!.submittedAttempts ?? 0}/${eligibility!.maxAttempts} lượt thi'
                            : 'Đã xảy ra lỗi. Vui lòng thử lại sau.',
                        style: TextStyle(
                          fontSize: 12,
                          color: QuizExamTheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    // Bình thường → hiển thị nút Start
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: onStartQuiz,
        icon: Icon(
          Icons.play_arrow_rounded,
          size: 22,
          color: Colors.white.withValues(alpha: 0.9),
        ),
        label: Text(
          eligibility?.remainingAttempts != null
              ? 'Bắt đầu làm bài (${eligibility!.remainingAttempts} lượt còn lại)'
              : 'Bắt đầu làm bài',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: QuizExamTheme.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryButton(BuildContext context) {
    return Center(
      child: TextButton.icon(
        onPressed: () {
          context.go(
            '/employee/quiz-history/$quizId?title=${Uri.encodeComponent(quizInfo?.title ?? 'Bài kiểm tra')}',
          );
        },
        icon: Icon(
          Icons.history_rounded,
          size: 18,
          color: QuizExamTheme.onSurfaceVariant,
        ),
        label: Text(
          'Xem lịch sử làm bài',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: QuizExamTheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: QuizExamTheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: QuizExamTheme.error.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: QuizExamTheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              error ?? 'Đã xảy ra lỗi',
              style: const TextStyle(
                fontSize: 15,
                color: QuizExamTheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
              style: ElevatedButton.styleFrom(
                backgroundColor: QuizExamTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// MOBILE LAYOUT
// ============================================================

class _QuizDetailMobileView extends StatelessWidget {
  final QuizInfo? quizInfo;
  final QuizEligibility? eligibility;
  final bool isLoading;
  final String? error;
  final String quizId;
  final VoidCallback onRetry;
  final VoidCallback onStartQuiz;
  final VoidCallback onResumeQuiz;

  const _QuizDetailMobileView({
    required this.quizInfo,
    required this.eligibility,
    required this.isLoading,
    required this.error,
    required this.quizId,
    required this.onRetry,
    required this.onStartQuiz,
    required this.onResumeQuiz,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QuizExamTheme.background,
      appBar: AppBar(
        backgroundColor: QuizExamTheme.surfaceContainerLowest,
        elevation: 0,
        scrolledUnderElevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(
          quizInfo?.title ?? 'Bài kiểm tra',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _buildBody(context),
      bottomNavigationBar: _buildBottomBar(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: QuizExamTheme.primary),
      );
    }

    if (error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(error!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 20),
          _buildInfoCards(context),
          const SizedBox(height: 20),
          _buildDescription(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (quizInfo?.isFinalQuiz == true)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: QuizExamTheme.tertiaryFixed,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.star_rounded,
                  size: 12,
                  color: QuizExamTheme.tertiary,
                ),
                const SizedBox(width: 5),
                Text(
                  'BÀI KIỂM TRA CUỐI KHÓA',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: QuizExamTheme.tertiary,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        if (quizInfo?.isFinalQuiz == true) const SizedBox(height: 10),
        Text(
          quizInfo?.title ?? 'Bài kiểm tra',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: QuizExamTheme.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Kiểm tra kiến thức của bạn về chủ đề này',
          style: TextStyle(
            fontSize: 14,
            color: QuizExamTheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCards(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _InfoCard(
            icon: Icons.schedule_rounded,
            label: 'Thời gian',
            value: '${quizInfo?.timeLimitMinutes ?? 10} phút',
            color: QuizExamTheme.primary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _InfoCard(
            icon: Icons.quiz_rounded,
            label: 'Số câu',
            value: '${quizInfo?.questionCount ?? 0}',
            color: QuizExamTheme.secondary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _InfoCard(
            icon: Icons.grade_rounded,
            label: 'Điểm đạt',
            value: '${quizInfo?.passingScore ?? 70}%',
            color: QuizExamTheme.answeredGreen,
          ),
        ),
      ],
    );
  }

  Widget _buildDescription(BuildContext context) {
    final desc = quizInfo?.description ?? '';
    if (desc.isEmpty) return const SizedBox();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: QuizExamTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [QuizExamTheme.cardShadowLight],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.description_rounded,
                size: 16,
                color: QuizExamTheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              const Text(
                'Mô tả',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: QuizExamTheme.onSurface,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            desc,
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: QuizExamTheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    // Nếu có active attempt → hiển thị nút Resume
    if (eligibility?.hasActiveAttempt == true) {
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
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: onResumeQuiz,
              icon: Icon(
                Icons.play_arrow_rounded,
                size: 20,
                color: Colors.white.withValues(alpha: 0.9),
              ),
              label: const Text(
                'Tiếp tục làm bài',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: QuizExamTheme.tertiary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Nếu không thể start → hiển thị thông báo
    if (eligibility?.canStart == false) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: QuizExamTheme.errorContainer.withValues(alpha: 0.3),
          border: Border(
            top: BorderSide(color: QuizExamTheme.error.withValues(alpha: 0.2)),
          ),
        ),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.block_rounded, color: QuizExamTheme.error, size: 18),
              const SizedBox(width: 8),
              Text(
                eligibility?.maxAttempts != null
                    ? 'Đã hết lượt thi (${eligibility!.submittedAttempts ?? 0}/${eligibility!.maxAttempts})'
                    : 'Không thể làm bài',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: QuizExamTheme.error,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Bình thường → hiển thị nút Start
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
        child: SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: onStartQuiz,
            icon: Icon(
              Icons.play_arrow_rounded,
              size: 20,
              color: Colors.white.withValues(alpha: 0.9),
            ),
            label: Text(
              eligibility?.remainingAttempts != null
                  ? 'Bắt đầu (${eligibility!.remainingAttempts} lượt)'
                  : 'Bắt đầu làm bài',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: QuizExamTheme.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// SHARED WIDGETS
// ============================================================

class _QuizDetailTopNavBar extends StatelessWidget {
  final String quizTitle;
  final VoidCallback onBack;

  const _QuizDetailTopNavBar({
    required this.quizTitle,
    required this.onBack,
  });

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
            onPressed: onBack,
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: QuizExamTheme.onSurfaceVariant,
            ),
            tooltip: 'Quay lại',
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              quizTitle,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: QuizExamTheme.onSurface,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
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

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: QuizExamTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [QuizExamTheme.cardShadowLight],
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 20,
              color: color,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: QuizExamTheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
