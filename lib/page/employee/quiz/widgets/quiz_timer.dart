import 'dart:async';
import 'package:flutter/material.dart';
import 'package:smet/page/employee/quiz/widgets/quiz_exam_theme.dart';

class QuizTimer extends StatefulWidget {
  final int totalSeconds;
  final VoidCallback onTimeUp;

  const QuizTimer({
    super.key,
    required this.totalSeconds,
    required this.onTimeUp,
  });

  @override
  State<QuizTimer> createState() => _QuizTimerState();
}

class _QuizTimerState extends State<QuizTimer> {
  late int _remainingSeconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.totalSeconds;
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        _timer?.cancel();
        widget.onTimeUp();
      }
    });
  }

  String get formattedTime {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  bool get isLowTime => _remainingSeconds <= 60;

  Color get _iconColor => isLowTime ? QuizExamTheme.error : QuizExamTheme.primary;
  Color get _textColor => isLowTime ? QuizExamTheme.error : QuizExamTheme.primary;
  Color get _containerBg => isLowTime
      ? QuizExamTheme.errorContainer.withValues(alpha: 0.3)
      : QuizExamTheme.primaryFixed.withValues(alpha: 0.4);
  Color get _containerBorder => isLowTime
      ? QuizExamTheme.error.withValues(alpha: 0.4)
      : QuizExamTheme.primary.withValues(alpha: 0.3);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: _containerBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _containerBorder, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer_outlined,
            size: 18,
            color: _iconColor,
          ),
          const SizedBox(width: 6),
          Text(
            formattedTime,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _textColor,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
