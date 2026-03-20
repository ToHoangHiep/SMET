import 'package:flutter/material.dart';
import 'mentor_create_course_mobile.dart';
import 'mentor_create_course_web.dart';

class MentorCreateCourse extends StatelessWidget {
  const MentorCreateCourse({super.key});

  @override
  Widget build(BuildContext context) {

    final width = MediaQuery.of(context).size.width;

    if (width < 900) {
      return const MentorCreateCourseMobile();
    } else {
      return const MentorCreateCourseWeb();
    }
  }
}