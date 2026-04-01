import 'package:flutter/material.dart';

/// Mentor Review Assignment - Mobile Layout
class MentorReviewAssignmentMobile extends StatefulWidget {
  const MentorReviewAssignmentMobile({super.key});

  @override
  State<MentorReviewAssignmentMobile> createState() =>
      _MentorReviewAssignmentMobileState();
}

class _MentorReviewAssignmentMobileState
    extends State<MentorReviewAssignmentMobile> {
  int _selectedIndex = 0;
  bool _showReviewDetail = false;
  final _commentController = TextEditingController();

  // Mock data
  final List<_SubmissionData> _submissions = [
    _SubmissionData(
      id: '1',
      initials: 'LB',
      studentName: 'Lê Thị B',
      dateText: '14:30 · Hôm nay',
      status: _SubmissionStatus.pending,
      testTitle: 'Kiểm tra kiến thức UX Research',
      courseTitle: 'UX/UI Design Advanced',
      score: 85,
    ),
    _SubmissionData(
      id: '2',
      initials: 'TM',
      studentName: 'Trần Minh A',
      dateText: '09:00 · Hôm nay',
      status: _SubmissionStatus.pending,
      testTitle: 'Final Assignment - React',
      courseTitle: 'Frontend Development Basics',
      score: 72,
    ),
    _SubmissionData(
      id: '3',
      initials: 'NH',
      studentName: 'Nguyễn Hương H',
      dateText: '18:00 · Hôm qua',
      status: _SubmissionStatus.reviewed,
      testTitle: 'Bài tập về nhà Module 3',
      courseTitle: 'Frontend Development Basics',
      score: 90,
    ),
    _SubmissionData(
      id: '4',
      initials: 'PV',
      studentName: 'Phạm Văn C',
      dateText: '15:30 · Hôm qua',
      status: _SubmissionStatus.reviewed,
      testTitle: 'Final Assignment - React',
      courseTitle: 'Frontend Development Basics',
      score: 60,
    ),
  ];

  final List<_QuestionData> _questions = [
    _QuestionData(
      question: 'Câu 1: Mục đích chính của User Interview là gì?',
      studentAnswer: 'Hiểu sâu về hành vi và nhu cầu',
      correctAnswer: 'Hiểu sâu về hành vi và nhu cầu',
      isCorrect: true,
    ),
    _QuestionData(
      question:
          'Câu 2: Số lượng người tham gia tối thiểu cho một buổi Usability Testing cơ bản là bao nhiêu?',
      studentAnswer: '15 người',
      correctAnswer: '5 người',
      isCorrect: false,
    ),
    _QuestionData(
      question:
          'Câu 3: Phương pháp nào được sử dụng để thu thập dữ liệu định lượng?',
      studentAnswer: 'Khảo sát trực tuyến (Survey)',
      correctAnswer: 'Khảo sát trực tuyến (Survey)',
      isCorrect: true,
    ),
  ];

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
      body: _showReviewDetail
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
        // Search bar
        Padding(
          padding: const EdgeInsets.all(16),
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

        // Tab filter
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _buildTabChip('Tất cả (4)', true),
              const SizedBox(width: 8),
              _buildTabChip('Chờ xem (2)', false),
              const SizedBox(width: 8),
              _buildTabChip('Đã xem (2)', false),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // List
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _submissions.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final sub = _submissions[index];
              final isActive = _selectedIndex == index;
              return _buildSubmissionCard(sub, isActive, index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTabChip(String label, bool active) {
    return Container(
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
    );
  }

  Widget _buildSubmissionCard(
      _SubmissionData sub, bool isActive, int index) {
    final statusBg = sub.status == _SubmissionStatus.pending
        ? const Color(0xffFEF3C7)
        : const Color(0xffDCFCE7);
    final statusTextColor = sub.status == _SubmissionStatus.pending
        ? const Color(0xffB45309)
        : const Color(0xff15803D);
    final statusText =
        sub.status == _SubmissionStatus.pending ? 'Chờ xem' : 'Đã xem';

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
          _showReviewDetail = true;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: isActive
              ? Border.all(color: const Color(0xff0074DB), width: 2)
              : null,
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
                        sub.studentName,
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
                            sub.dateText,
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
                      '${sub.score}/100',
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
                    sub.testTitle,
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

  Widget _buildReviewDetailView() {
    final selected = _submissions[_selectedIndex];

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
                  selected.studentName,
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
                            selected.studentName,
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
                            '${selected.score}',
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
                          selected.testTitle,
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

          ..._questions.map((q) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _buildQuestionCard(q),
              )),

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
                    'Học viên nắm vững lý thuyết nhưng cần xem lại Usability Testing.',
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

  Widget _buildQuestionCard(_QuestionData q) {
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
                  q.question,
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
                  q.studentAnswer,
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
                  q.correctAnswer,
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

// ============ Data models ============

enum _SubmissionStatus { pending, reviewed }

class _SubmissionData {
  final String id;
  final String initials;
  final String studentName;
  final String dateText;
  final _SubmissionStatus status;
  final String testTitle;
  final String courseTitle;
  final int score;

  _SubmissionData({
    required this.id,
    required this.initials,
    required this.studentName,
    required this.dateText,
    required this.status,
    required this.testTitle,
    required this.courseTitle,
    required this.score,
  });
}

class _QuestionData {
  final String question;
  final String studentAnswer;
  final String correctAnswer;
  final bool isCorrect;

  _QuestionData({
    required this.question,
    required this.studentAnswer,
    required this.correctAnswer,
    required this.isCorrect,
  });
}
