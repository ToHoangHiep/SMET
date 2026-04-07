import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'mentor_quiz_review_mobile.dart';
import 'mentor_quiz_review_web.dart';

/// Mentor Quiz Review - Base Responsive Wrapper
/// Endpoint: GET /api/mentor/course-review/{courseId}
class MentorQuizReview extends StatelessWidget {
  const MentorQuizReview({super.key});

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return const MentorQuizReviewWeb();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 900) {
          return const MentorQuizReviewWeb();
        }
        return const MentorQuizReviewMobile();
      },
    );
  }
}
