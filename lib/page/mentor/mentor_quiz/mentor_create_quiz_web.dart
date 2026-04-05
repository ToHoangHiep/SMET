import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smet/page/shared/widgets/shared_breadcrumb.dart';
import 'package:smet/model/learning_path_model.dart';
import 'package:smet/model/option_model.dart';
import 'package:smet/model/question_model.dart';
import 'package:smet/model/quiz_model.dart';
import 'package:smet/service/mentor/option_service.dart';
import 'package:smet/service/mentor/question_service.dart';
import 'package:smet/service/mentor/quiz_service.dart';
import 'package:smet/service/common/global_notification_service.dart';

class MentorCreateQuizWeb extends StatefulWidget {
  final String? moduleId;
  final String? courseId;
  final bool isFinalQuiz;
  /** Nếu truyền quizId → chế độ sửa quiz đã tồn tại. */
  final String? quizId;
  /** Gọi sau khi lưu thành công, trước khi quay lại trang khóa học. */
  final VoidCallback? onSaved;

  const MentorCreateQuizWeb({
    super.key,
    this.moduleId,
    this.courseId,
    this.isFinalQuiz = false,
    this.quizId,
    this.onSaved,
  });

  @override
  State<MentorCreateQuizWeb> createState() => _MentorCreateQuizWebState();
}

class _MentorCreateQuizWebState extends State<MentorCreateQuizWeb> {
  final _formKey = GlobalKey<FormState>();

  final MentorQuizService _quizService = MentorQuizService();
  final MentorQuestionService _questionService = MentorQuestionService();
  final MentorOptionService _optionService = MentorOptionService();

  bool get _isEditMode => widget.quizId != null;

  final _titleController = TextEditingController();
  final _durationController = TextEditingController(text: '45');
  final _passingScoreController = TextEditingController(text: '80');
  final _maxAttemptsController = TextEditingController(text: '1');

  bool _showAnswer = false;
  bool _isSaving = false;
  bool _isLoading = true;
  String? _loadError;

  final List<_EditableQuestion> _questions = [];

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      _loadExistingQuiz();
    } else {
      _addQuestion();
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadExistingQuiz() async {
    try {
      final quiz = await _quizService.getQuizWithQuestions(
        Long(int.parse(widget.quizId!)),
      );

      _titleController.text = quiz.title;
      _durationController.text = quiz.timeLimitMinutes.toString();
      _passingScoreController.text = quiz.passingScore.toString();
      _maxAttemptsController.text = (quiz.maxAttempts ?? 1).toString();
      _showAnswer = quiz.showAnswer;

      if (quiz.questions != null) {
        for (final q in quiz.questions!) {
          final editable = _EditableQuestion();
          editable.questionController.text = q.content;
          editable.questionId = q.id;

          // _EditableQuestion() đã tạo sẵn 4 ô trống; khi sửa quiz phải thay bằng đáp án từ API,
          // không được add thêm → tránh 8 ô (4 placeholder + 4 thật).
          if (q.options != null && q.options!.isNotEmpty) {
            for (final c in editable.optionControllers) {
              c.dispose();
            }
            editable.optionControllers.clear();
            editable.correctAnswers.clear();
            editable.optionIds.clear();
            for (final o in q.options!) {
              editable.optionControllers.add(
                TextEditingController(text: o.content),
              );
              editable.correctAnswers.add(o.isCorrect);
              editable.optionIds.add(o.id);
            }
            while (editable.optionControllers.length < 2) {
              editable.optionControllers.add(TextEditingController());
              editable.correctAnswers.add(false);
              editable.optionIds.add(null);
            }
          }

          _questions.add(editable);
        }
      }

      if (_questions.isEmpty) {
        _addQuestion();
      }

      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadError = e.toString();
          _isLoading = false;
        });
      }
    }
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
    widget.onSaved?.call();
    // Mở bằng context.go() → stack không có route để pop → phải go() lại chi tiết khóa
    if (widget.courseId != null && widget.courseId!.isNotEmpty) {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/mentor/courses/${widget.courseId}');
      }
      return;
    }
    if (context.canPop()) {
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
      // ── Ghi lại ID gốc từ server trước khi save ──
      final _originalQuestionIds = <Long>{};
      for (final eq in _questions) {
        if (eq.questionId != null) _originalQuestionIds.add(eq.questionId!);
      }

      if (_isEditMode) {
        // ── EDIT MODE: cập nhật metadata quiz ──
        final updatedQuiz = QuizModel(
          title: _titleController.text.trim(),
          timeLimitMinutes: int.tryParse(_durationController.text.trim()) ?? 0,
          passingScore: int.tryParse(_passingScoreController.text.trim()) ?? 0,
          maxAttempts: int.tryParse(_maxAttemptsController.text.trim()),
          questionCount: _questions.length,
          showAnswer: _showAnswer,
          isFinalQuiz: widget.isFinalQuiz,
          moduleId:
              widget.moduleId != null
                  ? Long(int.parse(widget.moduleId!))
                  : null,
          courseId:
              widget.courseId != null
                  ? Long(int.parse(widget.courseId!))
                  : null,
        );

        await _quizService.updateQuiz(
          Long(int.parse(widget.quizId!)),
          updatedQuiz,
        );

        // ── Cập nhật / tạo / xóa câu hỏi & đáp án ──
        final _stillUsedQuestionIds = <Long>{};

        for (int i = 0; i < _questions.length; i++) {
          final item = _questions[i];
          item.ensureValidState();

          Long questionId;
          if (item.questionId != null) {
            // Câu hỏi đã có → cập nhật
            final updated = await _questionService.updateQuestion(
              item.questionId!,
              QuestionModel(
                quizId: Long(int.parse(widget.quizId!)),
                content: item.questionController.text.trim(),
                type: 'MULTIPLE_CHOICE',
              ),
            );
            questionId = updated.id!;
          } else {
            // Câu hỏi mới → tạo mới
            final created = await _questionService.createQuestion(
              QuestionModel(
                quizId: Long(int.parse(widget.quizId!)),
                content: item.questionController.text.trim(),
                type: 'MULTIPLE_CHOICE',
              ),
            );
            questionId = created.id!;
          }
          _stillUsedQuestionIds.add(questionId);

          for (int j = 0; j < item.optionControllers.length; j++) {
            final optionId = item.optionIds[j];
            final isNewOption = optionId == null;

            if (isNewOption) {
              await _optionService.createOption(
                OptionModel(
                  questionId: questionId,
                  content: item.optionControllers[j].text.trim(),
                  isCorrect: item.correctAnswers[j],
                ),
              );
            } else {
              await _optionService.updateOption(
                optionId,
                OptionModel(
                  questionId: questionId,
                  content: item.optionControllers[j].text.trim(),
                  isCorrect: item.correctAnswers[j],
                ),
              );
            }
          }
        }

        // Xóa câu hỏi đã bị bỏ đi (trong original nhưng không còn trong form)
        for (final qid in _originalQuestionIds) {
          if (!_stillUsedQuestionIds.contains(qid)) {
            try {
              await _questionService.deleteQuestion(qid);
            } catch (_) {}
          }
        }

        if (!mounted) return;
        GlobalNotificationService.show(
          context: context,
          message: 'Cập nhật quiz thành công',
          type: NotificationType.success,
        );
        _goBack();
      } else {
        // ── CREATE MODE: create quiz + questions ──
        final quiz = QuizModel(
          title: _titleController.text.trim(),
          timeLimitMinutes: int.tryParse(_durationController.text.trim()) ?? 0,
          passingScore: int.tryParse(_passingScoreController.text.trim()) ?? 0,
          maxAttempts: int.tryParse(_maxAttemptsController.text.trim()),
          questionCount: _questions.length,
          showAnswer: _showAnswer,
          isFinalQuiz: widget.isFinalQuiz,
          moduleId:
              widget.moduleId != null
                  ? Long(int.parse(widget.moduleId!))
                  : null,
          courseId:
              widget.courseId != null
                  ? Long(int.parse(widget.courseId!))
                  : null,
        );

        dev.log(
          '[MentorCreateQuizWeb._saveQuiz] CREATE payload: moduleId=${widget.moduleId} '
          'courseId=${widget.courseId} isFinalQuiz=${widget.isFinalQuiz} '
          'quiz.moduleId=${quiz.moduleId?.value} quiz.courseId=${quiz.courseId?.value}',
          name: 'QuizDebug',
        );
        final createdQuiz = await _quizService.createQuiz(quiz);
        dev.log(
          '[MentorCreateQuizWeb._saveQuiz] created quiz id=${createdQuiz.id?.value} '
          '(sau khi quay lại trang khóa, GET modules/course phải trả quizId khớp module)',
          name: 'QuizDebug',
        );

        for (int i = 0; i < _questions.length; i++) {
          final item = _questions[i];
          item.ensureValidState();

          dev.log(
            '[MentorCreateQuizWeb._saveQuiz] Creating question $i for quiz id=${createdQuiz.id?.value}',
            name: 'QuizDebug',
          );
          final createdQuestion = await _questionService.createQuestion(
            QuestionModel(
              quizId: createdQuiz.id,
              content: item.questionController.text.trim(),
              type: 'MULTIPLE_CHOICE',
            ),
          );
          dev.log(
            '[MentorCreateQuizWeb._saveQuiz]   question $i created, id=${createdQuestion.id?.value}',
            name: 'QuizDebug',
          );

          for (int j = 0; j < item.optionControllers.length; j++) {
            dev.log(
              '[MentorCreateQuizWeb._saveQuiz]     Creating option $j for question $i',
              name: 'QuizDebug',
            );
            await _optionService.createOption(
              OptionModel(
                questionId: createdQuestion.id,
                content: item.optionControllers[j].text.trim(),
                isCorrect: item.correctAnswers[j],
              ),
            );
            dev.log(
              '[MentorCreateQuizWeb._saveQuiz]     option $j created',
              name: 'QuizDebug',
            );
          }
        }

        // validateQuiz là bước backend kiểm tra quiz đủ câu hỏi.
        // Nếu questionCount (form) != số câu hỏi thực tế → lỗi, nhưng quiz đã lưu rồi.
        // Bọc riêng để user vẫn thấy "Tạo quiz thành công" dù validation fail.
        if (createdQuiz.id != null) {
          dev.log(
            '[MentorCreateQuizWeb._saveQuiz] Calling validateQuiz(id=${createdQuiz.id?.value})',
            name: 'QuizDebug',
          );
          try {
            await _quizService.validateQuiz(createdQuiz.id!);
            dev.log(
              '[MentorCreateQuizWeb._saveQuiz] validateQuiz OK',
              name: 'QuizDebug',
            );
          } catch (e) {
            dev.log(
              '[MentorCreateQuizWeb._saveQuiz] validateQuiz FAILED (quiz+questions đã lưu OK): $e',
              name: 'QuizDebug',
            );
            if (!mounted) return;
            GlobalNotificationService.show(
              context: context,
              message: 'Quiz đã lưu nhưng chưa validate: $e',
              type: NotificationType.warning,
            );
          }
        }

        if (!mounted) return;
        GlobalNotificationService.show(
          context: context,
          message: 'Tạo quiz thành công',
          type: NotificationType.success,
        );

        _goBack();
      }
    } catch (e) {
      _showError('Lưu quiz thất bại: $e');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showError(String message) {
    GlobalNotificationService.show(
      context: context,
      message: message,
      type: NotificationType.error,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_loadError != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(_loadError!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _goBack, child: const Text('Quay lại')),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xfff5f6fa),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(30, 30, 30, 0),
            child: BreadcrumbPageHeader(
              pageTitle:
                  _isEditMode
                      ? 'Sửa Quiz'
                      : (widget.isFinalQuiz ? 'Tạo Final Quiz' : 'Tạo Quiz'),
              pageIcon: Icons.quiz_rounded,
              breadcrumbs: [
                const BreadcrumbItem(
                  label: 'Khóa học',
                  route: '/mentor/courses',
                ),
                if (widget.courseId != null && widget.courseId!.isNotEmpty)
                  BreadcrumbItem(
                    label: 'Chi tiết khóa',
                    route: '/mentor/courses/${widget.courseId}',
                  ),
                BreadcrumbItem(
                  label:
                      _isEditMode
                          ? 'Sửa quiz'
                          : (widget.isFinalQuiz ? 'Final Quiz' : 'Quiz module'),
                ),
              ],
              primaryColor: const Color(0xFF6366F1),
              actions: [
                TextButton(
                  onPressed: _isSaving ? null : _goBack,
                  child: const Text('Hủy'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isSaving ? null : _saveQuiz,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                  ),
                  child:
                      _isSaving
                          ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : Text(_isEditMode ? 'Lưu thay đổi' : 'Lưu'),
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
                    Expanded(flex: 1, child: _buildSettingCard()),
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
      action:
          _questions.length > 1
              ? TextButton.icon(
                onPressed: () => _removeQuestion(index),
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                label: const Text('Xóa', style: TextStyle(color: Colors.red)),
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
                    value:
                        optionIndex < question.correctAnswers.length
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
                    onPressed:
                        question.optionControllers.length <= 2
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
  /** ID gốc từ server (null = câu hỏi mới thêm lúc sửa quiz). */
  Long? questionId;
  /** ID gốc của mỗi đáp án (null = đáp án mới thêm). */
  final List<Long?> optionIds = [];

  final TextEditingController questionController = TextEditingController();
  final List<TextEditingController> optionControllers = List.generate(
    4,
    (_) => TextEditingController(),
  );

  final List<bool> correctAnswers = List.generate(4, (_) => false);

  void addOption() {
    optionControllers.add(TextEditingController());
    correctAnswers.add(false);
    optionIds.add(null);
  }

  void removeOption(int index) {
    if (optionControllers.length <= 2) return;
    optionControllers[index].dispose();
    optionControllers.removeAt(index);
    correctAnswers.removeAt(index);
    optionIds.removeAt(index);
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
