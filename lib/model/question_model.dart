import 'package:smet/model/learning_path_model.dart';
import 'package:smet/model/option_model.dart';

class QuestionModel {
  final Long? id;
  final String content;
  final Long? lessonId;
  final String? type;
  final Long? quizId;
  final List<OptionModel>? options;

  QuestionModel({
    this.id,
    required this.content,
    this.lessonId,
    this.type,
    this.quizId,
    this.options,
  });

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    return QuestionModel(
      id: json['id'] != null ? Long(json['id']) : null,
      content: json['content'] ?? '',
      lessonId: json['lessonId'] != null
          ? Long(json['lessonId'])
          : (json['lesson_id'] != null ? Long(json['lesson_id']) : null),
      type: json['type'],
      quizId: json['quizId'] != null
          ? Long(json['quizId'])
          : (json['quiz_id'] != null ? Long(json['quiz_id']) : null),
      options: json['options'] != null
          ? (json['options'] as List)
              .map((o) => OptionModel.fromJson(o))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id!.value,
      'content': content,
      if (lessonId != null) 'lessonId': lessonId!.value,
      if (type != null) 'type': type,
      if (quizId != null) 'quizId': quizId!.value,
    };
  }
}