import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'employee_live_session_web.dart';
import 'employee_live_session_mobile.dart';

/// Học viên / employee — màn buổi học trực tuyến (layout giống mentor).
/// [courseId] tùy chọn từ query để chọn sẵn khóa học (deep link).
class EmployeeLiveSession extends StatelessWidget {
  const EmployeeLiveSession({super.key, this.courseId});

  final String? courseId;

  @override
  Widget build(BuildContext context) {
    final isWebOrDesktop = kIsWeb ||
        MediaQuery.of(context).size.width >= 768 ||
        !Platform.isAndroid && !Platform.isIOS;

    if (isWebOrDesktop) {
      return EmployeeLiveSessionWeb(initialCourseId: courseId);
    }
    return EmployeeLiveSessionMobile(initialCourseId: courseId);
  }
}
