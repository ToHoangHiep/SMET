import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Chat Input Widget - Ô nhập tin nhắn
class ChatInput extends StatefulWidget {
  final Function(String) onSend;
  final bool isLoading;
  final Color primaryColor;
  final String hintText;

  const ChatInput({
    super.key,
    required this.onSend,
    this.isLoading = false,
    this.primaryColor = const Color(0xFF137FEC),
    this.hintText = 'Nhập tin nhắn...',
  });

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _hasText = false;

  // Colors
  static const _bgInput = Color(0xFFF8FAFC);
  static const _border = Color(0xFFE5E7EB);
  static const _borderFocus = Color(0xFF137FEC);
  static const _textDark = Color(0xFF0F172A);
  static const _textMuted = Color(0xFF94A3B8);
  static const _sendBg = Color(0xFF137FEC);

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = _controller.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() {
        _hasText = hasText;
      });
    }
  }

  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isEmpty || widget.isLoading) return;

    widget.onSend(text);
    _controller.clear();
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: _border, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Text input field
            Expanded(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 120),
                decoration: BoxDecoration(
                  color: _bgInput,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: _focusNode.hasFocus ? _borderFocus : _border,
                    width: 1,
                  ),
                ),
                child: KeyboardListener(
                  focusNode: FocusNode(),
                  onKeyEvent: (event) {
                    if (event is KeyDownEvent &&
                        event.logicalKey == LogicalKeyboardKey.enter &&
                        !HardwareKeyboard.instance.isShiftPressed) {
                      _handleSend();
                    }
                  },
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    maxLines: null,
                    textInputAction: TextInputAction.newline,
                    style: const TextStyle(
                      fontSize: 15,
                      color: _textDark,
                    ),
                    decoration: InputDecoration(
                      hintText: widget.hintText,
                      hintStyle: const TextStyle(
                        fontSize: 15,
                        color: _textMuted,
                      ),
                      contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Send button
            _buildSendButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildSendButton() {
    if (widget.isLoading) {
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: widget.primaryColor.withValues(alpha: 0.5),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          ),
        ),
      );
    }

    return Material(
      color: _hasText ? widget.primaryColor : _border,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: _hasText ? _handleSend : null,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.send_rounded,
            color: _hasText ? Colors.white : _textMuted,
            size: 22,
          ),
        ),
      ),
    );
  }
}
