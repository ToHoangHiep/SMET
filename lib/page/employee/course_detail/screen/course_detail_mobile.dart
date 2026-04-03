import 'package:flutter/material.dart';
import 'package:smet/model/Employee_course_model.dart';
import 'package:smet/page/employee/course_detail/widgets/syllabus_section.dart';
import 'package:smet/page/employee/course_detail/widgets/enroll_card.dart';

class CourseDetailMobile extends StatelessWidget {
  final CourseDetail course;
  final Map<int, bool> expandedModules;
  final void Function(int) onToggleModule;
  final bool isEnrolling;
  final bool isPreviewMode;
  final VoidCallback? onEnroll;
  final VoidCallback? onStartLearning;
  final Function(String) onNavigate;
  final VoidCallback onLogout;

  const CourseDetailMobile({
    super.key,
    required this.course,
    required this.expandedModules,
    required this.onToggleModule,
    required this.isEnrolling,
    required this.isPreviewMode,
    required this.onEnroll,
    required this.onStartLearning,
    required this.onNavigate,
    required this.onLogout,
  });

  String get _deadlineText {
    if (course.fixedDeadline != null && course.fixedDeadline!.isNotEmpty) {
      return 'Hạn chót: ${course.fixedDeadline}';
    }
    if (course.defaultDeadlineDays != null) {
      return 'Hạn chót: ${course.defaultDeadlineDays} ngày sau khi đăng ký';
    }
    return 'Không có giới hạn thời gian';
  }

  String get _deadlineStatusLabel {
    switch (course.deadlineStatus?.toUpperCase()) {
      case 'OVERDUE':
        return 'Quá hạn';
      case 'DUE_SOON':
        return 'Sắp hết hạn';
      case 'ON_TIME':
        return 'Còn thời gian';
      default:
        return '';
    }
  }

  Color get _deadlineStatusColor {
    switch (course.deadlineStatus?.toUpperCase()) {
      case 'OVERDUE':
        return const Color(0xFFEF4444);
      case 'DUE_SOON':
        return const Color(0xFFF59E0B);
      case 'ON_TIME':
        return const Color(0xFF22C55E);
      default:
        return const Color(0xFF64748B);
    }
  }

  List<SyllabusModule> get _modulesWithState {
    return course.modules.asMap().entries.map((entry) {
      final index = entry.key;
      final module = entry.value;
      return SyllabusModule(
        title: module.title,
        lessonCount: module.lessons.length,
        lessons: module.lessons
            .map((l) => SyllabusLesson(title: l.title, type: SyllabusLessonType.video))
            .toList(),
        isExpanded: expandedModules[index] ?? false,
        onToggle: () => onToggleModule(index),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF137FEC),
        elevation: 0,
        toolbarHeight: 64,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'SMETS',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
      drawer: _buildDrawer(context),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Hero Header ───────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF137FEC), Color(0xFF0F57D0)],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course.title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  if (course.description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      course.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.85),
                        height: 1.5,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 16),

                  // Mentor
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.person, size: 18, color: Colors.white),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Giảng viên',
                              style: TextStyle(
                                fontSize: 10,
                                color: Color(0xFFD0E8FF),
                              ),
                            ),
                            Text(
                              course.mentorName,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (course.departmentName != null) ...[
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Đơn vị',
                              style: TextStyle(
                                fontSize: 10,
                                color: Color(0xFFD0E8FF),
                              ),
                            ),
                            Text(
                              course.departmentName!,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // ─── Stats row ───────────────────────────────
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: _MobileStatChip(
                      icon: Icons.library_books,
                      label: '${course.moduleCount} chương',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _MobileStatChip(
                      icon: Icons.play_lesson,
                      label: '${course.lessonCount} bài học',
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Enroll Card
                  EnrollCard(
                    onEnroll: isPreviewMode ? null : onEnroll,
                    onStartLearning: onStartLearning,
                    moduleCount: course.moduleCount,
                    lessonCount: course.lessonCount,
                    isEnrolled: course.enrolled,
                    progress: course.progress,
                    enrollmentStatus: course.enrollmentStatus,
                    isLoading: isEnrolling,
                    isArchived: course.isArchived,
                  ),
                  const SizedBox(height: 16),

                  // Deadline info
                  if (course.deadlineType != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.timer_outlined, size: 18, color: _deadlineStatusColor),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _deadlineText,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          if (_deadlineStatusLabel.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: _deadlineStatusColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _deadlineStatusLabel,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: _deadlineStatusColor,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Syllabus header
                  Row(
                    children: [
                      const Text(
                        'Nội dung khóa học',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF137FEC).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${course.moduleCount} chương',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF137FEC),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Syllabus
                  if (_modulesWithState.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.library_books_outlined,
                              size: 40, color: Color(0xFFCBD5E1)),
                          SizedBox(height: 8),
                          Text(
                            'Chưa có chương nào',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    SyllabusSection(
                      modules: _modulesWithState,
                      onLessonTap: (moduleIdx, lessonIdx) {
                        debugPrint('Tap lesson $lessonIdx in module $moduleIdx');
                      },
                    ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFF137FEC)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person, color: Colors.white, size: 32),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Nhân viên',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          _buildDrawerItem(
            icon: Icons.home,
            label: 'Trang chủ',
            isActive: false,
            onTap: () {
              Navigator.pop(context);
              onNavigate('/employee/dashboard');
            },
          ),
          _buildDrawerItem(
            icon: Icons.library_books,
            label: 'Khóa học của tôi',
            isActive: false,
            onTap: () => Navigator.pop(context),
          ),
          _buildDrawerItem(
            icon: Icons.grid_view,
            label: 'Danh mục',
            isActive: true,
            onTap: () {
              Navigator.pop(context);
              onNavigate('/employee/courses');
            },
          ),
          _buildDrawerItem(
            icon: Icons.settings,
            label: 'Cài đặt',
            isActive: false,
            onTap: () => Navigator.pop(context),
          ),
          const Divider(),
          _buildDrawerItem(
            icon: Icons.logout,
            label: 'Đăng xuất',
            isActive: false,
            onTap: () {
              Navigator.pop(context);
              onLogout();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isActive ? const Color(0xFF137FEC) : const Color(0xFF64748B),
      ),
      title: Text(
        label,
        style: TextStyle(
          color: isActive ? const Color(0xFF137FEC) : const Color(0xFF0F172A),
          fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      onTap: onTap,
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      selectedItemColor: const Color(0xFF137FEC),
      unselectedItemColor: const Color(0xFF64748B),
      selectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      unselectedLabelStyle: const TextStyle(fontSize: 12),
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Trang chủ'),
        BottomNavigationBarItem(icon: Icon(Icons.library_books), label: 'Khóa học'),
        BottomNavigationBarItem(icon: Icon(Icons.grid_view), label: 'Danh mục'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Cá nhân'),
      ],
    );
  }
}

class _MobileStatChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MobileStatChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF137FEC)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }
}
