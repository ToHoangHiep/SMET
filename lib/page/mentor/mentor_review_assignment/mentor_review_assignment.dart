import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'mentor_review_assignment_mobile.dart';
import 'mentor_review_assignment_web.dart';

/// Mentor Review Assignment - Base Responsive Wrapper
class MentorReviewAssignment extends StatelessWidget {
  const MentorReviewAssignment({super.key});

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return const MentorReviewAssignmentWeb();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 900) {
          return const MentorReviewAssignmentWeb();
        }
        return const MentorReviewAssignmentMobile();
      },
    );
  }
}
