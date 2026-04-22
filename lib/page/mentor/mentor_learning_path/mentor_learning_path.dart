import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'mentor_learning_path_web.dart';
import 'mentor_learning_path_mobile.dart';

/// Mentor Learning Path - Base Responsive Wrapper
class MentorLearningPath extends StatelessWidget {
  const MentorLearningPath({super.key});

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return const MentorLearningPathWeb();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 900) {
          return const MentorLearningPathWeb();
        }
        return const MentorLearningPathMobile();
      },
    );
  }
}
