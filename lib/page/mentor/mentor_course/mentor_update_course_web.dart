import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smet/page/mentor/mentor_course/mentor_course_detail_web.dart';

/// Mentor Update Course - Web Layout
/// Wrapper trỏ tới MentorCourseDetailWeb với edit mode
class MentorUpdateCourseWeb extends StatelessWidget {
  final String? courseId;
  final String? title;

  const MentorUpdateCourseWeb({
    super.key,
    this.courseId,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    // Nếu có courseId → dùng MentorCourseDetailWeb (đã có full API)
    // Nếu không → hiện trang tạo mới
    if (courseId != null && courseId!.isNotEmpty) {
      return MentorCourseDetailWeb(courseId: courseId);
    }

    // Fallback: trang tạo mới
    return _buildCreateFallback(context);
  }

  Widget _buildCreateFallback(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f6fa),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            const Text("Không tìm thấy khóa học", style: TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/mentor/courses'),
              child: const Text("Quay lại danh sách"),
            ),
          ],
        ),
      ),
    );
  }
}
