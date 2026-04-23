import 'package:smet/model/option_model.dart';
import 'package:smet/model/question_model.dart';

/// Format dữ liệu quiz sau khi parse từ CSV.
class ParsedQuizData {
  final String title;
  final int timeLimitMinutes;
  final int passingScore;
  final int maxAttempts;
  final bool showAnswer;
  final List<ParsedQuestion> questions;
  final List<String> errors;

  ParsedQuizData({
    required this.title,
    required this.timeLimitMinutes,
    required this.passingScore,
    required this.maxAttempts,
    required this.showAnswer,
    required this.questions,
    this.errors = const [],
  });

  bool get hasErrors => errors.isNotEmpty;
  int get questionCount => questions.length;
  int get totalOptions => questions.fold(0, (sum, q) => sum + q.options.length);
  int get totalCorrect => questions.fold(0, (sum, q) => sum + q.options.where((o) => o.isCorrect).length);

  String toDebugString() {
    final buf = StringBuffer();
    buf.writeln('=== ParsedQuizData ===');
    buf.writeln('title: $title');
    buf.writeln('timeLimitMinutes: $timeLimitMinutes');
    buf.writeln('passingScore: $passingScore');
    buf.writeln('maxAttempts: $maxAttempts');
    buf.writeln('showAnswer: $showAnswer');
    buf.writeln('questions: ${questions.length}');
    for (int i = 0; i < questions.length; i++) {
      buf.writeln('  Q${i + 1}: ${questions[i].content}');
      buf.writeln('    type: ${questions[i].type}');
      for (int j = 0; j < questions[i].options.length; j++) {
        final o = questions[i].options[j];
        buf.writeln('    ${String.fromCharCode(65 + j)}) ${o.content} [${o.isCorrect ? 'CORRECT' : 'wrong'}]');
      }
    }
    if (errors.isNotEmpty) {
      buf.writeln('ERRORS:');
      for (final e in errors) {
        buf.writeln('  - $e');
      }
    }
    return buf.toString();
  }
}

class ParsedQuestion {
  final String content;
  final String type;
  final List<ParsedOption> options;
  final List<String> rowErrors;

  ParsedQuestion({
    required this.content,
    required this.type,
    required this.options,
    this.rowErrors = const [],
  });

  bool get hasErrors => rowErrors.isNotEmpty;

  QuestionModel toModel() {
    return QuestionModel(
      content: content.trim(),
      type: type,
      options: options.map((o) => o.toModel()).toList(),
    );
  }
}

class ParsedOption {
  final String content;
  final bool isCorrect;

  ParsedOption({required this.content, required this.isCorrect});

  OptionModel toModel() {
    return OptionModel(
      content: content.trim(),
      isCorrect: isCorrect,
    );
  }
}

/// CSV format quy ước:
///
/// Dòng 1 (metadata): quiz_title,time_limit_minutes,passing_score,max_attempts,show_answer
/// Dòng 2 (header câu hỏi): question_content,question_type,option_a,option_b,option_c,option_d,correct_option
///
/// - question_type: SINGLE_CHOICE | MULTIPLE_CHOICE | TRUE_FALSE
/// - correct_option: A, B, C, D cho SINGLE_CHOICE / TRUE_FALSE
///                  A,B,C hoặc A,C cho MULTIPLE_CHOICE (nhiều đáp án)
/// - TRUE_FALSE: option_a = "Dung", option_b = "Sai", correct_option = A hoặc B
///
/// Dòng trống hoặc dòng bắt đầu bằng # được bỏ qua.
///
/// Ví dụ SINGLE_CHOICE:
///   Flutter là gì?,SINGLE_CHOICE,Một framework mobile,Một ngôn ngữ lập trình,Một hệ điều hành,Một database,A
///
/// Ví dụ MULTIPLE_CHOICE:
///   Các ngôn ngữ nào thuộc nhóm OOP?,MULTIPLE_CHOICE,Dart,Java,C++,HTML,Java,C++
///
/// Ví dụ TRUE_FALSE:
///   Dart là ngôn ngữ lập trình,TRUE_FALSE,Dung,Sai,A
class QuizCsvParser {
  static const String _sep = ',';

  ParsedQuizData parse(String csvContent) {
    final errors = <String>[];
    final lines = _splitLines(csvContent);

    if (lines.isEmpty) {
      errors.add('File CSV trống');
      return ParsedQuizData(
        title: '',
        timeLimitMinutes: 45,
        passingScore: 80,
        maxAttempts: 1,
        showAnswer: false,
        questions: [],
        errors: errors,
      );
    }

    // Parse dòng 1: quiz metadata
    String quizTitle = 'Quiz từ file';
    int timeLimitMinutes = 45;
    int passingScore = 80;
    int maxAttempts = 1;
    bool showAnswer = false;

    final metaLine = lines[0].trim();
    if (metaLine.isNotEmpty && !metaLine.startsWith('#')) {
      final metaParts = _parseLine(metaLine);
      if (metaParts.isNotEmpty && metaParts[0].isNotEmpty) {
        quizTitle = metaParts[0];
      }
      if (metaParts.length > 1) {
        timeLimitMinutes = int.tryParse(metaParts[1].trim()) ?? 45;
      }
      if (metaParts.length > 2) {
        passingScore = int.tryParse(metaParts[2].trim()) ?? 80;
      }
      if (metaParts.length > 3) {
        maxAttempts = int.tryParse(metaParts[3].trim()) ?? 1;
      }
      if (metaParts.length > 4) {
        final sa = metaParts[4].trim().toLowerCase();
        showAnswer = sa == 'true' || sa == '1' || sa == 'yes';
      }
    }

    // Parse các dòng câu hỏi
    final questions = <ParsedQuestion>[];
    for (int i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty || line.startsWith('#')) continue;

      final question = _parseQuestionLine(line, i + 1);
      questions.add(question);
      errors.addAll(question.rowErrors);
    }

    return ParsedQuizData(
      title: quizTitle,
      timeLimitMinutes: timeLimitMinutes,
      passingScore: passingScore,
      maxAttempts: maxAttempts,
      showAnswer: showAnswer,
      questions: questions,
      errors: errors,
    );
  }

  List<String> _splitLines(String content) {
    final lines = content.split(RegExp(r'\r?\n'));
    return lines;
  }

  List<String> _parseLine(String line) {
    final result = <String>[];
    var current = StringBuffer();
    var inQuotes = false;

    for (var i = 0; i < line.length; i++) {
      final c = line[i];
      if (c == '"') {
        inQuotes = !inQuotes;
      } else if (c == _sep && !inQuotes) {
        result.add(current.toString());
        current = StringBuffer();
      } else {
        current.write(c);
      }
    }
    result.add(current.toString());
    return result;
  }

  ParsedQuestion _parseQuestionLine(String line, int lineNumber) {
    final errors = <String>[];
    final parts = _parseLine(line);

    if (parts.isEmpty) {
      errors.add('Dòng $lineNumber: Dòng trống');
      return ParsedQuestion(
        content: '',
        type: 'SINGLE_CHOICE',
        options: [],
        rowErrors: errors,
      );
    }

    final content = parts.isNotEmpty ? parts[0].trim() : '';
    if (content.isEmpty) {
      errors.add('Dòng $lineNumber: Câu hỏi trống');
    }

    final typeRaw = parts.length > 1 ? parts[1].trim().toUpperCase() : 'SINGLE_CHOICE';
    final type = _normalizeQuestionType(typeRaw);

    final options = <ParsedOption>[];
    final optionA = parts.length > 2 ? parts[2].trim() : '';
    final optionB = parts.length > 3 ? parts[3].trim() : '';
    final optionC = parts.length > 4 ? parts[4].trim() : '';
    final optionD = parts.length > 5 ? parts[5].trim() : '';
    final correctRaw = parts.length > 6 ? parts[6].trim().toUpperCase() : '';

    if (type == 'TRUE_FALSE') {
      options.add(ParsedOption(
        content: optionA.isEmpty ? 'Dung' : optionA,
        isCorrect: correctRaw == 'A',
      ));
      options.add(ParsedOption(
        content: optionB.isEmpty ? 'Sai' : optionB,
        isCorrect: correctRaw == 'B',
      ));
    } else {
      if (optionA.isEmpty) errors.add('Dòng $lineNumber: Đáp án A trống');
      if (optionB.isEmpty) errors.add('Dòng $lineNumber: Đáp án B trống');

      final correctIndices = _parseCorrectIndices(correctRaw, type);
      options.add(ParsedOption(content: optionA, isCorrect: correctIndices.contains(0)));
      options.add(ParsedOption(content: optionB, isCorrect: correctIndices.contains(1)));

      if (optionC.isNotEmpty) {
        options.add(ParsedOption(content: optionC, isCorrect: correctIndices.contains(2)));
      }
      if (optionD.isNotEmpty) {
        options.add(ParsedOption(content: optionD, isCorrect: correctIndices.contains(3)));
      }
    }

    if (type == 'SINGLE_CHOICE' || type == 'TRUE_FALSE') {
      if (options.where((o) => o.isCorrect).length != 1) {
        errors.add('Dòng $lineNumber: Phải có đúng 1 đáp án đúng');
      }
    } else {
      if (options.where((o) => o.isCorrect).isEmpty) {
        errors.add('Dòng $lineNumber: Phải có ít nhất 1 đáp án đúng');
      }
    }

    return ParsedQuestion(
      content: content,
      type: type,
      options: options,
      rowErrors: errors,
    );
  }

  String _normalizeQuestionType(String raw) {
    switch (raw) {
      case 'SINGLE':
      case 'SINGLE_CHOICE':
      case 'RADIO':
        return 'SINGLE_CHOICE';
      case 'MULTIPLE':
      case 'MULTIPLE_CHOICE':
      case 'CHECKBOX':
        return 'MULTIPLE_CHOICE';
      case 'TRUEFALSE':
      case 'TRUE_FALSE':
      case 'TF':
        return 'TRUE_FALSE';
      default:
        return 'SINGLE_CHOICE';
    }
  }

  Set<int> _parseCorrectIndices(String raw, String questionType) {
    final result = <int>{};
    if (raw.isEmpty) return result;

    if (questionType == 'MULTIPLE_CHOICE') {
      for (final char in raw.split(',')) {
        final trimmed = char.trim();
        if (trimmed.isEmpty) continue;
        final idx = trimmed.codeUnitAt(0) - 'A'.codeUnitAt(0);
        if (idx >= 0 && idx <= 3) result.add(idx);
      }
    } else {
      final trimmed = raw.trim();
      if (trimmed.isNotEmpty) {
        final idx = trimmed.codeUnitAt(0) - 'A'.codeUnitAt(0);
        if (idx >= 0 && idx <= 3) result.add(idx);
      }
    }
    return result;
  }

  String generateTemplateCsv() {
    return '''# Dong nay chua thong tin quiz. Bo trong dong nay neu khong can thiet.
quiz_title,time_limit_minutes,passing_score,max_attempts,show_answer
Quiz Moi,45,80,1,false

# Cac dong bat dau bang # la dong chu thich, se duoc bo qua.
# question_content,question_type,option_a,option_b,option_c,option_d,correct_option
# Vi du SINGLE_CHOICE (1 dap an dung):
Flutter la gi?,SINGLE_CHOICE,Mot framework mobile,Mot ngon ngu lap trinh,Mot he dieu hanh,Mot database,A
# Vi du MULTIPLE_CHOICE (nhieu dap an dung):
Cac ngon ngu nao thuoc OOP?,MULTIPLE_CHOICE,Dart,Java,C++,HTML,A,B
# Vi du TRUE_FALSE:
Dart la ngon ngu lap trinh,TRUE_FALSE,Dung,Sai,A
''';
  }
}
