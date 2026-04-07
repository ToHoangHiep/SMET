import 'package:flutter/material.dart';
import 'package:smet/model/course_model.dart';
import 'package:smet/model/course_review_model.dart';
import 'package:smet/model/question_model.dart';
import 'package:smet/service/mentor/course_review_service.dart';
import 'package:smet/service/mentor/course_service.dart';
import 'package:smet/service/mentor/question_service.dart';
import 'package:smet/page/shared/widgets/shared_breadcrumb.dart';

/// Mentor Quiz Review - Web Layout
/// Endpoint: GET /api/mentor/course-review/{courseId}
class MentorQuizReviewWeb extends StatefulWidget {
  const MentorQuizReviewWeb({super.key});

  @override
  State<MentorQuizReviewWeb> createState() => _MentorQuizReviewWebState();
}

class _MentorQuizReviewWebState extends State<MentorQuizReviewWeb> {
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

  int _currentPage = 0;
  int _totalPages = 0;
  int _totalElements = 0;

  List<CourseReviewItem> _students = [];
  CourseReviewItem? _selectedStudent;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

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
          _loadCourseReview();
        }
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoadingCourses = false;
      });
    }
  }

  Future<void> _loadCourseReview({int page = 0}) async {
    if (_selectedCourse == null) return;

    setState(() {
      _isLoadingReview = true;
      _error = null;
      _currentPage = page;
    });

    try {
      final response = await _reviewService.getCourseReview(
        courseId: _selectedCourse!.id,
        page: page,
        size: 20,
      );

      setState(() {
        _students = response.items;
        _totalPages = response.totalPages;
        _totalElements = response.totalElements;
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
    // Lấy tất cả unique quizId
    final quizIds = <Long>{};
    for (final student in students) {
      for (final quiz in student.quizzes) {
        quizIds.add(quiz.quizId);
      }
    }

    // Gọi song song cho các quiz chưa có trong cache
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
      body: Column(
        children: [
          _buildTopHeader(),
          Expanded(
            child: _buildMainContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildTopHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: BreadcrumbPageHeader(
              pageTitle: 'Quiz Review',
              pageIcon: Icons.quiz_rounded,
              breadcrumbs: const [
                BreadcrumbItem(label: 'Mentor', route: '/mentor/dashboard'),
                BreadcrumbItem(label: 'Quiz Review'),
              ],
              primaryColor: const Color(0xFF6366F1),
            ),
          ),
          const SizedBox(width: 16),
          if (!_isLoadingCourses && _courses.isNotEmpty)
            _buildCourseSelector(),
          const SizedBox(width: 16),
          _buildSearchBar(),
        ],
      ),
    );
  }

  Widget _buildCourseSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F3FD),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E7FF)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<CourseResponse>(
          value: _selectedCourse,
          icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF6366F1)),
          items: _courses.map((course) {
            return DropdownMenuItem(
              value: course,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.menu_book, size: 18, color: Color(0xFF6366F1)),
                  const SizedBox(width: 8),
                  Text(
                    course.title,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
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
              });
              _loadCourseReview();
            }
          },
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return SizedBox(
      width: 280,
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Tìm kiếm học viên...',
          prefixIcon: const Icon(Icons.search, color: Color(0xFF94A3B8)),
          filled: true,
          fillColor: const Color(0xFFF1F3FD),
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

  Widget _buildMainContent() {
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
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left panel - Student list
        Expanded(
          flex: 4,
          child: _buildStudentList(),
        ),
        // Right panel - Quiz detail
        Expanded(
          flex: 6,
          child: _buildQuizDetailPanel(),
        ),
      ],
    );
  }

  Widget _buildStudentList() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStudentListHeader(),
          const SizedBox(height: 12),
          Expanded(
            child: _buildStudentListContent(),
          ),
          if (_totalPages > 1) _buildPagination(),
        ],
      ),
    );
  }

  Widget _buildStudentListHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
      child: Row(
        children: [
          const Icon(Icons.people_alt_rounded, color: Color(0xFF6366F1), size: 20),
          const SizedBox(width: 8),
          const Text(
            'DANH SÁCH HỌC VIÊN',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
              color: Color(0xFF64748B),
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$_totalElements',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6366F1),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentListContent() {
    if (_isLoadingReview) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _students.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 36, color: Colors.red),
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 12)),
            const SizedBox(height: 8),
            TextButton(
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
            Icon(Icons.people_outline, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 8),
            Text(
              'Chưa có học viên nào',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    final filteredStudents = _searchQuery.isEmpty
        ? _students
        : _students.where((s) => s.userName.toLowerCase().contains(_searchQuery)).toList();

    if (filteredStudents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 8),
            Text(
              'Không tìm thấy học viên',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return Container(
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
        itemCount: filteredStudents.length,
        separatorBuilder: (_, __) => const SizedBox(height: 4),
        itemBuilder: (context, index) {
          final student = filteredStudents[index];
          final isSelected = _selectedStudent?.userId == student.userId;
          return _StudentCard(
            student: student,
            isSelected: isSelected,
            onTap: () {
              setState(() {
                _selectedStudent = student;
              });
              _loadQuizOptionsForStudent(student);
            },
          );
        },
      ),
    );
  }

  Widget _buildPagination() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: _currentPage > 0
                ? () => _loadCourseReview(page: _currentPage - 1)
                : null,
            icon: const Icon(Icons.chevron_left),
            color: const Color(0xFF6366F1),
          ),
          const SizedBox(width: 8),
          Text(
            'Trang ${_currentPage + 1} / $_totalPages',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _currentPage < _totalPages - 1
                ? () => _loadCourseReview(page: _currentPage + 1)
                : null,
            icon: const Icon(Icons.chevron_right),
            color: const Color(0xFF6366F1),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizDetailPanel() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: _selectedStudent != null
          ? _QuizDetailView(
              student: _selectedStudent!,
              quizQuestionCache: _quizQuestionCache,
            )
          : _buildEmptyDetailPanel(),
    );
  }

  Widget _buildEmptyDetailPanel() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.touch_app_rounded, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'Chọn học viên để xem chi tiết',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[500],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Nhấp vào một học viên trong danh sách bên trái',
              style: TextStyle(fontSize: 13, color: Colors.grey[400]),
            ),
          ],
        ),
      ),
    );
  }
}

class _StudentCard extends StatelessWidget {
  final CourseReviewItem student;
  final bool isSelected;
  final VoidCallback onTap;

  const _StudentCard({
    required this.student,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scoreColor = _getScoreColor(student.avgScore);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEEF2FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(color: const Color(0xFF6366F1), width: 2)
              : null,
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 44,
              height: 44,
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
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student.userName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? const Color(0xFF6366F1) : const Color(0xFF1E293B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.quiz_outlined,
                        size: 14,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${student.quizzes.length} quiz',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                      const SizedBox(width: 12),
                      _buildScoreBadge(student.avgScore, scoreColor),
                    ],
                  ),
                ],
              ),
            ),
            // Arrow
            Icon(
              Icons.chevron_right_rounded,
              color: isSelected ? const Color(0xFF6366F1) : Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreBadge(double? score, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        score != null ? '${score.toStringAsFixed(1)}%' : 'N/A',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
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

class _QuizDetailView extends StatelessWidget {
  final CourseReviewItem student;
  final Map<Long, List<QuestionModel>> quizQuestionCache;

  const _QuizDetailView({
    required this.student,
    required this.quizQuestionCache,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStudentHeader(),
            const SizedBox(height: 20),
            _buildSummaryCards(),
            const SizedBox(height: 24),
            _buildQuizTabs(),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentHeader() {
    final scoreColor = _getScoreColor(student.avgScore);

    return Container(
      padding: const EdgeInsets.all(20),
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
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [scoreColor.withOpacity(0.8), scoreColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: Text(
              student.initials,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student.userName,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    _buildInfoChip(
                      Icons.menu_book_outlined,
                      '${student.quizzes.length} bài quiz',
                    ),
                    _buildInfoChip(
                      Icons.help_outline,
                      '${student.totalQuestions} câu hỏi',
                    ),
                    _buildInfoChip(
                      Icons.check_circle_outline,
                      '${student.correctAnswers} đúng',
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: scoreColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: scoreColor.withOpacity(0.2)),
            ),
            child: Column(
              children: [
                const Text(
                  'ĐIỂM TB',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  student.avgScore != null
                      ? '${student.avgScore!.toStringAsFixed(1)}'
                      : 'N/A',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: scoreColor,
                  ),
                ),
                const Text(
                  'ĐIỂM',
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

  Widget _buildInfoChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF64748B)),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCards() {
    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            icon: Icons.quiz_outlined,
            title: 'Số Quiz',
            value: '${student.quizzes.length}',
            color: const Color(0xFF6366F1),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            icon: Icons.help_outline,
            title: 'Tổng Câu Hỏi',
            value: '${student.totalQuestions}',
            color: const Color(0xFF0EA5E9),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            icon: Icons.check_circle,
            title: 'Câu Đúng',
            value: '${student.correctAnswers}',
            color: const Color(0xFF22C55E),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            icon: Icons.cancel_outlined,
            title: 'Câu Sai',
            value: '${student.totalQuestions - student.correctAnswers}',
            color: const Color(0xFFEF4444),
          ),
        ),
      ],
    );
  }

  Widget _buildQuizTabs() {
    return DefaultTabController(
      length: student.quizzes.length,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TabBar(
            isScrollable: true,
            labelColor: const Color(0xFF6366F1),
            unselectedLabelColor: const Color(0xFF64748B),
            indicatorColor: const Color(0xFF6366F1),
            indicatorWeight: 3,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
            tabs: student.quizzes.map((quiz) {
              return Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.quiz_outlined, size: 18),
                    const SizedBox(width: 8),
                    Text(quiz.quizTitle),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 600,
            child: TabBarView(
              children: student.quizzes.map((quiz) {
                return _QuizQuestionList(
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

  Color _getScoreColor(double? score) {
    if (score == null) return Colors.grey;
    if (score >= 80) return const Color(0xFF22C55E);
    if (score >= 60) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }
}

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _SummaryCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuizQuestionList extends StatelessWidget {
  final QuizItem quiz;
  final List<QuestionModel> questionCache;

  const _QuizQuestionList({required this.quiz, required this.questionCache});

  @override
  Widget build(BuildContext context) {
    final correctCount = quiz.questions.where((q) => q.isCorrect).length;
    final accuracy = quiz.questions.isNotEmpty
        ? (correctCount / quiz.questions.length * 100)
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildQuizHeader(quiz, correctCount, accuracy),
        const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
            itemCount: quiz.questions.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              return _QuestionCard(
                question: quiz.questions[index],
                index: index + 1,
                questionCache: questionCache,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildQuizHeader(QuizItem quiz, int correctCount, double accuracy) {
    final statusColor = quiz.isPassed ? const Color(0xFF22C55E) : const Color(0xFFF59E0B);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  quiz.quizTitle,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                if (quiz.moduleTitle != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.folder_outlined, size: 14, color: Color(0xFF64748B)),
                      const SizedBox(width: 4),
                      Text(
                        quiz.moduleTitle!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${quiz.score?.toStringAsFixed(1) ?? "N/A"}%',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$correctCount/${quiz.questions.length} đúng',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                ),
              ),
              Text(
                '${accuracy.toStringAsFixed(0)}% accuracy',
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  final QuestionItem question;
  final int index;
  final List<QuestionModel> questionCache;

  const _QuestionCard({
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

  /// Tìm nội dung option từ cache dựa trên optionId
  String _getOptionContent(Long optionId) {
    final cached = _cachedQuestion;
    if (cached?.options != null) {
      for (final opt in cached!.options!) {
        if (opt.id?.value == optionId.value) {
          return opt.content;
        }
      }
    }
    return 'Đáp án ${optionId.value}';
  }

  @override
  Widget build(BuildContext context) {
    final isCorrect = question.isCorrect;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCorrect
              ? const Color(0xFF22C55E).withOpacity(0.3)
              : const Color(0xFFEF4444).withOpacity(0.3),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isCorrect
                      ? const Color(0xFF22C55E).withOpacity(0.1)
                      : const Color(0xFFEF4444).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Icon(
                  isCorrect ? Icons.check : Icons.close,
                  size: 18,
                  color: isCorrect ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(4),
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
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isCorrect
                                ? const Color(0xFFDCFCE7)
                                : const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isCorrect ? 'ĐÚNG' : 'SAI',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isCorrect
                                  ? const Color(0xFF15803D)
                                  : const Color(0xFFDC2626),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      question.content,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Color(0xFFE2E8F0), height: 1),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _AnswerColumn(
                  title: 'Đáp án học viên chọn',
                  answers: question.selectedAnswers
                      .map((id) => _getOptionContent(id))
                      .toList(),
                  isCorrect: isCorrect,
                  isSelected: true,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _AnswerColumn(
                  title: 'Đáp án đúng',
                  answers: question.correctAnswers
                      .map((id) => _getOptionContent(id))
                      .toList(),
                  isCorrect: true,
                  isSelected: false,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AnswerColumn extends StatelessWidget {
  final String title;
  final List<String> answers;
  final bool isCorrect;
  final bool isSelected;

  const _AnswerColumn({
    required this.title,
    required this.answers,
    required this.isCorrect,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              isSelected
                  ? (isCorrect ? Icons.check_circle : Icons.cancel)
                  : Icons.check_circle_outline,
              size: 16,
              color: isCorrect
                  ? const Color(0xFF22C55E)
                  : (isSelected ? const Color(0xFFEF4444) : const Color(0xFF22C55E)),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? (isCorrect ? const Color(0xFF22C55E) : const Color(0xFFEF4444))
                      : const Color(0xFF22C55E),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (answers.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              isSelected ? 'Không chọn đáp án' : '-',
              style: TextStyle(
                fontSize: 13,
                color: isSelected ? const Color(0xFFEF4444) : const Color(0xFF94A3B8),
                fontStyle: isSelected ? FontStyle.normal : FontStyle.italic,
              ),
            ),
          )
        else
          ...answers.map((answer) => Container(
                margin: const EdgeInsets.only(bottom: 4),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isCorrect
                          ? const Color(0xFFDCFCE7)
                          : const Color(0xFFFEE2E2))
                      : const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isSelected
                          ? (isCorrect ? Icons.check : Icons.close)
                          : Icons.check,
                      size: 14,
                      color: isCorrect
                          ? const Color(0xFF22C55E)
                          : const Color(0xFFEF4444),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        answer,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isCorrect
                              ? const Color(0xFF15803D)
                              : const Color(0xFFDC2626),
                        ),
                      ),
                    ),
                  ],
                ),
              )),
      ],
    );
  }
}
