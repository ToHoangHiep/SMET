import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'mentor_course_report_detail_web.dart';
import 'mentor_course_report_detail_mobile.dart';

/// Mentor Course Report Detail - Base Responsive Wrapper
class MentorCourseReportDetail extends StatelessWidget {
  const MentorCourseReportDetail({super.key});

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return const MentorCourseReportDetailWeb();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 900) {
          return const MentorCourseReportDetailWeb();
        }
        return const MentorCourseReportDetailMobile();
      },
    );
  }
}
