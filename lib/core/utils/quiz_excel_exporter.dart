import 'package:excel/excel.dart';
import 'package:smet/core/utils/quiz_csv_parser.dart';

/// Chuyển ParsedQuizData sang Excel theo format mà backend QuizService.importQuizFromExcel đọc.
///
/// Format Excel (sheet đầu tiên):
///   Row 0: header bị bỏ qua (backend đọc từ row 1 trở đi)
///   Row N: content | type | optionA | optionB | optionC | optionD | correct
///
/// Backend QuizService đọc:
///   col 0: content (câu hỏi)
///   col 1: type (SINGLE_CHOICE | MULTIPLE_CHOICE | TRUE_FALSE)
///   col 2-5: 4 đáp án
///   col 6: đáp án đúng (A, B, C, D)
class QuizExcelExporter {
  /// Chuyển ParsedQuizData sang bytes Excel (.xlsx).
  static List<int> exportToExcel(ParsedQuizData data) {
    final excel = Excel.createExcel();

    // Xóa sheet mặc định "Sheet1" nếu có, tạo sheet mới
    final sheet = excel['Quiz'];

    // Header row (backend bỏ qua, chỉ đọc từ row 1)
    sheet.appendRow([
      TextCellValue('question_content'),
      TextCellValue('question_type'),
      TextCellValue('option_a'),
      TextCellValue('option_b'),
      TextCellValue('option_c'),
      TextCellValue('option_d'),
      TextCellValue('correct_option'),
    ]);

    for (final q in data.questions) {
      String correctOption = '';

      if (q.type == 'TRUE_FALSE') {
        correctOption = _findCorrectIndex(q.options);
      } else {
        correctOption = _buildCorrectOption(q.options);
      }

      sheet.appendRow([
        TextCellValue(q.content),
        TextCellValue(q.type),
        TextCellValue(_optionOrEmpty(q.options, 0)),
        TextCellValue(_optionOrEmpty(q.options, 1)),
        TextCellValue(_optionOrEmpty(q.options, 2)),
        TextCellValue(_optionOrEmpty(q.options, 3)),
        TextCellValue(correctOption),
      ]);
    }

    final bytes = excel.encode();
    if (bytes == null) {
      throw Exception('Không thể tạo file Excel');
    }
    return bytes;
  }

  static String _optionOrEmpty(List<ParsedOption> options, int index) {
    if (index < options.length) {
      return options[index].content;
    }
    return '';
  }

  static String _findCorrectIndex(List<ParsedOption> options) {
    for (int i = 0; i < options.length; i++) {
      if (options[i].isCorrect) {
        return String.fromCharCode(65 + i); // A=65
      }
    }
    return '';
  }

  static String _buildCorrectOption(List<ParsedOption> options) {
    final correct = <String>[];
    for (int i = 0; i < options.length; i++) {
      if (options[i].isCorrect) {
        correct.add(String.fromCharCode(65 + i));
      }
    }
    return correct.join(',');
  }
}
