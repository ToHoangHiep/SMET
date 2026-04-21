class Quiz {
  final String id;
  final String lessonId;
  final String title;
  final String? description;
  final int timeLimitMinutes;
  final int passingScore;
  final List<QuizQuestion> questions;

  Quiz({
    required this.id,
    required this.lessonId,
    required this.title,
    this.description,
    required this.timeLimitMinutes,
    required this.passingScore,
    required this.questions,
  });

  factory Quiz.fromJson(Map<String, dynamic> json) {
    return Quiz(
      id: json['id'] ?? '',
      lessonId: json['lessonId'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      timeLimitMinutes: json['timeLimitMinutes'] ?? 10,
      passingScore: json['passingScore'] ?? 70,
      questions: (json['questions'] as List<dynamic>?)
              ?.map((q) => QuizQuestion.fromJson(q))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'lessonId': lessonId,
      'title': title,
      'description': description,
      'timeLimitMinutes': timeLimitMinutes,
      'passingScore': passingScore,
      'questions': questions.map((q) => q.toJson()).toList(),
    };
  }
}

enum QuestionType {
  single,
  multiple,
  trueFalse,
}

class QuizQuestion {
  final String id;
  final String content;
  final QuestionType type;
  final List<QuizOption> options;
  final int point;

  QuizQuestion({
    required this.id,
    required this.content,
    required this.type,
    required this.options,
    this.point = 1,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      id: json['id'] ?? '',
      content: json['content'] ?? '',
      type: QuestionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => QuestionType.single,
      ),
      options: (json['options'] as List<dynamic>?)
              ?.map((o) => QuizOption.fromJson(o))
              .toList() ??
          [],
      point: json['point'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'type': type.name,
      'options': options.map((o) => o.toJson()).toList(),
      'point': point,
    };
  }
}

class QuizOption {
  final String id;
  final String content;
  final bool isCorrect;

  QuizOption({
    required this.id,
    required this.content,
    required this.isCorrect,
  });

  factory QuizOption.fromJson(Map<String, dynamic> json) {
    return QuizOption(
      id: json['id'] ?? '',
      content: json['content'] ?? '',
      isCorrect: json['isCorrect'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'isCorrect': isCorrect,
    };
  }
}

class QuizAnswer {
  final String questionId;
  final List<String> selectedOptionIds;

  QuizAnswer({
    required this.questionId,
    required this.selectedOptionIds,
  });

  Map<String, dynamic> toJson() {
    return {
      'questionId': questionId,
      'selectedOptionIds': selectedOptionIds,
    };
  }
}

class QuizResult {
  final String quizId;
  final int totalScore;
  final int maxScore;
  final double percentage;
  final bool passed;
  final int correctCount;
  final int totalQuestions;
  final Duration timeSpent;
  final List<QuestionResult> questionResults;

  QuizResult({
    required this.quizId,
    required this.totalScore,
    required this.maxScore,
    double? percentage,
    required this.passed,
    required this.correctCount,
    required this.totalQuestions,
    required this.timeSpent,
    required this.questionResults,
  }) : percentage = percentage ?? (maxScore > 0 ? (totalScore / maxScore) * 100 : 0);
}

class QuestionResult {
  final String questionId;
  final bool isCorrect;
  final List<String> selectedOptionIds;
  final List<String> correctOptionIds;

  QuestionResult({
    required this.questionId,
    required this.isCorrect,
    required this.selectedOptionIds,
    required this.correctOptionIds,
  });
}
