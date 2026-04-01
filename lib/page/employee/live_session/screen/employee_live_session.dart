import 'package:flutter/material.dart';

import 'employee_live_session_web.dart';

/// Học viên / employee — màn buổi học trực tuyến (layout giống mentor).
/// [courseId] tùy chọn từ query để chọn sẵn khóa học (deep link).
class EmployeeLiveSession extends StatelessWidget {
  const EmployeeLiveSession({super.key, this.courseId});

  final String? courseId;

  @override
  Widget build(BuildContext context) {
    return EmployeeLiveSessionWeb(initialCourseId: courseId);
  }
}
