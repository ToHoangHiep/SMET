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

class _QuizLessonViewState extends State<QuizLessonView>
    with SingleTickerProviderStateMixin {
  QuizInfo? _quizInfo;
  QuizEligibility? _eligibility;
  bool _isLoading = true;
  String? _error;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  bool get _isFinalQuiz {
    if (widget.isFinalQuiz != null) return widget.isFinalQuiz!;
    return _quizInfo?.isFinalQuiz ?? false;
  }

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _loadQuizData();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
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
        _fadeController.forward();
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
      return const _QuizLoadingSkeleton();
    }

    if (_error != null) {
      return _QuizErrorState(
        error: _error!,
        onRetry: _loadQuizData,
      );
    }

    final hasDescription =
        _quizInfo != null && _quizInfo!.description.isNotEmpty;

    return FadeTransition(
      opacity: _fadeAnimation,
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
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFF8FAFC),
            const Color(0xFFF1F5F9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF137FEC).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF137FEC).withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF137FEC).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.quiz_outlined,
                        size: 14,
                        color: Color(0xFF137FEC),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isFinalQuiz ? 'Bài kiểm tra cuối khóa' : 'Kiểm tra Module',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF137FEC),
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
              if (_isFinalQuiz) ...[
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star_rounded, size: 13, color: Colors.white),
                      SizedBox(width: 5),
                      Text(
                        'CUỐI KHÓA',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 20),
          Text(
            _quizInfo?.title ?? 'Bài kiểm tra',
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
              height: 1.2,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: const Color(0xFF137FEC),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Kiểm tra kiến thức của bạn về chủ đề này',
                  style: TextStyle(
                    fontSize: 14,
                    color: const Color(0xFF64748B),
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCards() {
    return Row(
      children: [
        Expanded(
          child: _InfoCard(
            icon: Icons.schedule_rounded,
            label: 'Thời gian',
            value: '${_quizInfo?.timeLimitMinutes ?? 10} phút',
            color: const Color(0xFF137FEC),
            gradientColors: [const Color(0xFF137FEC).withValues(alpha: 0.08), Colors.transparent],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _InfoCard(
            icon: Icons.quiz_rounded,
            label: 'Số câu hỏi',
            value: '${_quizInfo?.questionCount ?? 0} câu',
            color: const Color(0xFF8B5CF6),
            gradientColors: [const Color(0xFF8B5CF6).withValues(alpha: 0.08), Colors.transparent],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _InfoCard(
            icon: Icons.grade_rounded,
            label: 'Điểm đạt',
            value: '${_quizInfo?.passingScore ?? 70}%',
            color: const Color(0xFF22C55E),
            gradientColors: [const Color(0xFF22C55E).withValues(alpha: 0.08), Colors.transparent],
          ),
        ),
      ],
    );
  }

  Widget _buildDescription() {
    final desc = _quizInfo?.description ?? '';
    if (desc.isEmpty) return const SizedBox();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF137FEC).withValues(alpha: 0.1),
                      const Color(0xFF137FEC).withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.info_outline,
                  size: 20,
                  color: Color(0xFF137FEC),
                ),
              ),
              const SizedBox(width: 14),
              const Text(
                'Về bài kiểm tra này',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Text(
              desc,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF475569),
                height: 1.7,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    if (_eligibility?.hasActiveAttempt == true) {
      return Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFFEF3C7),
                  const Color(0xFFFDE68A).withValues(alpha: 0.5),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFFDE68A)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD97706).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.pending_actions_rounded,
                    color: Color(0xFFD97706),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Bài thi chưa hoàn thành',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFD97706),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Bạn có một bài thi đang dở. Tiếp tục làm bài?',
                        style: TextStyle(
                          fontSize: 13,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _ActionButton(
            onPressed: _onResumeQuiz,
            icon: Icons.play_arrow_rounded,
            label: 'Tiếp tục làm bài',
            gradient: const [Color(0xFFD97706), Color(0xFFB45309)],
          ),
        ],
      );
    }

    if (_eligibility?.canStart == false) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFFFEE2E2),
              const Color(0xFFFECACA).withValues(alpha: 0.5),
            ],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFFECACA)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFEF4444).withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.block_rounded,
                color: Color(0xFFEF4444),
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Không thể làm bài',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFEF4444),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _eligibility?.maxAttempts != null
                        ? 'Bạn đã sử dụng hết ${_eligibility!.submittedAttempts ?? 0}/${_eligibility!.maxAttempts} lượt thi'
                        : 'Đã xảy ra lỗi. Vui lòng thử lại sau.',
                    style: TextStyle(
                      fontSize: 13,
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

    return _ActionButton(
      onPressed: _onStartQuiz,
      icon: Icons.play_arrow_rounded,
      label: _eligibility?.remainingAttempts != null
          ? 'Bắt đầu làm bài (${_eligibility!.remainingAttempts} lượt còn lại)'
          : 'Bắt đầu làm bài',
      gradient: const [Color(0xFF137FEC), Color(0xFF0B5FC5)],
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

class _InfoCard extends StatefulWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final List<Color> gradientColors;

  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.gradientColors,
  });

  @override
  State<_InfoCard> createState() => _InfoCardState();
}

class _InfoCardState extends State<_InfoCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _isHovered
                ? [
                    widget.gradientColors[0],
                    widget.gradientColors[1],
                  ]
                : [Colors.white, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _isHovered
                ? widget.color.withValues(alpha: 0.3)
                : const Color(0xFFE2E8F0),
          ),
          boxShadow: [
            BoxShadow(
              color: _isHovered
                  ? widget.color.withValues(alpha: 0.15)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: _isHovered ? 16 : 10,
              offset: Offset(0, _isHovered ? 6 : 3),
            ),
          ],
        ),
        transform:
            _isHovered ? (Matrix4.identity()..translate(0.0, -2.0)) : Matrix4.identity(),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    widget.color.withValues(alpha: _isHovered ? 0.2 : 0.12),
                    widget.color.withValues(alpha: _isHovered ? 0.08 : 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withValues(alpha: 0.15),
                    blurRadius: _isHovered ? 8 : 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(widget.icon, size: 22, color: widget.color),
            ),
            const SizedBox(height: 14),
            Text(
              widget.value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: widget.color,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatefulWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String label;
  final List<Color> gradient;

  const _ActionButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.gradient,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: widget.gradient,
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: widget.gradient[0].withValues(alpha: _isHovered ? 0.5 : 0.35),
                blurRadius: _isHovered ? 20 : 12,
                offset: Offset(0, _isHovered ? 8 : 4),
              ),
            ],
          ),
          transform:
              _isHovered ? (Matrix4.identity()..translate(0.0, -2.0)) : Matrix4.identity(),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.icon,
                color: Colors.white.withValues(alpha: 0.9),
                size: 24,
              ),
              const SizedBox(width: 10),
              Text(
                widget.label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuizLoadingSkeleton extends StatelessWidget {
  const _QuizLoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SkeletonBox(
          height: 180,
          borderRadius: 16,
        ),
        const SizedBox(height: 24),
        Row(
          children: List.generate(
            3,
            (index) => Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: index < 2 ? 12 : 0),
                child: _SkeletonBox(
                  height: 120,
                  borderRadius: 14,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        _SkeletonBox(
          height: 100,
          borderRadius: 14,
        ),
        const SizedBox(height: 24),
        _SkeletonBox(
          height: 56,
          borderRadius: 14,
        ),
      ],
    );
  }
}

class _SkeletonBox extends StatefulWidget {
  final double height;
  final double borderRadius;

  const _SkeletonBox({
    required this.height,
    this.borderRadius = 8,
  });

  @override
  State<_SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<_SkeletonBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    _animation = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              colors: [
                Color.lerp(
                  const Color(0xFFE2E8F0),
                  const Color(0xFFF1F5F9),
                  _animation.value,
                )!,
                Color.lerp(
                  const Color(0xFFF1F5F9),
                  const Color(0xFFE2E8F0),
                  _animation.value,
                )!,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        );
      },
    );
  }
}

class _QuizErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _QuizErrorState({
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(48),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.2),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: Color(0xFFEF4444),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              error,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF64748B),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            _ActionButton(
              onPressed: onRetry,
              icon: Icons.refresh_rounded,
              label: 'Thử lại',
              gradient: const [Color(0xFF137FEC), Color(0xFF0B5FC5)],
            ),
          ],
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
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF137FEC).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF137FEC).withValues(alpha: 0.2),
                ),
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
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF137FEC),
                    ),
                  ),
                ],
              ),
            ),
            if (isFinalQuiz) ...[
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star_rounded, size: 13, color: Colors.white),
                    SizedBox(width: 5),
                    Text(
                      'CUỐI KHÓA',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.8,
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
