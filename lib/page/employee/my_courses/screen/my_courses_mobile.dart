import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smet/page/employee/my_courses/widgets/enrolled_course_card.dart';
import 'package:smet/page/employee/my_courses/widgets/filter_tabs.dart';
import 'package:smet/service/employee/lms_service.dart';

class MyCoursesMobile extends StatelessWidget {
  final List<EnrolledCourse> courses;
  final List<EnrolledCourse> allCourses;
  final bool isLoading;
  final String? error;
  final CourseFilter selectedFilter;
  final ValueChanged<CourseFilter> onFilterChanged;
  final VoidCallback onRetry;
  final Function(String) onCourseTap;
  final VoidCallback onLogout;
  final Function(String) onNavigate;
  final int currentPage;
  final int totalPages;
  final int totalElements;
  final bool isPaging;
  final ValueChanged<int> onPageChanged;

  const MyCoursesMobile({
    super.key,
    required this.courses,
    required this.allCourses,
    required this.isLoading,
    this.error,
    required this.selectedFilter,
    required this.onFilterChanged,
    required this.onRetry,
    required this.onCourseTap,
    required this.onLogout,
    required this.onNavigate,
    required this.currentPage,
    required this.totalPages,
    required this.totalElements,
    required this.isPaging,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 64,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF137FEC),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.school, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            const Text(
              'SMETS',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF137FEC),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.notifications_outlined,
              color: Color(0xFF64748B),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF137FEC).withValues(alpha: 0.2),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF137FEC), width: 2),
              ),
              child: const Icon(
                Icons.person,
                color: Color(0xFF137FEC),
                size: 18,
              ),
            ),
          ),
        ],
      ),
      drawer: _buildDrawer(context),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF137FEC)),
      );
    }

    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Color(0xFFEF4444),
              ),
              const SizedBox(height: 16),
              Text(
                error!,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF64748B),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF137FEC),
                ),
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    if (allCourses.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.school_outlined,
                size: 64,
                color: Color(0xFFE5E7EB),
              ),
              const SizedBox(height: 16),
              const Text(
                'Chưa có khóa học nào',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Hãy đăng ký khóa học để bắt đầu học tập',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF94A3B8),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => onNavigate('/employee/courses'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF137FEC),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.explore),
                label: const Text('Khám phá khóa học'),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats
          _MobileStatsSection(
            courses: allCourses,
            totalCountOverride: totalElements > 0 ? totalElements : null,
          ),
          const SizedBox(height: 16),

          // Filter tabs
          SizedBox(
            width: double.infinity,
            child: FilterTabs(
              selected: selectedFilter,
              onChanged: onFilterChanged,
            ),
          ),
          const SizedBox(height: 16),

          // Course list
          if (courses.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Column(
                  children: [
                    Icon(
                      Icons.search_off,
                      size: 48,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Không có khóa học nào trong mục này',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            Stack(
              alignment: Alignment.center,
              children: [
                Opacity(
                  opacity: isPaging ? 0.45 : 1,
                  child: Column(
                    children: courses
                        .map(
                          (course) => Builder(
                            builder: (ctx) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: SizedBox(
                                height: 280,
                                child: EnrolledCourseCard(
                                  course: course,
                                  onTap: () => onCourseTap(course.id),
                                  onViewCertificate: course.certificateAvailable
                                      ? () => ctx.go('/employee/certificates?courseId=${course.id}')
                                      : null,
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                if (isPaging)
                  const SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF137FEC),
                    ),
                  ),
              ],
            ),
            _MobilePaginationBar(
              currentPage: currentPage,
              totalPages: totalPages,
              totalElements: totalElements,
              isPaging: isPaging,
              onPageChanged: onPageChanged,
            ),
          ],
        ],
      ),
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
                  child: const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 32,
                  ),
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
                Text(
                  'Nhân viên',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          _buildDrawerItem(
            icon: Icons.dashboard,
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
            isActive: true,
            onTap: () => Navigator.pop(context),
          ),
          _buildDrawerItem(
            icon: Icons.explore,
            label: 'Danh mục',
            isActive: false,
            onTap: () {
              Navigator.pop(context);
              onNavigate('/employee/courses');
            },
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

  Widget _buildBottomNav(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      selectedItemColor: const Color(0xFF137FEC),
      unselectedItemColor: const Color(0xFF64748B),
      selectedLabelStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: const TextStyle(fontSize: 12),
      currentIndex: 1,
      onTap: (index) {
        switch (index) {
          case 0:
            onNavigate('/employee/dashboard');
            break;
          case 2:
            onNavigate('/employee/courses');
            break;
          case 3:
            break;
        }
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Trang chủ'),
        BottomNavigationBarItem(
          icon: Icon(Icons.library_books),
          label: 'Khóa học',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.grid_view),
          label: 'Danh mục',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Cá nhân'),
      ],
    );
  }
}

class _MobilePaginationBar extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final int totalElements;
  final bool isPaging;
  final ValueChanged<int> onPageChanged;

  const _MobilePaginationBar({
    required this.currentPage,
    required this.totalPages,
    required this.totalElements,
    required this.isPaging,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF137FEC);
    final tp = totalPages <= 0 ? 1 : totalPages;
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: !isPaging && currentPage > 0
                    ? () => onPageChanged(currentPage - 1)
                    : null,
                icon: const Icon(Icons.chevron_left),
                color: const Color(0xFF64748B),
              ),
              Opacity(
                opacity: isPaging ? 0.5 : 1,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                    tp > 5 ? 5 : tp,
                    (index) {
                      int pageNum;
                      if (tp > 5) {
                        if (currentPage < 3) {
                          pageNum = index;
                        } else if (currentPage > tp - 3) {
                          pageNum = tp - 5 + index;
                        } else {
                          pageNum = currentPage - 2 + index;
                        }
                      } else {
                        pageNum = index;
                      }
                      final isCurrent = pageNum == currentPage;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: InkWell(
                          onTap: isPaging ? null : () => onPageChanged(pageNum),
                          borderRadius: BorderRadius.circular(4),
                          child: Container(
                            width: 32,
                            height: 32,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isCurrent ? primary : Colors.transparent,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${pageNum + 1}',
                              style: TextStyle(
                                color: isCurrent ? Colors.white : const Color(0xFF64748B),
                                fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              IconButton(
                onPressed: !isPaging && currentPage < tp - 1
                    ? () => onPageChanged(currentPage + 1)
                    : null,
                icon: const Icon(Icons.chevron_right),
                color: const Color(0xFF64748B),
              ),
            ],
          ),
          Text(
            'Trang ${currentPage + 1}/$tp · $totalElements khóa học',
            style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }
}

class _MobileStatsSection extends StatelessWidget {
  final List<EnrolledCourse> courses;
  final int? totalCountOverride;

  const _MobileStatsSection({
    required this.courses,
    this.totalCountOverride,
  });

  @override
  Widget build(BuildContext context) {
    final total = totalCountOverride ?? courses.length;
    final inProgress = courses
        .where((c) => c.status == EnrollmentStatus.inProgress)
        .length;
    final completed = courses
        .where((c) => c.status == EnrollmentStatus.completed)
        .length;
    final overdue = courses
        .where((c) => c.deadlineStatus == DeadlineStatus.overdue)
        .length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _MiniStat(
                label: 'Tổng',
                value: total,
                color: const Color(0xFF137FEC),
              ),
              const SizedBox(width: 12),
              _MiniStat(
                label: 'Đang học',
                value: inProgress,
                color: const Color(0xFFF59E0B),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _MiniStat(
                label: 'Hoàn thành',
                value: completed,
                color: const Color(0xFF22C55E),
              ),
              const SizedBox(width: 12),
              _MiniStat(
                label: 'Quá hạn',
                value: overdue,
                color: const Color(0xFFEF4444),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              '$label: ',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
