import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smet/model/learning_path_model.dart';
import 'package:smet/model/option_model.dart';
import 'package:smet/model/question_model.dart';
import 'package:smet/model/quiz_model.dart';
import 'package:smet/service/mentor/option_service.dart';
import 'package:smet/service/mentor/question_service.dart';
import 'package:smet/service/mentor/quiz_service.dart';

class MentorCreateQuizWeb extends StatefulWidget {
  final String? moduleId;
  final String? courseId;
  final bool isFinalQuiz;

  const MentorCreateQuizWeb({
    super.key,
    this.moduleId,
    this.courseId,
    this.isFinalQuiz = false,
  });

  @override
  State<MentorCreateQuizWeb> createState() => _MentorCreateQuizWebState();
}

class _MentorCreateQuizWebState extends State<MentorCreateQuizWeb> {
  final _formKey = GlobalKey<FormState>();

  final MentorQuizService _quizService = MentorQuizService();
  final MentorQuestionService _questionService = MentorQuestionService();
  final MentorOptionService _optionService = MentorOptionService();

  final _titleController = TextEditingController();
  final _durationController = TextEditingController(text: '45');
  final _passingScoreController = TextEditingController(text: '80');
  final _maxAttemptsController = TextEditingController(text: '1');

  bool _showAnswer = false;
  bool _isSaving = false;

  final List<_EditableQuestion> _questions = [];

  @override
  void initState() {
    super.initState();
    _addQuestion();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _durationController.dispose();
    _passingScoreController.dispose();
    _maxAttemptsController.dispose();

    for (final q in _questions) {
      q.dispose();
    }
    super.dispose();
  }

  void _goBack() {
    final router = GoRouter.of(context);
    if (router.canPop()) {
      context.pop();
    } else {
      context.go('/mentor/courses');
    }
  }

  void _addQuestion() {
    setState(() {
      _questions.add(_EditableQuestion());
    });
  }

  void _removeQuestion(int index) {
    if (_questions.length == 1) return;

    setState(() {
      _questions[index].dispose();
      _questions.removeAt(index);
    });
  }

  Future<void> _saveQuiz() async {
    if (!_formKey.currentState!.validate()) return;

    for (int i = 0; i < _questions.length; i++) {
      final q = _questions[i];
      q.ensureValidState();

      if (q.questionController.text.trim().isEmpty) {
        _showError('Câu hỏi ${i + 1} chưa có nội dung');
        return;
      }

      if (q.optionControllers.length < 2) {
        _showError('Câu hỏi ${i + 1} phải có ít nhất 2 đáp án');
        return;
      }

      for (int j = 0; j < q.optionControllers.length; j++) {
        if (q.optionControllers[j].text.trim().isEmpty) {
          _showError('Câu hỏi ${i + 1} còn đáp án trống');
          return;
        }
      }

      final hasCorrectAnswer = q.correctAnswers.any((e) => e);
      if (!hasCorrectAnswer) {
        _showError('Câu hỏi ${i + 1} phải có ít nhất 1 đáp án đúng');
        return;
      }
    }

    setState(() => _isSaving = true);

    try {
      final quiz = QuizModel(
        title: _titleController.text.trim(),
        timeLimitMinutes: int.tryParse(_durationController.text.trim()) ?? 0,
        passingScore: int.tryParse(_passingScoreController.text.trim()) ?? 0,
        maxAttempts: int.tryParse(_maxAttemptsController.text.trim()),
        questionCount: _questions.length,
        showAnswer: _showAnswer,
        isFinalQuiz: widget.isFinalQuiz,
        moduleId:
            widget.moduleId != null ? Long(int.parse(widget.moduleId!)) : null,
        courseId:
            widget.courseId != null ? Long(int.parse(widget.courseId!)) : null,
      );

      final createdQuiz = await _quizService.createQuiz(quiz);

      for (int i = 0; i < _questions.length; i++) {
        final item = _questions[i];
        item.ensureValidState();

        final createdQuestion = await _questionService.createQuestion(
          QuestionModel(
            quizId: createdQuiz.id,
            content: item.questionController.text.trim(),
            type: 'MULTIPLE_CHOICE',
          ),
        );

        for (int j = 0; j < item.optionControllers.length; j++) {
          await _optionService.createOption(
            OptionModel(
              questionId: createdQuestion.id,
              content: item.optionControllers[j].text.trim(),
              isCorrect: item.correctAnswers[j],
            ),
          );
        }
      }

      if (createdQuiz.id != null) {
        await _quizService.validateQuiz(createdQuiz.id!);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tạo quiz thành công'),
          backgroundColor: Colors.green,
        ),
      );

      _goBack();
    } catch (e) {
      _showError('Lưu quiz thất bại: $e');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f6fa),
      body: Column(
        children: [
          Container(
            height: 70,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            color: Colors.white,
            child: Row(
              children: [
                IconButton(
                  onPressed: _goBack,
                  icon: const Icon(Icons.arrow_back),
                ),
                const SizedBox(width: 8),
                Text(
                  widget.isFinalQuiz ? 'Tạo Final Quiz' : 'Tạo Quiz',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _isSaving ? null : _goBack,
                  child: const Text('Hủy'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isSaving ? null : _saveQuiz,
                  child: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Lưu'),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        children: [
                          _buildGeneralCard(),
                          const SizedBox(height: 24),
                          ...List.generate(
                            _questions.length,
                            (index) => Padding(
                              padding: const EdgeInsets.only(bottom: 24),
                              child: _buildQuestionCard(index),
                            ),
                          ),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _addQuestion,
                              icon: const Icon(Icons.add),
                              label: const Text('Thêm câu hỏi'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      flex: 1,
                      child: _buildSettingCard(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGeneralCard() {
    return _buildCard(
      title: 'Thông tin chung',
      child: Column(
        children: [
          TextFormField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Tên bài thi',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Vui lòng nhập tên bài thi';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _durationController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Thời gian (phút)',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Nhập thời gian';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _passingScoreController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Điểm đạt (%)',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Nhập điểm đạt';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(int index) {
    final question = _questions[index];
    question.ensureValidState();

    return _buildCard(
      title: 'Câu hỏi ${index + 1}',
      action: _questions.length > 1
          ? TextButton.icon(
              onPressed: () => _removeQuestion(index),
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              label: const Text(
                'Xóa',
                style: TextStyle(color: Colors.red),
              ),
            )
          : null,
      child: Column(
        children: [
          TextFormField(
            controller: question.questionController,
            decoration: const InputDecoration(
              labelText: 'Nội dung câu hỏi',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          ...List.generate(question.optionControllers.length, (optionIndex) {
            final optionLabel = String.fromCharCode(65 + optionIndex);

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Checkbox(
                    value: optionIndex < question.correctAnswers.length
                        ? question.correctAnswers[optionIndex]
                        : false,
                    onChanged: (value) {
                      setState(() {
                        question.ensureValidState();
                        if (optionIndex < question.correctAnswers.length) {
                          question.correctAnswers[optionIndex] = value ?? false;
                        }
                      });
                    },
                  ),
                  SizedBox(
                    width: 24,
                    child: Text(
                      optionLabel,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: question.optionControllers[optionIndex],
                      decoration: InputDecoration(
                        labelText: 'Đáp án $optionLabel',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Xóa đáp án',
                    onPressed: question.optionControllers.length <= 2
                        ? null
                        : () {
                            setState(() {
                              question.removeOption(optionIndex);
                            });
                          },
                    icon: const Icon(Icons.close, size: 18),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  question.addOption();
                });
              },
              icon: const Icon(Icons.add),
              label: const Text('Thêm đáp án'),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Có thể chọn nhiều đáp án đúng.',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingCard() {
    return _buildCard(
      title: 'Cài đặt',
      child: Column(
        children: [
          TextFormField(
            controller: _maxAttemptsController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Giới hạn số lần làm',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Nhập số lần làm';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Hiển thị đáp án'),
            value: _showAnswer,
            onChanged: (value) {
              setState(() => _showAnswer = value);
            },
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xfff8f9fc),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Số câu hỏi: ${_questions.length}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required Widget child,
    Widget? action,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (action != null) action,
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _EditableQuestion {
  final TextEditingController questionController = TextEditingController();
  final List<TextEditingController> optionControllers = List.generate(
    4,
    (_) => TextEditingController(),
  );

  final List<bool> correctAnswers = List.generate(4, (_) => false);

  void addOption() {
    optionControllers.add(TextEditingController());
    correctAnswers.add(false);
  }

  void removeOption(int index) {
    if (optionControllers.length <= 2) return;
    optionControllers[index].dispose();
    optionControllers.removeAt(index);
    correctAnswers.removeAt(index);
  }

  void ensureValidState() {
    while (correctAnswers.length < optionControllers.length) {
      correctAnswers.add(false);
    }
    while (correctAnswers.length > optionControllers.length) {
      correctAnswers.removeLast();
    }
  }

  void dispose() {
    questionController.dispose();
    for (final controller in optionControllers) {
      controller.dispose();
    }
  }
}