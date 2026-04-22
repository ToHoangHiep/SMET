import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

/// Shared Rich Text Editor widget sử dụng Flutter Quill.
/// Hỗ trợ web và mobile, với toolbar mềm mại.
class RichTextEditorWidget extends StatefulWidget {
  final QuillController? controller;
  final String? initialContent;
  final String hintText;
  final bool readOnly;
  final double? maxHeight;
  final ValueChanged<String>? onContentChanged;
  final Color? primaryColor;

  const RichTextEditorWidget({
    super.key,
    this.controller,
    this.initialContent,
    this.hintText = 'Nhập nội dung...',
    this.readOnly = false,
    this.maxHeight,
    this.onContentChanged,
    this.primaryColor,
  });

  @override
  State<RichTextEditorWidget> createState() => _RichTextEditorWidgetState();
}

class _RichTextEditorWidgetState extends State<RichTextEditorWidget> {
  late QuillController _controller;
  late TextEditingController _plainTextController;

  @override
  void initState() {
    super.initState();
    _plainTextController = TextEditingController();

    if (widget.controller != null) {
      _controller = widget.controller!;
    } else {
      Document doc;
      if (widget.initialContent != null && widget.initialContent!.isNotEmpty) {
        doc = Document()..insert(0, widget.initialContent!);
      } else {
        doc = Document();
      }
      _controller = QuillController(
        document: doc,
        selection: const TextSelection.collapsed(offset: 0),
      );
    }

    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final plainText = _controller.document.toPlainText().trim();
    _plainTextController.text = plainText;
    widget.onContentChanged?.call(plainText);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    if (widget.controller == null) {
      _controller.dispose();
    }
    _plainTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = widget.primaryColor ?? const Color(0xFF6366F1);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        if (!widget.readOnly) _buildToolbar(primary),
        const SizedBox(height: 8),
        Container(
          constraints: BoxConstraints(
            minHeight: widget.maxHeight ?? 120,
            maxHeight: widget.maxHeight ?? 300,
          ),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: widget.readOnly
                ? _buildReadOnlyView(isDark)
                : _buildEditorView(primary, isDark),
          ),
        ),
      ],
    );
  }

  Widget _buildToolbar(Color primary) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Wrap(
        spacing: 2,
        runSpacing: 2,
        children: [
          _toolbarButton(
            icon: Icons.format_bold,
            tooltip: 'Đậm',
            action: () => _toggleStyle(Attribute.bold),
            isActive: _isAttributeActive(Attribute.bold),
            primary: primary,
          ),
          _toolbarButton(
            icon: Icons.format_italic,
            tooltip: 'Nghiêng',
            action: () => _toggleStyle(Attribute.italic),
            isActive: _isAttributeActive(Attribute.italic),
            primary: primary,
          ),
          _toolbarButton(
            icon: Icons.format_underlined,
            tooltip: 'Gạch chân',
            action: () => _toggleStyle(Attribute.underline),
            isActive: _isAttributeActive(Attribute.underline),
            primary: primary,
          ),
          _toolbarButton(
            icon: Icons.format_strikethrough,
            tooltip: 'Gạch ngang',
            action: () => _toggleStyle(Attribute.strikeThrough),
            isActive: _isAttributeActive(Attribute.strikeThrough),
            primary: primary,
          ),
          const VerticalDivider(width: 12, indent: 6, endIndent: 6),
          _toolbarButton(
            icon: Icons.format_list_bulleted,
            tooltip: 'Danh sách gạch đầu dòng',
            action: () => _toggleStyle(Attribute.ul),
            isActive: _isAttributeActive(Attribute.ul),
            primary: primary,
          ),
          _toolbarButton(
            icon: Icons.format_list_numbered,
            tooltip: 'Danh sách số',
            action: () => _toggleStyle(Attribute.ol),
            isActive: _isAttributeActive(Attribute.ol),
            primary: primary,
          ),
          const VerticalDivider(width: 12, indent: 6, endIndent: 6),
          _toolbarButton(
            icon: Icons.format_quote,
            tooltip: 'Trích dẫn',
            action: () => _toggleStyle(Attribute.blockQuote),
            isActive: _isAttributeActive(Attribute.blockQuote),
            primary: primary,
          ),
          _toolbarButton(
            icon: Icons.code,
            tooltip: 'Mã',
            action: () => _toggleStyle(Attribute.codeBlock),
            isActive: _isAttributeActive(Attribute.codeBlock),
            primary: primary,
          ),
          const VerticalDivider(width: 12, indent: 6, endIndent: 6),
          _toolbarButton(
            icon: Icons.undo,
            tooltip: 'Hoàn tác',
            action: _controller.undo,
            isActive: false,
            primary: primary,
          ),
          _toolbarButton(
            icon: Icons.redo,
            tooltip: 'Làm lại',
            action: _controller.redo,
            isActive: false,
            primary: primary,
          ),
        ],
      ),
    );
  }

  Widget _toolbarButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback action,
    required bool isActive,
    required Color primary,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: action,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isActive ? primary.withValues(alpha: 0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            icon,
            size: 18,
            color: isActive ? primary : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  void _toggleStyle(Attribute attribute) {
    final isActive = _isAttributeActive(attribute);
    if (isActive) {
      _controller.formatSelection(Attribute.clone(attribute, null));
    } else {
      _controller.formatSelection(attribute);
    }
  }

  bool _isAttributeActive(Attribute attribute) {
    final style = _controller.getSelectionStyle();
    return style.containsKey(attribute.key);
  }

  Widget _buildEditorView(Color primary, bool isDark) {
    return QuillEditor.basic(
      controller: _controller,
      config: QuillEditorConfig(
        placeholder: widget.hintText,
        padding: const EdgeInsets.all(12),
        scrollable: true,
        autoFocus: false,
        expands: false,
        customStyles: DefaultStyles(
          paragraph: DefaultTextBlockStyle(
            TextStyle(
              fontSize: 15,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              height: 1.5,
            ),
            const HorizontalSpacing(0, 0),
            const VerticalSpacing(4, 4),
            const VerticalSpacing(0, 0),
            null,
          ),
          placeHolder: DefaultTextBlockStyle(
            TextStyle(
              fontSize: 15,
              color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
              height: 1.5,
            ),
            const HorizontalSpacing(0, 0),
            const VerticalSpacing(4, 4),
            const VerticalSpacing(0, 0),
            null,
          ),
          bold: const TextStyle(fontWeight: FontWeight.bold),
          italic: const TextStyle(fontStyle: FontStyle.italic),
          underline: const TextStyle(decoration: TextDecoration.underline),
          strikeThrough: const TextStyle(decoration: TextDecoration.lineThrough),
        ),
      ),
    );
  }

  Widget _buildReadOnlyView(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Text(
        _controller.document.toPlainText(),
        style: TextStyle(
          fontSize: 15,
          color: isDark ? Colors.white : const Color(0xFF0F172A),
          height: 1.6,
        ),
      ),
    );
  }

  String get plainText => _controller.document.toPlainText();
  String get deltaJson => _controller.document.toDelta().toJson().toString();
}

/// Dialog chọn loại nội dung bài học với UI mềm mại
class LessonTypeSelector extends StatelessWidget {
  final String selectedType;
  final ValueChanged<String> onTypeChanged;
  final Color primaryColor;

  const LessonTypeSelector({
    super.key,
    required this.selectedType,
    required this.onTypeChanged,
    this.primaryColor = const Color(0xFF6366F1),
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _typeOption(
            context: context,
            value: 'TEXT',
            icon: Icons.article_outlined,
            label: 'Văn bản',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _typeOption(
            context: context,
            value: 'VIDEO',
            icon: Icons.videocam_outlined,
            label: 'Video',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _typeOption(
            context: context,
            value: 'LINK',
            icon: Icons.link,
            label: 'Tài liệu',
          ),
        ),
      ],
    );
  }

  Widget _typeOption({
    required BuildContext context,
    required String value,
    required IconData icon,
    required String label,
  }) {
    final isSelected = selectedType == value;
    return GestureDetector(
      onTap: () => onTypeChanged(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryColor.withValues(alpha: 0.1)
              : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? primaryColor : const Color(0xFFE2E8F0),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 22,
              color: isSelected ? primaryColor : const Color(0xFF64748B),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? primaryColor : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
