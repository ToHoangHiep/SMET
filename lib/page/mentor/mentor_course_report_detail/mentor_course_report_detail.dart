import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'mentor_course_report_detail_web.dart';
import 'mentor_course_report_detail_mobile.dart';

/// Mentor Course Report Detail - Base Responsive Wrapper
class MentorCourseReportDetail extends StatelessWidget {
  final String? courseId;

  const MentorCourseReportDetail({super.key, this.courseId});

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return MentorCourseReportDetailWeb(courseId: courseId);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 900) {
          return MentorCourseReportDetailWeb(courseId: courseId);
        }
        return MentorCourseReportDetailMobile(courseId: courseId);
      },
    );
  }
}
