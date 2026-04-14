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
  final String? quizId;
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

class _MentorCreateQuizWebState extends State<MentorCreateQuizWeb>
    with SingleTickerProviderStateMixin {
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
  bool? _quizIsFinal;

  final List<_EditableQuestion> _questions = [];

  static const _primaryColor = Color(0xFF6366F1);
  static const _secondaryColor = Color(0xFF8B5CF6);
  static const _accentColor = Color(0xFF06B6D4);
  static const _successColor = Color(0xFF10B981);
  static const _errorColor = Color(0xFFEF4444);
  static const _bgColor = Color(0xFFF1F5F9);
  static const _cardBg = Color(0xFFFFFFFF);
  static const _textPrimary = Color(0xFF1E293B);
  static const _textSecondary = Color(0xFF64748B);

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
      _quizIsFinal = quiz.isFinalQuiz;

      if (quiz.questions != null) {
        for (final q in quiz.questions!) {
          final editable = _EditableQuestion();
          editable.questionController.text = q.content;
          editable.questionId = q.id;

          for (final c in editable.optionControllers) {
            c.dispose();
          }
          editable.optionControllers.clear();
          editable.correctAnswers.clear();
          editable.optionIds.clear();

          if (q.options != null) {
            for (final o in q.options!) {
              editable.optionControllers.add(
                TextEditingController(text: o.content),
              );
              editable.correctAnswers.add(o.isCorrect);
              editable.optionIds.add(o.id);
            }
          }

          while (editable.optionControllers.length < 2) {
            editable.optionControllers.add(TextEditingController());
            editable.correctAnswers.add(false);
            editable.optionIds.add(null);
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
    dev.log('[MentorCreateQuizWeb._goBack] START courseId=${widget.courseId}', name: 'QuizDebug');
    try {
      widget.onSaved?.call();
      if (widget.courseId != null && widget.courseId!.isNotEmpty) {
        dev.log('[MentorCreateQuizWeb._goBack] branch: courseId path, canPop=${context.canPop()}', name: 'QuizDebug');
        context.go('/mentor/courses/${widget.courseId}');
        dev.log('[MentorCreateQuizWeb._goBack] after go(courseId)', name: 'QuizDebug');
        return;
      }
      dev.log('[MentorCreateQuizWeb._goBack] branch: default path, canPop=${context.canPop()}', name: 'QuizDebug');
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/mentor/courses');
      }
    } catch (e, st) {
      dev.log('[MentorCreateQuizWeb._goBack] EXCEPTION: $e\n$st', name: 'QuizDebug');
    }
  }

  void _addQuestion() {
    setState(() {
      _questions.add(_EditableQuestion());
    });
  }

  void _removeQuestion(int index) {
    if (_questions.length == 1) return;

    final removed = _questions.removeAt(index);
    removed.dispose();
    setState(() {});
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
      final _originalQuestionIds = <Long>{};
      for (final eq in _questions) {
        if (eq.questionId != null) _originalQuestionIds.add(eq.questionId!);
      }

      if (_isEditMode) {
        final updatedQuiz = QuizModel(
          title: _titleController.text.trim(),
          timeLimitMinutes: int.tryParse(_durationController.text.trim()) ?? 0,
          passingScore: int.tryParse(_passingScoreController.text.trim()) ?? 0,
          maxAttempts: int.tryParse(_maxAttemptsController.text.trim()),
          questionCount: _questions.length,
          showAnswer: _showAnswer,
          isFinalQuiz: _quizIsFinal ?? widget.isFinalQuiz,
          moduleId: widget.moduleId != null && widget.moduleId!.isNotEmpty
              ? Long(int.parse(widget.moduleId!))
              : null,
          courseId: widget.courseId != null
              ? Long(int.parse(widget.courseId!))
              : null,
        );

        await _quizService.updateQuiz(
          Long(int.parse(widget.quizId!)),
          updatedQuiz,
        );

        final _stillUsedQuestionIds = <Long>{};

        for (int i = 0; i < _questions.length; i++) {
          final item = _questions[i];
          item.ensureValidState();

          Long questionId;
          if (item.questionId != null) {
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
        final quiz = QuizModel(
          title: _titleController.text.trim(),
          timeLimitMinutes: int.tryParse(_durationController.text.trim()) ?? 0,
          passingScore: int.tryParse(_passingScoreController.text.trim()) ?? 0,
          maxAttempts: int.tryParse(_maxAttemptsController.text.trim()),
          questionCount: _questions.length,
          showAnswer: _showAnswer,
          isFinalQuiz: _quizIsFinal ?? widget.isFinalQuiz,
          moduleId: widget.moduleId != null && widget.moduleId!.isNotEmpty
              ? Long(int.parse(widget.moduleId!))
              : null,
          courseId: widget.courseId != null
              ? Long(int.parse(widget.courseId!))
              : null,
        );

        dev.log(
          '[MentorCreateQuizWeb._saveQuiz] CREATE payload: '
          'courseId=${widget.courseId} isFinalQuiz=${widget.isFinalQuiz} '
          'quiz.courseId=${quiz.courseId?.value}',
          name: 'QuizDebug',
        );
        final createdQuiz = await _quizService.createQuiz(quiz);
        dev.log(
          '[MentorCreateQuizWeb._saveQuiz] created quiz id=${createdQuiz.id?.value} '
          '(sau khi quay lại trang khóa, GET modules/course phải trả quizId khớp module)',
          name: 'QuizDebug',
        );
        if (createdQuiz.id == null) {
          dev.log('[MentorCreateQuizWeb._saveQuiz] WARNING: createdQuiz.id is NULL!', name: 'QuizDebug');
        }

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
              '[MentorCreateQuizWeb._saveQuiz] validateQuiz FAILED: $e',
              name: 'QuizDebug',
            );
            if (mounted) {
              setState(() => _isSaving = false);
            }
            _showError('Quiz không hợp lệ: $e');
            return;
          }
        }

        dev.log('[MentorCreateQuizWeb._saveQuiz] before mounted check: mounted=$mounted', name: 'QuizDebug');

        if (!mounted) {
          dev.log('[MentorCreateQuizWeb._saveQuiz] STOP: mounted=false', name: 'QuizDebug');
          return;
        }
        dev.log('[MentorCreateQuizWeb._saveQuiz] calling GlobalNotificationService.show', name: 'QuizDebug');
        GlobalNotificationService.show(
          context: context,
          message: 'Tạo quiz thành công',
          type: NotificationType.success,
        );
        dev.log('[MentorCreateQuizWeb._saveQuiz] after show, calling _goBack', name: 'QuizDebug');

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
      return Scaffold(
        backgroundColor: _bgColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_primaryColor.withOpacity(0.1), _secondaryColor.withOpacity(0.1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: const CircularProgressIndicator(
                  color: _primaryColor,
                  strokeWidth: 3,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Đang tải dữ liệu...',
                style: TextStyle(
                  color: _textSecondary,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_loadError != null) {
      return Scaffold(
        backgroundColor: _bgColor,
        body: Center(
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: _cardBg,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _errorColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.error_outline, size: 48, color: _errorColor),
                ),
                const SizedBox(height: 16),
                Text(
                  _loadError!,
                  style: const TextStyle(color: _errorColor, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                _buildActionButton(
                  label: 'Quay lại',
                  onPressed: _goBack,
                  isPrimary: false,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _bgColor,
      body: Column(
        children: [
          _buildHeader(),
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
                          _buildAddQuestionButton(),
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

  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.fromLTRB(30, 30, 30, 0),
      child: BreadcrumbPageHeader(
        pageTitle: _isEditMode
            ? (_quizIsFinal == true ? 'Sửa Final Quiz' : 'Sửa Quiz')
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
            label: _isEditMode
                ? (_quizIsFinal == true ? 'Final Quiz' : 'Quiz module')
                : (widget.isFinalQuiz ? 'Final Quiz' : 'Quiz module'),
          ),
        ],
        primaryColor: _primaryColor,
        actions: [
          _buildActionButton(
            label: 'Hủy',
            onPressed: _isSaving ? null : _goBack,
            isPrimary: false,
          ),
          const SizedBox(width: 12),
          _buildActionButton(
            label: _isEditMode ? 'Lưu thay đổi' : 'Lưu',
            onPressed: _isSaving ? null : _saveQuiz,
            isPrimary: true,
            icon: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required VoidCallback? onPressed,
    required bool isPrimary,
    Widget? icon,
  }) {
    if (isPrimary) {
      return Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_primaryColor, _secondaryColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: _primaryColor.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    icon,
                    const SizedBox(width: 8),
                  ] else ...[
                    const Icon(Icons.check_rounded, size: 20, color: Colors.white),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.close_rounded, size: 20, color: _textSecondary),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: _textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGeneralCard() {
    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _primaryColor.withOpacity(0.08),
                  _secondaryColor.withOpacity(0.08),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_primaryColor, _secondaryColor],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.info_outline_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                const Text(
                  'Thông tin chung',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildStyledTextField(
                  controller: _titleController,
                  label: 'Tên bài thi',
                  hint: 'Nhập tên bài thi...',
                  prefixIcon: Icons.title_rounded,
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
                      child: _buildStyledTextField(
                        controller: _durationController,
                        label: 'Thời gian (phút)',
                        hint: '45',
                        prefixIcon: Icons.timer_outlined,
                        keyboardType: TextInputType.number,
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
                      child: _buildStyledTextField(
                        controller: _passingScoreController,
                        label: 'Điểm đạt (%)',
                        hint: '80',
                        prefixIcon: Icons.stars_rounded,
                        keyboardType: TextInputType.number,
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
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(int index) {
    final question = _questions[index];
    question.ensureValidState();

    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _accentColor.withOpacity(0.08),
                  _secondaryColor.withOpacity(0.08),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_accentColor, _secondaryColor],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'Câu hỏi ${index + 1}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _textPrimary,
                    ),
                  ),
                ),
                if (_questions.length > 1)
                  _buildDeleteButton(
                    onPressed: () => _removeQuestion(index),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStyledTextField(
                  controller: question.questionController,
                  label: 'Nội dung câu hỏi',
                  hint: 'Nhập nội dung câu hỏi...',
                  prefixIcon: Icons.help_outline_rounded,
                  maxLines: 3,
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _bgColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.list_alt_rounded,
                            size: 20,
                            color: _textSecondary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Đáp án',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _textSecondary,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            'Chọn đáp án đúng',
                            style: TextStyle(
                              fontSize: 12,
                              color: _textSecondary.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ...List.generate(
                        question.optionControllers.length,
                        (optionIndex) {
                          final optionLabel = String.fromCharCode(65 + optionIndex);
                          final isCorrect = optionIndex < question.correctAnswers.length
                              ? question.correctAnswers[optionIndex]
                              : false;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildOptionRow(
                              question: question,
                              optionIndex: optionIndex,
                              optionLabel: optionLabel,
                              isCorrect: isCorrect,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      _buildAddOptionButton(
                        onPressed: () {
                          setState(() {
                            question.addOption();
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: _successColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _successColor.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.lightbulb_outline_rounded,
                              size: 16,
                              color: _successColor,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Có thể chọn nhiều đáp án đúng',
                              style: TextStyle(
                                fontSize: 12,
                                color: _successColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionRow({
    required _EditableQuestion question,
    required int optionIndex,
    required String optionLabel,
    required bool isCorrect,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildOptionRadio(
          isCorrect: isCorrect,
          onChanged: (value) {
            question.ensureValidState();
            setState(() {
              if (optionIndex < question.correctAnswers.length) {
                question.correctAnswers[optionIndex] = value ?? false;
              }
            });
          },
        ),
        const SizedBox(width: 8),
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isCorrect
                  ? [_successColor, _accentColor]
                  : [_primaryColor, _secondaryColor],
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              optionLabel,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStyledTextField(
            controller: question.optionControllers[optionIndex],
            label: 'Đáp án $optionLabel',
            hint: 'Nhập đáp án...',
            noBorder: true,
          ),
        ),
        const SizedBox(width: 8),
        if (question.optionControllers.length > 2)
          _buildRemoveOptionButton(
            onPressed: () {
              question.removeOption(optionIndex);
              setState(() {});
            },
          ),
      ],
    );
  }

  Widget _buildOptionRadio({
    required bool isCorrect,
    required ValueChanged<bool?> onChanged,
  }) {
    return GestureDetector(
      onTap: () => onChanged(!isCorrect),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          gradient: isCorrect
              ? LinearGradient(
                  colors: [_successColor, _accentColor],
                )
              : null,
          color: isCorrect ? null : Colors.white,
          shape: BoxShape.circle,
          border: Border.all(
            color: isCorrect ? Colors.transparent : Colors.grey.shade300,
            width: 2,
          ),
          boxShadow: isCorrect
              ? [
                  BoxShadow(
                    color: _successColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: isCorrect
            ? const Icon(
                Icons.check_rounded,
                size: 16,
                color: Colors.white,
              )
            : null,
      ),
    );
  }

  Widget _buildRemoveOptionButton({required VoidCallback onPressed}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: _errorColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.close_rounded,
            size: 18,
            color: _errorColor,
          ),
        ),
      ),
    );
  }

  Widget _buildAddOptionButton({required VoidCallback onPressed}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: _primaryColor.withOpacity(0.06),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _primaryColor.withOpacity(0.2),
              style: BorderStyle.solid,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.add_rounded,
                size: 18,
                color: _primaryColor,
              ),
              const SizedBox(width: 6),
              Text(
                'Thêm đáp án',
                style: TextStyle(
                  color: _primaryColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddQuestionButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _primaryColor.withOpacity(0.2),
          width: 2,
          strokeAlign: BorderSide.strokeAlignCenter,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _addQuestion,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _primaryColor.withOpacity(0.1),
                        _secondaryColor.withOpacity(0.1),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.add_rounded,
                    size: 28,
                    color: _primaryColor,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Thêm câu hỏi',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _primaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Bấm để thêm câu hỏi mới vào bài thi',
                  style: TextStyle(
                    fontSize: 12,
                    color: _textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingCard() {
    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _successColor.withOpacity(0.08),
                  _accentColor.withOpacity(0.08),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_successColor, _accentColor],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.settings_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                const Text(
                  'Cài đặt',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStyledTextField(
                  controller: _maxAttemptsController,
                  label: 'Giới hạn số lần làm',
                  hint: '1',
                  prefixIcon: Icons.repeat_rounded,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Nhập số lần làm';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                _buildToggleSetting(),
                const SizedBox(height: 20),
                _buildStatsCard(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleSetting() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _showAnswer
                      ? _successColor.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.visibility_rounded,
                  size: 20,
                  color: _showAnswer ? _successColor : Colors.grey,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hiển thị đáp án',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: _textPrimary,
                      ),
                    ),
                    Text(
                      _showAnswer ? 'Đã bật' : 'Đã tắt',
                      style: TextStyle(
                        fontSize: 12,
                        color: _textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              _buildToggleSwitch(
                value: _showAnswer,
                onChanged: (value) {
                  setState(() => _showAnswer = value);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToggleSwitch({
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 52,
        height: 30,
        decoration: BoxDecoration(
          gradient: value
              ? LinearGradient(
                  colors: [_successColor, _accentColor],
                )
              : null,
          color: value ? null : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(15),
          boxShadow: value
              ? [
                  BoxShadow(
                    color: _successColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 250),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 26,
            height: 26,
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _primaryColor.withOpacity(0.08),
            _secondaryColor.withOpacity(0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _primaryColor.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.quiz_rounded,
                size: 20,
                color: _primaryColor,
              ),
              const SizedBox(width: 8),
              Text(
                'Tổng quan',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildStatRow(
            icon: Icons.help_outline_rounded,
            label: 'Số câu hỏi',
            value: '${_questions.length}',
            color: _primaryColor,
          ),
          const SizedBox(height: 12),
          _buildStatRow(
            icon: Icons.list_alt_rounded,
            label: 'Tổng đáp án',
            value: '${_questions.fold<int>(0, (sum, q) => sum + q.optionControllers.length)}',
            color: _accentColor,
          ),
          const SizedBox(height: 12),
          _buildStatRow(
            icon: Icons.check_circle_outline_rounded,
            label: 'Đáp án đúng',
            value: '${_questions.fold<int>(0, (sum, q) => sum + q.correctAnswers.where((e) => e).length)}',
            color: _successColor,
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: _textSecondary,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStyledTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    IconData? prefixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
    bool noBorder = false,
  }) {
    final effectivePrefixIcon = noBorder ? null : prefixIcon;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          style: const TextStyle(
            fontSize: 14,
            color: _textPrimary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: _textSecondary.withOpacity(0.5),
              fontSize: 14,
            ),
            prefixIcon: effectivePrefixIcon != null
                ? Padding(
                    padding: const EdgeInsets.all(12),
                    child: Icon(
                      effectivePrefixIcon,
                      size: 20,
                      color: _primaryColor,
                    ),
                  )
                : null,
            filled: true,
            fillColor: noBorder ? Colors.white : _bgColor,
            contentPadding: EdgeInsets.symmetric(
              horizontal: noBorder ? 16 : 16,
              vertical: noBorder ? 16 : 14,
            ),
            border: noBorder
                ? OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  )
                : OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.grey.shade200,
                      width: 1.5,
                    ),
                  ),
            enabledBorder: noBorder
                ? OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.grey.shade200,
                      width: 1.5,
                    ),
                  )
                : OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.grey.shade200,
                      width: 1.5,
                    ),
                  ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: _primaryColor,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: _errorColor,
                width: 1.5,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: _errorColor,
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDeleteButton({required VoidCallback onPressed}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: _errorColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.delete_outline_rounded,
                size: 18,
                color: _errorColor,
              ),
              const SizedBox(width: 6),
              Text(
                'Xóa',
                style: TextStyle(
                  color: _errorColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditableQuestion {
  Long? questionId;
  final List<Long?> optionIds = [];

  final TextEditingController questionController = TextEditingController();
  final List<TextEditingController> optionControllers = List.generate(
    4,
    (_) => TextEditingController(),
  );

  final List<bool> correctAnswers = List.generate(4, (_) => false);

  void addOption() {
    ensureValidState();
    optionControllers.add(TextEditingController());
    correctAnswers.add(false);
    optionIds.add(null);
  }

  void removeOption(int index) {
    if (optionControllers.length <= 2) return;
    ensureValidState();
    if (index >= optionControllers.length) return;
    optionControllers[index].dispose();
    optionControllers.removeAt(index);
    if (index < correctAnswers.length) {
      correctAnswers.removeAt(index);
    }
    if (index < optionIds.length) {
      optionIds.removeAt(index);
    }
  }

  void ensureValidState() {
    while (correctAnswers.length < optionControllers.length) {
      correctAnswers.add(false);
    }
    while (correctAnswers.length > optionControllers.length) {
      correctAnswers.removeLast();
    }
    while (optionIds.length < optionControllers.length) {
      optionIds.add(null);
    }
    while (optionIds.length > optionControllers.length) {
      optionIds.removeLast();
    }
  }

  void dispose() {
    questionController.dispose();
    for (final controller in optionControllers) {
      controller.dispose();
    }
  }
}
