import 'package:flutter/material.dart';
import 'package:smet/model/user_model.dart';
import 'package:smet/model/department_model.dart';

class SwapInfo {
  final String pmName;
  final String departmentName;
  final int pmId;

  SwapInfo({
    required this.pmName,
    required this.departmentName,
    required this.pmId,
  });

  factory SwapInfo.fromError(String error) {
    // Format: "SWAP_DETECTED:PM_NAME|departmentName|pmId"
    final parts = error.split(':');
    if (parts.length != 2) return SwapInfo(pmName: '', departmentName: '', pmId: 0);
    final data = parts[1].split('|');
    if (data.length != 3) return SwapInfo(pmName: '', departmentName: '', pmId: 0);
    return SwapInfo(
      pmName: data[0],
      departmentName: data[1],
      pmId: int.tryParse(data[2]) ?? 0,
    );
  }

  bool get isValid => pmId > 0;
}

class ChangeDepartmentDialog extends StatefulWidget {
  final UserModel user;
  final List<DepartmentModel> departments;
  final Color primaryColor;
  final Future<bool> Function(int newDepartmentId, {bool confirmSwap}) onConfirm;

  const ChangeDepartmentDialog({
    super.key,
    required this.user,
    required this.departments,
    required this.primaryColor,
    required this.onConfirm,
  });

  static Future<void> show({
    required BuildContext context,
    required UserModel user,
    required List<DepartmentModel> departments,
    required Color primaryColor,
    required Future<bool> Function(int newDepartmentId, {bool confirmSwap}) onConfirm,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => ChangeDepartmentDialog(
        user: user,
        departments: departments,
        primaryColor: primaryColor,
        onConfirm: onConfirm,
      ),
    );
  }

  @override
  State<ChangeDepartmentDialog> createState() => _ChangeDepartmentDialogState();
}

class _ChangeDepartmentDialogState extends State<ChangeDepartmentDialog> {
  DepartmentModel? _selectedDepartment;
  bool _isLoading = false;
  String _errorMessage = '';
  bool _isSuccess = false;
  SwapInfo? _swapInfo;
  bool _isSwapLoading = false;

  Future<void> _handleConfirm() async {
    if (_selectedDepartment == null) return;
    if (_selectedDepartment!.id == widget.user.departmentId) {
      Navigator.pop(context);
      return;
    }

    // Reset state
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _swapInfo = null;
    });

    try {
      // Lần 1: Gọi API không có confirmSwap
      final success = await widget.onConfirm(_selectedDepartment!.id);

      if (!mounted) return;

      if (success) {
        setState(() {
          _isSuccess = true;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Không thể thay đổi phòng ban';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;

      final error = e.toString().replaceFirst('Exception: ', '');

      // Kiểm tra xem có phải SWAP_DETECTED không
      if (error.startsWith('SWAP_DETECTED:')) {
        final swap = SwapInfo.fromError(error);
        if (swap.isValid) {
          setState(() {
            _swapInfo = swap;
            _isLoading = false;
          });
          return;
        }
      }

      setState(() {
        _errorMessage = error;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleSwapConfirm() async {
    if (_swapInfo == null) return;

    setState(() {
      _isSwapLoading = true;
      _errorMessage = '';
    });

    try {
      // Lần 2: Gọi API với confirmSwap=true
      final success = await widget.onConfirm(_selectedDepartment!.id, confirmSwap: true);

      if (!mounted) return;

      if (success) {
        setState(() {
          _isSuccess = true;
          _isSwapLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Không thể thay đổi phòng ban';
          _isSwapLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isSwapLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 440,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildBody(),
            const SizedBox(height: 24),
            _buildFooter(),
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
            color: widget.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            Icons.swap_horiz_rounded,
            color: widget.primaryColor,
            size: 28,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Đổi phòng ban',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.user.fullName,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
          color: Colors.grey[400],
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (_isSuccess) {
      return _buildSuccessBody();
    }

    // Hiện UI swap confirmation
    if (_swapInfo != null) {
      return _buildSwapBody();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow(
          icon: Icons.business_outlined,
          label: 'Phòng ban hiện tại',
          value: widget.user.department ?? 'Chưa có',
          color: Colors.grey[600]!,
        ),
        const SizedBox(height: 8),
        _buildInfoRow(
          icon: Icons.arrow_downward_rounded,
          label: 'Phòng ban mới',
          value: _selectedDepartment?.name ?? 'Chưa chọn',
          color: widget.primaryColor,
        ),
        const SizedBox(height: 20),
        const Text(
          'Chọn phòng ban mới',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<DepartmentModel>(
              value: _selectedDepartment,
              isExpanded: true,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              borderRadius: BorderRadius.circular(12),
              hint: Text('Chọn phòng ban mới', style: TextStyle(color: Colors.grey[400])),
              items: widget.departments
                  .where((d) => d.id != widget.user.departmentId)
                  .map((d) => DropdownMenuItem(
                        value: d,
                        child: Text(d.name),
                      ))
                  .toList(),
              onChanged: (val) => setState(() => _selectedDepartment = val),
            ),
          ),
        ),
        if (_errorMessage.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFFECACA)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _errorMessage,
                    style: const TextStyle(
                      color: Color(0xFFDC2626),
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSuccessBody() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFFDCFCE7),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              color: Color(0xFF16A34A),
              size: 48,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Đổi phòng ban thành công!',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${widget.user.fullName} đã được chuyển sang phòng ban ${_selectedDepartment?.name}.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSwapBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Warning banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF3C7),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFDE68A)),
          ),
          child: Column(
            children: [
              const Icon(
                Icons.swap_horiz_rounded,
                color: Color(0xFFD97706),
                size: 40,
              ),
              const SizedBox(height: 12),
              const Text(
                'Phát hiện đổi chỗ 2 PM!',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF92400E),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Phòng ban [${_selectedDepartment?.name}] đã có PM [${_swapInfo?.pmName}].\n'
                'Nếu đồng ý, 2 PM sẽ đổi chỗ cho nhau.',
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF78350F),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Swap preview
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              _buildSwapRow(
                name: widget.user.fullName,
                fromDept: widget.user.department ?? 'Chưa có',
                toDept: _selectedDepartment?.name ?? '',
                isUser: true,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Icon(
                  Icons.swap_vert_rounded,
                  color: widget.primaryColor,
                  size: 24,
                ),
              ),
              _buildSwapRow(
                name: _swapInfo?.pmName ?? '',
                fromDept: _swapInfo?.departmentName ?? '',
                toDept: widget.user.department ?? 'Chưa có',
                isUser: false,
              ),
            ],
          ),
        ),
        if (_errorMessage.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFFECACA)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _errorMessage,
                    style: const TextStyle(
                      color: Color(0xFFDC2626),
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSwapRow({
    required String name,
    required String fromDept,
    required String toDept,
    required bool isUser,
  }) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isUser
                ? widget.primaryColor.withValues(alpha: 0.1)
                : Colors.orange.shade50,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.person_rounded,
            size: 20,
            color: isUser ? widget.primaryColor : Colors.orange.shade700,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isUser ? widget.primaryColor : Colors.orange.shade700,
                ),
              ),
              Text(
                '$fromDept → $toDept',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    if (_isSuccess) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 0,
          ),
          child: const Text('Đóng', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        ),
      );
    }

    // Footer cho SWAP confirmation
    if (_swapInfo != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: _isSwapLoading ? null : () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: Colors.grey.shade300),
              ),
              foregroundColor: Colors.grey[700],
            ),
            child: const Text('Hủy', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: _isSwapLoading ? null : _handleSwapConfirm,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: _isSwapLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text('Đổi chỗ', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          ),
        ],
      );
    }

    // Footer bình thường
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(color: Colors.grey.shade300),
            ),
            foregroundColor: Colors.grey[700],
          ),
          child: const Text('Hủy', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: (_selectedDepartment != null && !_isLoading) ? _handleConfirm : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: _selectedDepartment != null && !_isLoading
                ? widget.primaryColor
                : widget.primaryColor.withValues(alpha: 0.4),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 0,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Xác nhận', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }
}
