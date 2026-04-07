import 'package:flutter/material.dart';
import 'package:smet/model/mentor_attempt_model.dart';
import 'package:smet/model/quiz_model.dart';
import 'package:smet/service/mentor/mentor_attempt_service.dart';
import 'package:smet/service/mentor/quiz_service.dart';

/// Mentor Review Assignment - Mobile Layout
class MentorReviewAssignmentMobile extends StatefulWidget {
  const MentorReviewAssignmentMobile({super.key});

  @override
  State<MentorReviewAssignmentMobile> createState() =>
      _MentorReviewAssignmentMobileState();
}

class _MentorReviewAssignmentMobileState
    extends State<MentorReviewAssignmentMobile> {
  // API state
  final MentorAttemptService _attemptService = MentorAttemptService();
  final MentorQuizService _quizService = MentorQuizService();

  bool _isLoadingQuizzes = true;
  bool _isLoadingSubmissions = false;

  List<QuizModel> _quizzes = [];
  QuizModel? _selectedQuiz;
  List<MentorAttemptInfo> _submissions = [];
  List<MentorAttemptInfo> _pendingSubmissions = [];
  List<MentorAttemptInfo> _reviewedSubmissions = [];

  int _selectedIndex = 0;
  bool _showReviewDetail = false;
  MentorAttemptInfo? _selectedSubmission;
  List<AttemptQuestionInfo> _submissionQuestions = [];
  final _commentController = TextEditingController();
  bool _isLoadingDetail = false;

  @override
  void initState() {
    super.initState();
    _loadQuizzes();
  }

  Future<void> _loadQuizzes() async {
    try {
      final quizzes = await _quizService.getMyQuizzes();
      setState(() {
        _quizzes = quizzes;
        _isLoadingQuizzes = false;
        if (_quizzes.isNotEmpty && _selectedQuiz == null) {
          _selectedQuiz = _quizzes.first;
        }
      });
      if (_selectedQuiz != null) {
        _loadSubmissions();
      }
    } catch (e) {
      setState(() {
        _isLoadingQuizzes = false;
      });
    }
  }

  Future<void> _loadSubmissions() async {
    if (_selectedQuiz == null) return;

    try {
      final attempts = await _attemptService.getAttemptsByQuiz(_selectedQuiz!.id!);
      setState(() {
        _submissions = attempts;
        _pendingSubmissions = attempts.where((a) => a.status == AttemptStatus.IN_PROGRESS).toList();
        _reviewedSubmissions = attempts.where((a) => a.status == AttemptStatus.SUBMITTED).toList();
        _isLoadingSubmissions = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingSubmissions = false;
      });
    }
  }

  Future<void> _loadSubmissionDetail(MentorAttemptInfo submission) async {
    setState(() {
      _isLoadingDetail = true;
    });

    try {
      final questions = await _attemptService.getAttemptQuestions(submission.attemptId);
      setState(() {
        _submissionQuestions = questions;
        _isLoadingDetail = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingDetail = false;
      });
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF9F9FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back, color: Colors.black),
        ),
        title: const Text(
          'Chấm bài',
          style: TextStyle(
            color: Color(0xff0F172A),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.filter_list, color: Color(0xff64748B)),
          ),
        ],
      ),
      body: _isLoadingQuizzes
          ? const Center(child: CircularProgressIndicator())
          : _showReviewDetail
              ? _buildReviewDetailView()
              : _buildSubmissionListView(),
      bottomNavigationBar: _showReviewDetail
          ? _buildBottomActions()
          : null,
    );
  }

  Widget _buildSubmissionListView() {
    return Column(
      children: [
        // Quiz selector
        if (_quizzes.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xffE2E8F0)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<QuizModel>(
                  value: _selectedQuiz,
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xff0074DB)),
                  items: _quizzes.map((quiz) {
                    return DropdownMenuItem(
                      value: quiz,
                      child: Row(
                        children: [
                          const Icon(Icons.quiz_outlined, size: 18, color: Color(0xff0074DB)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              quiz.title,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (quiz) {
                    if (quiz != null) {
                      setState(() {
                        _selectedQuiz = quiz;
                        _showReviewDetail = false;
                      });
                      _loadSubmissions();
                    }
                  },
                ),
              ),
            ),
          ),

        // Search bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Tìm kiếm bài nộp...',
              prefixIcon: const Icon(Icons.search, color: Color(0xff94A3B8)),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Tab filter
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _buildTabChip('Tất cả (${_submissions.length})', _selectedIndex == 0, () {
                setState(() => _selectedIndex = 0);
              }),
              const SizedBox(width: 8),
              _buildTabChip('Chờ xem (${_pendingSubmissions.length})', _selectedIndex == 1, () {
                setState(() => _selectedIndex = 1);
              }),
              const SizedBox(width: 8),
              _buildTabChip('Đã xem (${_reviewedSubmissions.length})', _selectedIndex == 2, () {
                setState(() => _selectedIndex = 2);
              }),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // List
        Expanded(
          child: _isLoadingSubmissions
              ? const Center(child: CircularProgressIndicator())
              : _submissions.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.assignment_outlined, size: 64, color: Colors.grey[300]),
                          const SizedBox(height: 12),
                          Text(
                            'Chưa có bài nộp nào',
                            style: TextStyle(fontSize: 16, color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    )
                  : _buildFilteredSubmissions(),
        ),
      ],
    );
  }

  Widget _buildFilteredSubmissions() {
    List<MentorAttemptInfo> filtered;
    switch (_selectedIndex) {
      case 1:
        filtered = _pendingSubmissions;
        break;
      case 2:
        filtered = _reviewedSubmissions;
        break;
      default:
        filtered = _submissions;
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: filtered.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final sub = filtered[index];
        return _buildSubmissionCard(sub, index);
      },
    );
  }

  Widget _buildTabChip(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: active ? const Color(0xff0074DB) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? const Color(0xff0074DB) : const Color(0xffE2E8F0),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: active ? Colors.white : const Color(0xff64748B),
          ),
        ),
      ),
    );
  }

  Widget _buildSubmissionCard(MentorAttemptInfo sub, int index) {
    final isPending = sub.status == AttemptStatus.IN_PROGRESS;
    final statusBg = isPending ? const Color(0xffFEF3C7) : const Color(0xffDCFCE7);
    final statusTextColor = isPending ? const Color(0xffB45309) : const Color(0xff15803D);
    final statusText = isPending ? 'Chờ xem' : 'Đã xem';

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
          _selectedSubmission = sub;
          _showReviewDetail = true;
        });
        _loadSubmissionDetail(sub);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
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
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xffDBEAFE),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    sub.initials,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xff005BAF),
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sub.userName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xff0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.access_time,
                              size: 13, color: Color(0xff94A3B8)),
                          const SizedBox(width: 4),
                          Text(
                            _formatDateTime(sub.startedAt),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xff64748B),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: statusTextColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      sub.score != null ? '${sub.score!.toInt()}/100' : '--/100',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xff005BAF),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xffF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sub.quizTitle,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff1E293B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.menu_book,
                          size: 13, color: Color(0xff64748B)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          sub.courseTitle,
                          style: const TextStyle(
                              fontSize: 11, color: Color(0xff414753)),
                        ),
                      ),
                      const Icon(Icons.chevron_right,
                          size: 18, color: Color(0xff94A3B8)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} phút trước';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} giờ trước';
    } else if (diff.inDays == 1) {
      return 'Hôm qua';
    } else {
      return '${dt.day}/${dt.month}/${dt.year}';
    }
  }

  Widget _buildReviewDetailView() {
    if (_isLoadingDetail) {
      return const Center(child: CircularProgressIndicator());
    }

    final selected = _selectedSubmission;
    if (selected == null) {
      return const Center(child: Text('Không có dữ liệu'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back button + title
          Row(
            children: [
              GestureDetector(
                onTap: () => setState(() => _showReviewDetail = false),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xffE2E8F0)),
                  ),
                  child: const Icon(Icons.arrow_back,
                      size: 20, color: Color(0xff475569)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  selected.userName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff0F172A),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Student info card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xff3B82F6), Color(0xff1D4ED8)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        selected.initials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            selected.userName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xff0F172A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.book_outlined,
                                  size: 14, color: Color(0xff64748B)),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  selected.courseTitle,
                                  style: const TextStyle(
                                      fontSize: 12, color: Color(0xff64748B)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xff005BAF).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        children: [
                          Text(
                            selected.score != null ? '${selected.score!.toInt()}' : '--',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: Color(0xff005BAF),
                            ),
                          ),
                          const Text(
                            '/100',
                            style: TextStyle(
                              fontSize: 10,
                              color: Color(0xff005BAF),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xffF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.quiz_outlined,
                          size: 16, color: Color(0xff64748B)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          selected.quizTitle,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xff334155),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Questions
          Row(
            children: const [
              Icon(Icons.analytics, color: Color(0xff005BAF), size: 20),
              SizedBox(width: 8),
              Text(
                'CHI TIẾT BÀI LÀM',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.1,
                  color: Color(0xff0F172A),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          if (_submissionQuestions.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              child: const Center(
                child: Text(
                  'Không có chi tiết câu hỏi',
                  style: TextStyle(color: Color(0xff64748B)),
                ),
              ),
            )
          else
            ..._submissionQuestions.asMap().entries.map((entry) {
              final index = entry.key + 1;
              final q = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _buildQuestionCard(q, index),
              );
            }),

          const SizedBox(height: 20),

          // Comment
          const Text(
            'Nhận xét của Mentor',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xff334155),
            ),
          ),
          const SizedBox(height: 10),

          TextField(
            controller: _commentController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Viết phản hồi cho học viên...',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),

          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xffEFF6FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xffDBEAFE)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: Color(0xff3B82F6), size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Vui lòng nhập nhận xét cho học viên sau khi xem chi tiết bài làm.',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: Color(0xff1D4ED8),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(AttemptQuestionInfo q, int index) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xffF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                q.isCorrect ? Icons.check_circle : Icons.cancel,
                color: q.isCorrect
                    ? const Color(0xff22C55E)
                    : const Color(0xffBA1A1A),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Câu $index: ${q.questionText}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff1E293B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(
                width: 100,
                child: Text(
                  'Học viên chọn:',
                  style: TextStyle(fontSize: 11, color: Color(0xff64748B)),
                ),
              ),
              Expanded(
                child: Text(
                  q.studentAnswer ?? 'Không chọn',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: q.isCorrect
                        ? const Color(0xff0F172A)
                        : const Color(0xffBA1A1A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(
                width: 100,
                child: Text(
                  'Đáp án đúng:',
                  style: TextStyle(fontSize: 11, color: Color(0xff64748B)),
                ),
              ),
              Expanded(
                child: Text(
                  q.correctAnswer ?? '-',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xff16A34A),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                setState(() => _showReviewDetail = false);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff0074DB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: const StadiumBorder(),
                elevation: 3,
              ),
              child: const Text(
                'Xác nhận đã xem',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xffF1F5F9),
              borderRadius: BorderRadius.circular(30),
            ),
            child: IconButton(
              onPressed: () {},
              icon: const Icon(Icons.bookmark_border,
                  color: Color(0xff475569)),
            ),
          ),
        ],
      ),
    );
  }
}
