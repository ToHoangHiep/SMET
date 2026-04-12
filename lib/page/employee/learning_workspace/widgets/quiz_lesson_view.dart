import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smet/service/employee/quiz_service.dart';

/// QuizLessonView — hiển thị quiz giống như lesson trong Learning Workspace.
/// Thay vì chuyển sang trang riêng, quiz sẽ hiển thị ngay tại content area
/// với: title, mô tả, thời gian, số câu, điểm đạt, nút bắt đầu làm bài.
class QuizLessonView extends StatefulWidget {
  final String quizId;
  final String? courseId;
  final String? moduleTitle;
  /// Xác định đây có phải là final quiz (cuối khóa) hay không
  /// Nếu null, sẽ dùng thông tin từ API
  final bool? isFinalQuiz;

  const QuizLessonView({
    super.key,
    required this.quizId,
    this.courseId,
    this.moduleTitle,
    this.isFinalQuiz,
  });

  @override
  State<QuizLessonView> createState() => _QuizLessonViewState();
}

class _QuizLessonViewState extends State<QuizLessonView> {
  QuizInfo? _quizInfo;
  QuizEligibility? _eligibility;
  bool _isLoading = true;
  String? _error;

  /// Xác định có phải final quiz hay không
  /// Ưu tiên prop `isFinalQuiz` từ page, nếu null thì dùng từ API
  bool get _isFinalQuiz {
    // Nếu page truyền giá trị rõ ràng → dùng giá trị đó
    // (Page xác định dựa trên finalQuizId trong course model)
    if (widget.isFinalQuiz != null) return widget.isFinalQuiz!;
    // Ngược lại dùng giá trị từ API (đáng tin cậy hơn)
    return _quizInfo?.isFinalQuiz ?? false;
  }

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

      final results = await Future.wait([
        QuizService.getQuizInfo(widget.quizId),
        QuizService.checkQuizEligibility(widget.quizId),
      ]);

      if (mounted) {
        setState(() {
          _quizInfo = results[0] as QuizInfo;
          _eligibility = results[1] as QuizEligibility;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Không thể tải thông tin bài quiz';
          _isLoading = false;
        });
      }
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

  void _onViewHistory() {
    context.go(
      '/employee/quiz-history/${widget.quizId}?title=${Uri.encodeComponent(_quizInfo?.title ?? 'Bài kiểm tra')}',
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.all(48),
        child: const Center(
          child: CircularProgressIndicator(color: Color(0xFF137FEC)),
        ),
      );
    }

    if (_error != null) {
      return Container(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Color(0xFFEF4444)),
              const SizedBox(height: 16),
              Text(
                _error!,
                style: const TextStyle(fontSize: 15, color: Color(0xFF64748B)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadQuizData,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Thử lại'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF137FEC),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final hasDescription = _quizInfo != null && _quizInfo!.description.isNotEmpty;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildContentArea(),
          const SizedBox(height: 24),
          _buildInfoCards(),
          const SizedBox(height: 24),
          if (hasDescription) ...[
            _buildDescription(),
            const SizedBox(height: 24),
          ],
          _buildActionButtons(),
          const SizedBox(height: 16),
          _buildHistoryLink(),
        ],
      ),
    );
  }

  Widget _buildContentArea() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF137FEC).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.quiz_outlined,
                      size: 14,
                      color: Color(0xFF137FEC),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _isFinalQuiz ? 'Bài kiểm tra cuối khóa' : 'Kiểm tra Module',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF137FEC),
                      ),
                    ),
                  ],
                ),
              ),
              if (_isFinalQuiz) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star_rounded, size: 12, color: Color(0xFFF59E0B)),
                      SizedBox(width: 4),
                      Text(
                        'CUỐI KHÓA',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFF59E0B),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _quizInfo?.title ?? 'Bài kiểm tra',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Kiểm tra kiến thức của bạn về chủ đề này',
            style: TextStyle(
              fontSize: 14,
              color: const Color(0xFF64748B),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCards() {
    return Row(
      children: [
        Expanded(
          child: _buildInfoCard(
            icon: Icons.schedule_rounded,
            label: 'Thời gian',
            value: '${_quizInfo?.timeLimitMinutes ?? 10} phút',
            color: const Color(0xFF137FEC),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildInfoCard(
            icon: Icons.quiz_rounded,
            label: 'Số câu hỏi',
            value: '${_quizInfo?.questionCount ?? 0} câu',
            color: const Color(0xFF8B5CF6),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildInfoCard(
            icon: Icons.grade_rounded,
            label: 'Điểm đạt',
            value: '${_quizInfo?.passingScore ?? 70}%',
            color: const Color(0xFF22C55E),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
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
            child: Icon(icon, size: 20, color: color),
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
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescription() {
    final desc = _quizInfo?.description ?? '';
    if (desc.isEmpty) return const SizedBox();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFF137FEC).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.info_outline,
                  size: 18,
                  color: Color(0xFF137FEC),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Về bài kiểm tra này',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            desc,
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF475569),
              height: 1.7,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    // Nếu có active attempt → hiển thị nút Resume
    if (_eligibility?.hasActiveAttempt == true) {
      return Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Row(
              children: [
                const Icon(Icons.pending_actions_rounded, color: Color(0xFFD97706), size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Bài thi chưa hoàn thành',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFD97706),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Bạn có một bài thi đang dở. Tiếp tục làm bài?',
                        style: TextStyle(
                          fontSize: 12,
                          color: const Color(0xFF64748B),
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
              onPressed: _onResumeQuiz,
              icon: const Icon(Icons.play_arrow_rounded, size: 22),
              label: const Text(
                'Tiếp tục làm bài',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD97706),
                foregroundColor: Colors.white,
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

    // Nếu không thể start (hết lượt hoặc lỗi)
    if (_eligibility?.canStart == false) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFEE2E2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFECACA)),
        ),
        child: Row(
          children: [
            const Icon(Icons.block_rounded, color: Color(0xFFEF4444), size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Không thể làm bài',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFEF4444),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _eligibility?.maxAttempts != null
                        ? 'Bạn đã sử dụng hết ${_eligibility!.submittedAttempts ?? 0}/${_eligibility!.maxAttempts} lượt thi'
                        : 'Đã xảy ra lỗi. Vui lòng thử lại sau.',
                    style: TextStyle(
                      fontSize: 12,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Bình thường → hiển thị nút Start
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: _onStartQuiz,
        icon: const Icon(Icons.play_arrow_rounded, size: 22),
        label: Text(
          _eligibility?.remainingAttempts != null
              ? 'Bắt đầu làm bài (${_eligibility!.remainingAttempts} lượt còn lại)'
              : 'Bắt đầu làm bài',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF137FEC),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryLink() {
    return Center(
      child: TextButton.icon(
        onPressed: _onViewHistory,
        icon: const Icon(
          Icons.history_rounded,
          size: 18,
          color: Color(0xFF64748B),
        ),
        label: const Text(
          'Xem lịch sử làm bài',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF64748B),
          ),
        ),
      ),
    );
  }
}

/// Quiz Lesson Header — hiển thị header của quiz trong learning workspace
class QuizLessonHeader extends StatelessWidget {
  final String title;
  final bool isFinalQuiz;
  final String? moduleTitle;

  const QuizLessonHeader({
    super.key,
    required this.title,
    this.isFinalQuiz = false,
    this.moduleTitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Module title if exists
        if (moduleTitle != null) ...[
          Text(
            moduleTitle!,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 4),
        ],
        // Title
        Text(
          title,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
            height: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        // Badge
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF137FEC).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.quiz_outlined, size: 14, color: Color(0xFF137FEC)),
                  const SizedBox(width: 6),
                  Text(
                    isFinalQuiz ? 'Bài kiểm tra cuối khóa' : 'Kiểm tra Module',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF137FEC),
                    ),
                  ),
                ],
              ),
            ),
            if (isFinalQuiz) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star_rounded, size: 12, color: Color(0xFFF59E0B)),
                    SizedBox(width: 4),
                    Text(
                      'CUỐI KHÓA',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFF59E0B),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
