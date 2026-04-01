import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'mentor_students_web.dart';
import 'mentor_students_mobile.dart';

/// Mentor Students - Base Responsive Wrapper
class MentorStudents extends StatelessWidget {
  const MentorStudents({super.key});

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return const MentorStudentsWeb();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 900) {
          return const MentorStudentsWeb();
        }
        return const MentorStudentsMobile();
      },
    );
  }
}
