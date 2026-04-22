import 'package:smet/model/learning_path_model.dart';

class OptionModel {
  final Long? id;
  final Long? questionId;
  final String content;
  final bool isCorrect;

  OptionModel({
    this.id,
    this.questionId,
    required this.content,
    required this.isCorrect,
  });

  factory OptionModel.fromJson(Map<String, dynamic> json) {
    return OptionModel(
      id: json['id'] != null ? Long(json['id']) : null,
      questionId: json['questionId'] != null ? Long(json['questionId']) : null,
      content: json['content'] ?? '',
      isCorrect: json['isCorrect'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id!.value,
      if (questionId != null) 'questionId': questionId!.value,
      'content': content,
      'isCorrect': isCorrect,
    };
  }
}