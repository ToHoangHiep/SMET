import 'package:smet/model/learning_path_model.dart';
import 'package:smet/model/question_model.dart';

class QuizModel {
  final Long? id;
  final String title;
  final int timeLimitMinutes;
  final int passingScore;
  final int? maxAttempts;
  final int? questionCount;
  final bool showAnswer;
  final bool isFinalQuiz;
  final Long? courseId;
  final Long? moduleId;
  final List<QuestionModel>? questions;
  final int? totalQuestions;

  QuizModel({
    this.id,
    required this.title,
    required this.timeLimitMinutes,
    required this.passingScore,
    this.maxAttempts,
    this.questionCount,
    required this.showAnswer,
    required this.isFinalQuiz,
    this.courseId,
    this.moduleId,
    this.questions,
    this.totalQuestions,
  });

  factory QuizModel.fromJson(Map<String, dynamic> json) {
    return QuizModel(
      id: json['id'] != null ? Long(json['id']) : null,
      title: json['title'] ?? '',
      timeLimitMinutes:
          json['time_limit_minutes'] ?? json['timeLimitMinutes'] ?? 0,
      passingScore: json['passing_score'] ?? json['passingScore'] ?? 0,
      maxAttempts: json['max_attempts'] ?? json['maxAttempts'],
      questionCount: json['question_count'] ?? json['questionCount'],
      showAnswer: json['show_answer'] ?? json['showAnswer'] ?? false,
      isFinalQuiz: json['is_final_quiz'] ?? json['isFinalQuiz'] ?? false,
      courseId:
          json['course_id'] != null
              ? Long(json['course_id'])
              : (json['courseId'] != null ? Long(json['courseId']) : null),
      moduleId:
          json['module_id'] != null
              ? Long(json['module_id'])
              : (json['moduleId'] != null ? Long(json['moduleId']) : null),
      questions:
          json['questions'] != null
              ? (json['questions'] as List)
                  .map((q) => QuestionModel.fromJson(q))
                  .toList()
              : null,
      totalQuestions: json['totalQuestions'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id!.value,
      'title': title,
      'timeLimitMinutes': timeLimitMinutes,
      'passingScore': passingScore,
      'maxAttempts': maxAttempts,
      'questionCount': questionCount,
      'showAnswer': showAnswer,
      'isFinalQuiz': isFinalQuiz,
      if (moduleId != null) 'moduleId': moduleId!.value,
      if (courseId != null) 'courseId': courseId!.value,
    };
  }
}
