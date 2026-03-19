import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smet/service/common/two_factor_service.dart';

class TwoFactorSetupDialog extends StatefulWidget {
  final String qrCodeBase64;
  final VoidCallback onSuccess;
  final VoidCallback onCancel;

  const TwoFactorSetupDialog({
    super.key,
    required this.qrCodeBase64,
    required this.onSuccess,
    required this.onCancel,
  });

  static Future<bool?> show({
    required BuildContext context,
    required String qrCodeBase64,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => TwoFactorSetupDialog(
        qrCodeBase64: qrCodeBase64,
        onSuccess: () => Navigator.of(context).pop(true),
        onCancel: () => Navigator.of(context).pop(false),
      ),
    );
  }

  @override
  State<TwoFactorSetupDialog> createState() => _TwoFactorSetupDialogState();
}

class _TwoFactorSetupDialogState extends State<TwoFactorSetupDialog> {
  final _codeController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _onVerify() async {
    final code = _codeController.text.trim();

    if (code.isEmpty || code.length != 6) {
      setState(() => _errorMessage = "Vui lòng nhập mã 6 chữ số");
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await TwoFactorService.confirm2FA(code);
      log("2FA ENABLED SUCCESS");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Bật xác thực hai yếu tố thành công!"),
            backgroundColor: Colors.green,
          ),
        );
        widget.onSuccess();
      }
    } catch (e) {
      log("2FA ENABLE ERROR: $e");
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
          _codeController.clear();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildQRCode(),
            const SizedBox(height: 24),
            _buildInstructions(),
            const SizedBox(height: 20),
            _buildCodeInput(),
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              _buildErrorMessage(),
            ],
            const SizedBox(height: 24),
            _buildButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF6366F1).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.security,
            color: Color(0xFF6366F1),
            size: 28,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Kích hoạt 2FA",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "Quét mã QR bằng ứng dụng Google Authenticator",
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQRCode() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.memory(
                base64Decode(widget.qrCodeBase64),
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 180,
                    height: 180,
                    color: Colors.grey[100],
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.qr_code, size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 8),
                        Text(
                          "QR Code",
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.info_outline, size: 16, color: Colors.grey[500]),
              const SizedBox(width: 4),
              Text(
                "Mã có hiệu lực trong 30 giây",
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInstructions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, size: 18, color: Colors.blue[700]),
              const SizedBox(width: 8),
              Text(
                "Hướng dẫn",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildInstructionItem("1", "Mở ứng dụng Google Authenticator"),
          _buildInstructionItem("2", "Bấm dấu + để thêm tài khoản mới"),
          _buildInstructionItem("3", "Chọn \"Quét mã QR\" và quét mã bên trên"),
          _buildInstructionItem("4", "Nhập mã 6 chữ số được tạo"),
        ],
      ),
    );
  }

  Widget _buildInstructionItem(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$number. ",
            style: TextStyle(
              fontSize: 13,
              color: Colors.blue[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 13, color: Colors.blue[700]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCodeInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Nhập mã xác thực",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _codeController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 8,
          ),
          decoration: InputDecoration(
            hintText: "• • • • • •",
            hintStyle: TextStyle(
              fontSize: 24,
              color: Colors.grey[300],
              letterSpacing: 8,
            ),
            counterText: '',
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF6366F1),
                width: 2,
              ),
            ),
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
          ),
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(6),
          ],
          onSubmitted: (_) => _onVerify(),
        ),
      ],
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red[700], size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(color: Colors.red[700], fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _isLoading ? null : widget.onCancel,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text("Hủy"),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _onVerify,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child:
                _isLoading
                    ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                    : const Text(
                      "Xác nhận",
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
          ),
        ),
      ],
    );
  }
}
