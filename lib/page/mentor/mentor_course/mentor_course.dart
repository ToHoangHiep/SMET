import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'mentor_course_mobile.dart';
import 'mentor_course_web.dart';

class MentorCourse extends StatelessWidget {
  const MentorCourse({super.key});

  @override
  Widget build(BuildContext context) {

    if (kIsWeb) {
      return const MentorCourseWeb();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 900) {
          return const MentorCourseWeb();
        }
        return const MentorCourseMobile();
      },
    );
  }
}