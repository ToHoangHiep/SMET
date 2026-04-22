import 'package:flutter/material.dart';
import 'package:smet/page/employee/quiz/widgets/quiz_exam_theme.dart';

class QuizOptionItem extends StatefulWidget {
  final String optionId;
  final String content;
  final bool isSelected;
  final bool isCorrect;
  final bool showResult;
  final QuestionDisplayMode mode;
  final int optionIndex;
  final VoidCallback onTap;

  const QuizOptionItem({
    super.key,
    required this.optionId,
    required this.content,
    required this.isSelected,
    this.isCorrect = false,
    this.showResult = false,
    required this.mode,
    required this.optionIndex,
    required this.onTap,
  });

  @override
  State<QuizOptionItem> createState() => _QuizOptionItemState();
}

class _QuizOptionItemState extends State<QuizOptionItem> {
  bool _isHovered = false;

  Color get _backgroundColor {
    if (widget.showResult) {
      if (widget.isCorrect) {
        return QuizExamTheme.correctGreen.withValues(alpha: 0.12);
      } else if (widget.isSelected && !widget.isCorrect) {
        return QuizExamTheme.wrongRed.withValues(alpha: 0.08);
      }
      return QuizExamTheme.surfaceContainerLowest;
    }
    if (widget.isSelected) {
      return QuizExamTheme.primaryFixed;
    }
    if (_isHovered) {
      return QuizExamTheme.surfaceContainerLow;
    }
    return QuizExamTheme.surfaceContainerLowest;
  }

  Color get _borderColor {
    if (widget.showResult) {
      if (widget.isCorrect) return QuizExamTheme.correctGreen;
      if (widget.isSelected && !widget.isCorrect) return QuizExamTheme.wrongRed;
      return QuizExamTheme.outlineVariant.withValues(alpha: 0.15);
    }
    if (widget.isSelected) return QuizExamTheme.primary;
    if (_isHovered) return QuizExamTheme.primary.withValues(alpha: 0.3);
    return QuizExamTheme.outlineVariant.withValues(alpha: 0.15);
  }

  Color get _textColor {
    if (widget.showResult) {
      if (widget.isCorrect) return QuizExamTheme.correctGreen;
      if (widget.isSelected && !widget.isCorrect) return QuizExamTheme.wrongRed;
      return QuizExamTheme.onSurface;
    }
    if (widget.isSelected) return QuizExamTheme.primary;
    if (_isHovered) return QuizExamTheme.primary;
    return QuizExamTheme.onSurface;
  }

  Color get _labelBgColor {
    if (widget.showResult) {
      if (widget.isCorrect) return QuizExamTheme.correctGreen;
      if (widget.isSelected && !widget.isCorrect) return QuizExamTheme.wrongRed;
      return QuizExamTheme.surfaceContainerHighest;
    }
    if (widget.isSelected) return QuizExamTheme.primary;
    return QuizExamTheme.surfaceContainerHighest;
  }

  Color get _labelTextColor {
    if (widget.showResult && (widget.isCorrect || (widget.isSelected && !widget.isCorrect))) {
      return QuizExamTheme.onError;
    }
    if (widget.isSelected) return QuizExamTheme.onPrimary;
    return QuizExamTheme.onSurfaceVariant;
  }

  IconData? get _trailingIcon {
    if (!widget.showResult) return null;
    if (widget.isCorrect) return Icons.check_circle;
    if (widget.isSelected && !widget.isCorrect) return Icons.cancel;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isHovered = true),
        onTapUp: (_) => setState(() => _isHovered = false),
        onTapCancel: () => setState(() => _isHovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: _backgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _borderColor,
              width: widget.isSelected ? 1.5 : 1,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.showResult ? null : widget.onTap,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    _buildLabel(),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        widget.content,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: _textColor,
                          height: 1.4,
                        ),
                      ),
                    ),
                    if (_trailingIcon != null) ...[
                      const SizedBox(width: 8),
                      Icon(
                        _trailingIcon,
                        color: _borderColor,
                        size: 22,
                      ),
                    ] else ...[
                      const SizedBox(width: 22),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: _labelBgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          String.fromCharCode(65 + widget.optionIndex),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: _labelTextColor,
          ),
        ),
      ),
    );
  }
}
