import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smet/page/mentor/mentor_course/mentor_course_detail_mobile.dart';

/// Mentor Update Course - Mobile Layout
/// Wrapper trỏ tới MentorCourseDetailMobile với edit mode
class MentorUpdateCourseMobile extends StatelessWidget {
  final String? courseId;

  const MentorUpdateCourseMobile({super.key, this.courseId});

  @override
  Widget build(BuildContext context) {
    // Nếu có courseId → dùng MentorCourseDetailMobile (đã có full API)
    if (courseId != null && courseId!.isNotEmpty) {
      return MentorCourseDetailMobile(courseId: courseId);
    }

    // Fallback
    return Scaffold(
      backgroundColor: const Color(0xfff5f6fa),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.go('/mentor/courses'),
        ),
        title: const Text(
          "Lỗi",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
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
