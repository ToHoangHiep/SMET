import 'package:flutter/material.dart';
import 'package:smet/model/course_model.dart';
import 'package:smet/model/course_review_model.dart';
import 'package:smet/model/question_model.dart';
import 'package:smet/service/mentor/course_review_service.dart';
import 'package:smet/service/mentor/course_service.dart';
import 'package:smet/service/mentor/question_service.dart';

/// Mentor Quiz Review - Mobile Layout
class MentorQuizReviewMobile extends StatefulWidget {
  const MentorQuizReviewMobile({super.key});

  @override
  State<MentorQuizReviewMobile> createState() => _MentorQuizReviewMobileState();
}

class _MentorQuizReviewMobileState extends State<MentorQuizReviewMobile> {
  final CourseReviewService _reviewService = CourseReviewService();
  final MentorCourseService _courseService = MentorCourseService();
  final MentorQuestionService _questionService = MentorQuestionService();

  // Cache: quizId -> List<QuestionModel> (với options đã được load)
  final Map<Long, List<QuestionModel>> _quizQuestionCache = {};

  // State
  bool _isLoadingCourses = true;
  bool _isLoadingReview = false;
  String? _error;

  List<CourseResponse> _courses = [];
  CourseResponse? _selectedCourse;

  CourseReviewItem? _selectedStudent;
  bool _showDetail = false;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  List<CourseReviewItem> _students = [];
  List<CourseReviewItem> _filteredStudents = [];

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCourses() async {
    setState(() {
      _isLoadingCourses = true;
      _error = null;
    });

    try {
      final response = await _courseService.listCourses(isMine: true, size: 100);
      setState(() {
        _courses = response.content;
        _isLoadingCourses = false;
        if (_courses.isNotEmpty && _selectedCourse == null) {
          _selectedCourse = _courses.first;
        }
      });
      if (_selectedCourse != null) {
        _loadCourseReview();
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoadingCourses = false;
      });
    }
  }

  Future<void> _loadCourseReview() async {
    if (_selectedCourse == null) return;

    setState(() {
      _isLoadingReview = true;
      _error = null;
    });

    try {
      final response = await _reviewService.getCourseReview(
        courseId: _selectedCourse!.id,
        size: 100,
      );
      setState(() {
        _students = response.items;
        _isLoadingReview = false;
      });

      // Gọi song song API lấy options cho tất cả quiz trong danh sách
      _preloadQuizOptions(response.items);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoadingReview = false;
      });
    }
  }

  /// Gọi API lấy chi tiết câu hỏi + options cho từng quiz (cache lại)
  Future<void> _preloadQuizOptions(List<CourseReviewItem> students) async {
    final quizIds = <Long>{};
    for (final student in students) {
      for (final quiz in student.quizzes) {
        quizIds.add(quiz.quizId);
      }
    }

    final futures = <Future<void>>[];
    for (final quizId in quizIds) {
      if (!_quizQuestionCache.containsKey(quizId)) {
        futures.add(_loadQuizOptions(quizId));
      }
    }

    if (futures.isNotEmpty) {
      await Future.wait(futures);
    }
  }

  Future<void> _loadQuizOptions(Long quizId) async {
    try {
      final questions = await _questionService.getQuestionsByQuiz(quizId);
      if (mounted) {
        setState(() {
          _quizQuestionCache[quizId] = questions;
        });
      }
    } catch (e) {
      // Nếu fail, vẫn tiếp tục — UI sẽ hiển thị ID fallback
    }
  }

  /// Khi chọn student mới, kiểm tra quiz nào chưa load → load thêm
  Future<void> _loadQuizOptionsForStudent(CourseReviewItem student) async {
    final futures = <Future<void>>[];
    for (final quiz in student.quizzes) {
      if (!_quizQuestionCache.containsKey(quiz.quizId)) {
        futures.add(_loadQuizOptions(quiz.quizId));
      }
    }
    if (futures.isNotEmpty) {
      await Future.wait(futures);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quiz Review',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          Text(
            'Xem kết quả quiz học viên',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.normal,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.filter_list, color: Color(0xFF6366F1)),
          onPressed: _showFilterSheet,
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (_isLoadingCourses) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _courses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadCourses,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    if (_courses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.menu_book_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Bạn chưa có khóa học nào',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildCourseSelector(),
        _buildSearchBar(),
        Expanded(
          child: _showDetail && _selectedStudent != null
              ? _buildDetailView()
              : _buildStudentList(),
        ),
      ],
    );
  }

  Widget _buildCourseSelector() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.white,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F3FD),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE0E7FF)),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<CourseResponse>(
            value: _selectedCourse,
            isExpanded: true,
            icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF6366F1)),
            items: _courses.map((course) {
              return DropdownMenuItem(
                value: course,
                child: Row(
                  children: [
                    const Icon(Icons.menu_book, size: 18, color: Color(0xFF6366F1)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        course.title,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            onChanged: (course) {
              if (course != null) {
                setState(() {
                  _selectedCourse = course;
                  _selectedStudent = null;
                  _showDetail = false;
                });
                _loadCourseReview();
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Tìm kiếm học viên...',
          prefixIcon: const Icon(Icons.search, color: Color(0xFF94A3B8)),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value.toLowerCase();
          });
        },
      ),
    );
  }

  Widget _buildStudentList() {
    if (_isLoadingReview) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _students.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadCourseReview,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    if (_students.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Chưa có học viên nào',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    _filteredStudents = _searchQuery.isEmpty
        ? _students
        : _students.where((s) => s.userName.toLowerCase().contains(_searchQuery)).toList();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListView.separated(
        padding: const EdgeInsets.all(8),
        itemCount: _filteredStudents.length,
        separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
        itemBuilder: (context, index) {
          final student = _filteredStudents[index];
          return _MobileStudentCard(
            student: student,
            onTap: () {
              setState(() {
                _selectedStudent = student;
                _showDetail = true;
              });
              _loadQuizOptionsForStudent(student);
            },
          );
        },
      ),
    );
  }

  Widget _buildDetailView() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFF6366F1)),
                onPressed: () {
                  setState(() {
                    _showDetail = false;
                  });
                },
              ),
              const Expanded(
                child: Text(
                  'Chi tiết kết quả',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
        ),
        Expanded(
          child: _MobileQuizDetailView(
            student: _selectedStudent!,
            quizQuestionCache: _quizQuestionCache,
          ),
        ),
      ],
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Bộ lọc',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Điểm tối thiểu',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  _FilterChip(label: 'Tất cả', selected: true, onTap: () {}),
                  _FilterChip(label: '>= 80%', selected: false, onTap: () {}),
                  _FilterChip(label: '>= 60%', selected: false, onTap: () {}),
                  _FilterChip(label: '< 60%', selected: false, onTap: () {}),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Áp dụng'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF6366F1) : const Color(0xFFF1F3FD),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? const Color(0xFF6366F1) : const Color(0xFFE0E7FF),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }
}

class _MobileStudentCard extends StatelessWidget {
  final CourseReviewItem student;
  final VoidCallback onTap;

  const _MobileStudentCard({
    required this.student,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scoreColor = _getScoreColor(student.avgScore);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    scoreColor.withOpacity(0.8),
                    scoreColor,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(
                student.initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student.userName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '${student.quizzes.length} quiz',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: scoreColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          student.avgScore != null
                              ? '${student.avgScore!.toStringAsFixed(1)}%'
                              : 'N/A',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: scoreColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  Color _getScoreColor(double? score) {
    if (score == null) return Colors.grey;
    if (score >= 80) return const Color(0xFF22C55E);
    if (score >= 60) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }
}

class _MobileQuizDetailView extends StatelessWidget {
  final CourseReviewItem student;
  final Map<Long, List<QuestionModel>> quizQuestionCache;

  const _MobileQuizDetailView({
    required this.student,
    required this.quizQuestionCache,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: student.quizzes.length,
      child: Column(
        children: [
          _buildHeader(),
          TabBar(
            isScrollable: true,
            labelColor: const Color(0xFF6366F1),
            unselectedLabelColor: const Color(0xFF64748B),
            indicatorColor: const Color(0xFF6366F1),
            tabs: student.quizzes.map((quiz) {
              return Tab(text: quiz.quizTitle);
            }).toList(),
          ),
          Expanded(
            child: TabBarView(
              children: student.quizzes.map((quiz) {
                return _MobileQuestionList(
                  quiz: quiz,
                  questionCache: quizQuestionCache[quiz.quizId] ?? [],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final scoreColor = _getScoreColor(student.avgScore);

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF6366F1).withOpacity(0.05),
            const Color(0xFF6366F1).withOpacity(0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E7FF)),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [scoreColor.withOpacity(0.8), scoreColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Text(
              student.initials,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student.userName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${student.totalQuestions} câu hỏi · ${student.correctAnswers} đúng',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: scoreColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  student.avgScore != null
                      ? '${student.avgScore!.toStringAsFixed(1)}'
                      : 'N/A',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: scoreColor,
                  ),
                ),
                const Text(
                  'Điểm TB',
                  style: TextStyle(
                    fontSize: 10,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(double? score) {
    if (score == null) return Colors.grey;
    if (score >= 80) return const Color(0xFF22C55E);
    if (score >= 60) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }
}

class _MobileQuestionList extends StatelessWidget {
  final QuizItem quiz;
  final List<QuestionModel> questionCache;

  const _MobileQuestionList({required this.quiz, required this.questionCache});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: quiz.questions.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return _MobileQuestionCard(
          question: quiz.questions[index],
          index: index + 1,
          questionCache: questionCache,
        );
      },
    );
  }
}

class _MobileQuestionCard extends StatelessWidget {
  final QuestionItem question;
  final int index;
  final List<QuestionModel> questionCache;

  const _MobileQuestionCard({
    required this.question,
    required this.index,
    required this.questionCache,
  });

  QuestionModel? get _cachedQuestion {
    for (final q in questionCache) {
      if (q.id?.value == question.questionId.value) return q;
    }
    return null;
  }

  String _getOptionContent(Long optionId) {
    final cached = _cachedQuestion;
    if (cached?.options != null && cached!.options!.isNotEmpty) {
      for (final opt in cached.options!) {
        if (opt.id?.value == optionId.value) {
          return opt.content;
        }
      }
      return '[Option ID: ${optionId.value}]';
    }
    return '[Option ID: ${optionId.value} - loading...]';
  }

  @override
  Widget build(BuildContext context) {
    final isCorrect = question.isCorrect;
    final statusColor = isCorrect ? const Color(0xFF22C55E) : const Color(0xFFEF4444);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: statusColor.withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Câu $index',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isCorrect
                      ? const Color(0xFFDCFCE7)
                      : const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isCorrect ? Icons.check : Icons.close,
                      size: 12,
                      color: isCorrect
                          ? const Color(0xFF15803D)
                          : const Color(0xFFDC2626),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isCorrect ? 'Đúng' : 'Sai',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isCorrect
                            ? const Color(0xFF15803D)
                            : const Color(0xFFDC2626),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _cachedQuestion?.content ?? question.content,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildAnswerRow(
                  'Đáp án chọn',
                  question.selectedAnswers.isEmpty
                      ? 'Không chọn'
                      : question.selectedAnswers
                          .map((id) => _getOptionContent(id))
                          .join(', '),
                  isCorrect: isCorrect,
                ),
                const SizedBox(height: 8),
                _buildAnswerRow(
                  'Đáp án đúng',
                  question.correctAnswers
                      .map((id) => _getOptionContent(id))
                      .join(', '),
                  isCorrect: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerRow(String label, String value, {required bool isCorrect}) {
    final color = isCorrect ? const Color(0xFF22C55E) : const Color(0xFFEF4444);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          isCorrect ? Icons.check_circle : Icons.cancel,
          size: 16,
          color: color,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
