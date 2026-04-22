import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smet/model/Employee_course_model.dart';
import 'package:smet/service/employee/course_service.dart';
import 'package:smet/page/admin/course_preview/admin_course_preview_web.dart';
import 'package:smet/page/shared/widgets/shared_breadcrumb.dart';

class AdminCoursePreviewPage extends StatefulWidget {
  final String courseId;

  const AdminCoursePreviewPage({super.key, required this.courseId});

  @override
  State<AdminCoursePreviewPage> createState() => _AdminCoursePreviewPageState();
}

class _AdminCoursePreviewPageState extends State<AdminCoursePreviewPage> {
  CourseDetail? _course;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final course = await CourseService.getCourseDetail(widget.courseId);
      if (!mounted) return;
      setState(() {
        _course = course;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Không thể tải thông tin khóa học';
        _isLoading = false;
      });
    }
  }

  List<BreadcrumbItem> _breadcrumbs() {
    return [
      BreadcrumbItem(label: 'Trang chủ', onTap: () => context.go('/home')),
      BreadcrumbItem(label: 'Danh sách phòng ban', onTap: () => context.go('/department_management')),
      BreadcrumbItem(label: _course?.title ?? 'Chi tiết khóa học'),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FC),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF6366F1)),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(_error!, style: TextStyle(color: Colors.red[600])),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    final course = _course!;
    final breadcrumbs = _breadcrumbs();

    return AdminCoursePreviewWeb(
      course: course,
      breadcrumbs: breadcrumbs,
      onBack: () => context.go('/department_management'),
    );
  }
}
