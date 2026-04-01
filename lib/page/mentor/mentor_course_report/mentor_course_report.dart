import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'mentor_course_report_web.dart';
import 'mentor_course_report_mobile.dart';

/// Mentor Course Report - Base Responsive Wrapper
class MentorCourseReport extends StatelessWidget {
  const MentorCourseReport({super.key});

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return const MentorCourseReportWeb();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 900) {
          return const MentorCourseReportWeb();
        }
        return const MentorCourseReportMobile();
      },
    );
  }
}
