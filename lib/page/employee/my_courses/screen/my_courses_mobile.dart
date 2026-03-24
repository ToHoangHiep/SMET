import 'package:flutter/material.dart';
import 'package:smet/service/employee/lms_service.dart';

class MyCoursesMobile extends StatelessWidget {
  final List<EnrolledCourse> courses;
  final bool isLoading;
  final String? error;
  final VoidCallback onRetry;
  final Function(String) onCourseTap;
  final VoidCallback onLogout;
  final Function(String) onNavigate;

  const MyCoursesMobile({
    super.key,
    required this.courses,
    required this.isLoading,
    this.error,
    required this.onRetry,
    required this.onCourseTap,
    required this.onLogout,
    required this.onNavigate,
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
      bottomNavigationBar: _buildBottomNav(),
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

    if (courses.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.school_outlined,
                size: 64,
                color: Color(0xFFE5E7EB),
              ),
              SizedBox(height: 16),
              Text(
                'Chưa có khóa học nào',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Hãy đăng ký khóa học để bắt đầu học tập',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF94A3B8),
                ),
                textAlign: TextAlign.center,
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
          const Row(
            children: [
              Icon(
                Icons.library_books,
                color: Color(0xFF137FEC),
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Khóa học của tôi',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...courses.map((course) => _buildCourseItem(course)),
        ],
      ),
    );
  }

  Widget _buildCourseItem(EnrolledCourse course) {
    return GestureDetector(
      onTap: () => onCourseTap(course.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                    image: course.imageUrl != null
                        ? DecorationImage(
                            image: NetworkImage(course.imageUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: course.imageUrl == null
                      ? const Icon(
                          Icons.school,
                          color: Color(0xFFCBD5E1),
                          size: 28,
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        course.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: course.progressPercent / 100,
                                backgroundColor: const Color(0xFFE2E8F0),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  course.progressPercent >= 100
                                      ? const Color(0xFF22C55E)
                                      : const Color(0xFF137FEC),
                                ),
                                minHeight: 6,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${course.progressPercent.toInt()}%',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: course.progressPercent >= 100
                                  ? const Color(0xFF22C55E)
                                  : const Color(0xFF137FEC),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => onCourseTap(course.id),
                style: ElevatedButton.styleFrom(
                  backgroundColor: course.progressPercent >= 100
                      ? const Color(0xFF22C55E)
                      : const Color(0xFF137FEC),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  course.progressPercent >= 100
                      ? 'Hoàn thành'
                      : course.progressPercent > 0
                          ? 'Tiếp tục học'
                          : 'Bắt đầu học',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
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
          _buildDrawerItem(
            icon: Icons.work,
            label: 'Dự án của tôi',
            isActive: false,
            onTap: () => Navigator.pop(context),
          ),
          _buildDrawerItem(
            icon: Icons.workspace_premium,
            label: 'Chứng chỉ của tôi',
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
      selectedLabelStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: const TextStyle(fontSize: 12),
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Trang chủ'),
        BottomNavigationBarItem(
          icon: Icon(Icons.library_books),
          label: 'Khóa học',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.grid_view), label: 'Danh mục'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Cá nhân'),
      ],
    );
  }
}
