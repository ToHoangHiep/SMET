import 'package:flutter/material.dart';
import 'package:smet/page/employee/quiz/screen/quiz_page.dart';

class QuizWebPage extends StatelessWidget {
  final String quizId;

  const QuizWebPage({super.key, required this.quizId});

  @override
  Widget build(BuildContext context) {
    return QuizPage(quizId: quizId);
  }
}
