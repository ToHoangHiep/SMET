import 'package:flutter/material.dart';
import 'package:smet/page/employee/quiz/screen/quiz_page.dart';

class QuizMobilePage extends StatelessWidget {
  final String quizId;

  const QuizMobilePage({super.key, required this.quizId});

  @override
  Widget build(BuildContext context) {
    return QuizPage(quizId: quizId);
  }
}
