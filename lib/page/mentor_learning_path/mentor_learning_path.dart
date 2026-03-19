import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'mentor_learning_path_mobile.dart';
import 'mentor_learning_path_web.dart';

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
