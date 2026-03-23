import 'package:flutter/material.dart';
import 'package:smet/page/employee/quiz/screen/quiz_page.dart';

class QuizMobilePage extends StatelessWidget {
  final String lessonId;

  const QuizMobilePage({super.key, required this.lessonId});

  @override
  Widget build(BuildContext context) {
    return QuizPage(lessonId: lessonId);
  }
}
