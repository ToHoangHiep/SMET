import 'package:flutter/material.dart';
import 'package:smet/model/course_model.dart';
import 'package:smet/model/user_model.dart';
import 'package:smet/model/bulk_assign_result_model.dart';
import 'package:smet/service/admin/reassignment/reassignment_service.dart';

/// Dialog yêu cầu chọn mentor mới để chuyển khóa học trước khi xóa mentor khỏi phòng ban.
enum TransferState {
  loading,
  noCourses,
  selectMentor,
  preview,
  applying,
  success,
  error,
}

class TransferCourseDialog extends StatefulWidget {
  final UserModel mentor;
  final int departmentId;
  final Color primaryColor;
  final VoidCallback onComplete;

  const TransferCourseDialog({
    super.key,
    required this.mentor,
    required this.departmentId,
    required this.primaryColor,
    required this.onComplete,
  });

  static Future<void> show({
    required BuildContext context,
    required UserModel mentor,
    required int departmentId,
    required Color primaryColor,
    required VoidCallback onComplete,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => TransferCourseDialog(
        mentor: mentor,
        departmentId: departmentId,
        primaryColor: primaryColor,
        onComplete: onComplete,
      ),
    );
  }

  @override
  State<TransferCourseDialog> createState() => _TransferCourseDialogState();
}

class _TransferCourseDialogState extends State<TransferCourseDialog> {
  final _service = ReassignmentService();

  late TransferState _state;
  List<CourseModel> _courses = [];
  Set<int> _selectedCourseIds = {};
  List<UserModel> _availableMentors = [];
  UserModel? _selectedMentor;
  List<BulkAssignResultModel> _previewResults = [];
  String _errorMessage = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _state = TransferState.loading;
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        _service.getCoursesByMentor(widget.mentor.id),
        _service.getMentorsByDepartment(
          departmentId: widget.departmentId,
          excludeUserId: widget.mentor.id,
        ),
      ]);

      final courses = results[0] as List<CourseModel>;
      final mentors = results[1] as List<UserModel>;

      if (!mounted) return;

      if (courses.isEmpty) {
        setState(() {
          _state = TransferState.noCourses;
          _isLoading = false;
        });
      } else {
        setState(() {
          _courses = courses;
          _availableMentors = mentors;
          _selectedCourseIds = courses.map((c) => c.id).toSet();
          _state = TransferState.selectMentor;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Không thể tải dữ liệu: $e';
        _state = TransferState.error;
        _isLoading = false;
      });
    }
  }

  Future<void> _handlePreview() async {
    if (_selectedMentor == null) return;

    setState(() => _isLoading = true);

    try {
      final results = await _service.previewBulkChange(
        courseIds: _selectedCourseIds.toList(),
        newMentorId: _selectedMentor!.id,
      );

      if (!mounted) return;
      setState(() {
        _previewResults = results;
        _state = TransferState.preview;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Không thể xem trước: $e';
        _state = TransferState.error;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleConfirm() async {
    if (_selectedMentor == null) return;

    setState(() => _isLoading = true);

    try {
      final results = await _service.applyBulkChange(
        courseIds: _selectedCourseIds.toList(),
        newMentorId: _selectedMentor!.id,
      );

      if (!mounted) return;

      final hasError = results.any((r) => !r.isSuccess);
      if (hasError) {
        final failedCourses = results.where((r) => r.isFailed).map((r) => r.courseName).join(', ');
        setState(() {
          _errorMessage = 'Một số khóa học chuyển thất bại: $failedCourses';
          _state = TransferState.error;
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _state = TransferState.success;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Không thể chuyển khóa học: $e';
        _state = TransferState.error;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleBack() async {
    setState(() {
      _state = TransferState.selectMentor;
      _previewResults = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 560,
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              _buildBody(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: widget.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.swap_horiz, color: widget.primaryColor, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Chuyển khóa học của mentor',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Mentor "${widget.mentor.fullName}" đang quản lý ${_courses.length} khóa học',
                style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close, size: 20),
          color: Colors.grey[400],
        ),
      ],
    );
  }

  Widget _buildBody() {
    switch (_state) {
      case TransferState.loading:
        return const SizedBox(
          height: 200,
          child: Center(child: CircularProgressIndicator()),
        );

      case TransferState.noCourses:
        return _buildNoCoursesContent();

      case TransferState.selectMentor:
        return _buildSelectMentorContent();

      case TransferState.preview:
        return _buildPreviewContent();

      case TransferState.applying:
        return const SizedBox(
          height: 200,
          child: Center(child: CircularProgressIndicator()),
        );

      case TransferState.success:
        return _buildSuccessContent();

      case TransferState.error:
        return _buildErrorContent();
    }
  }

  Widget _buildNoCoursesContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green[600], size: 28),
              const SizedBox(width: 14),
              const Expanded(
                child: Text(
                  'Mentor này không có khóa học nào. Có thể xóa ngay.',
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Hủy'),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                widget.onComplete();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Xác nhận xóa'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSelectMentorContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Chọn mentor nhận khóa học trong phòng ban:',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 12),
        if (_availableMentors.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber, color: Colors.orange[600], size: 20),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Không có mentor nào trong phòng ban để nhận khóa học. Vui lòng thêm mentor vào phòng ban trước.',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          )
        else ...[
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            child: SingleChildScrollView(
              child: Column(
                children: _availableMentors.map((mentor) {
                  final isSelected = _selectedMentor?.id == mentor.id;
                  return InkWell(
                    onTap: () {
                      setState(() => _selectedMentor = mentor);
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      margin: const EdgeInsets.only(bottom: 6),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? widget.primaryColor.withValues(alpha: 0.08)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? widget.primaryColor.withValues(alpha: 0.4)
                              : const Color(0xFFE5E7EB),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: widget.primaryColor.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                _getInitials(mentor.fullName),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: widget.primaryColor,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  mentor.fullName,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (mentor.email.isNotEmpty)
                                  Text(
                                    mentor.email,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            Icon(Icons.check_circle, color: widget.primaryColor, size: 20),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildCoursesSummary(),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Hủy'),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _selectedMentor == null
                    ? null
                    : () => _handlePreview(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.primaryColor,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: widget.primaryColor.withValues(alpha: 0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Xem trước thay đổi'),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildCoursesSummary() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Icon(Icons.school, size: 16, color: Colors.grey[500]),
          const SizedBox(width: 8),
          Text(
            'Sẽ chuyển ${_selectedCourseIds.length} trong tổng số ${_courses.length} khóa học',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          const Spacer(),
          TextButton(
            onPressed: () {
              setState(() {
                if (_selectedCourseIds.length == _courses.length) {
                  _selectedCourseIds.clear();
                } else {
                  _selectedCourseIds = _courses.map((c) => c.id).toSet();
                }
              });
            },
            child: Text(
              _selectedCourseIds.length == _courses.length ? 'Bỏ chọn tất cả' : 'Chọn tất cả',
              style: TextStyle(fontSize: 12, color: widget.primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewContent() {
    final successCount = _previewResults.where((r) => r.isSuccess).length;
    final failCount = _previewResults.where((r) => r.isFailed).length;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Xem trước kết quả chuyển cho "${_selectedMentor!.fullName}":',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          constraints: const BoxConstraints(maxHeight: 220),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _previewResults.length,
            itemBuilder: (context, index) {
              final result = _previewResults[index];
              final color = result.isSuccess ? Colors.green : Colors.red;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                margin: const EdgeInsets.only(bottom: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: color.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Icon(
                      result.isSuccess ? Icons.check_circle : Icons.error,
                      size: 16,
                      color: color,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        result.courseName ?? 'Khóa học #${result.courseId}',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    Text(
                      result.isSuccess ? 'Thành công' : 'Thất bại',
                      style: TextStyle(fontSize: 11, color: color),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Icon(Icons.info_outline, size: 14, color: Colors.grey[500]),
            const SizedBox(width: 6),
            Text(
              'Thành công: $successCount / Thất bại: $failCount',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: _handleBack,
              child: const Text('Quay lại'),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: failCount == 0 ? _handleConfirm : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.primaryColor,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey[300],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Xác nhận chuyển'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSuccessContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green[600], size: 32),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Chuyển khóa học thành công!',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Đã chuyển ${_selectedCourseIds.length} khóa học cho "${_selectedMentor!.fullName}"',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                widget.onComplete();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Hoàn tất'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildErrorContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.error, color: Colors.red[600], size: 32),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  _errorMessage,
                  style: TextStyle(fontSize: 13, color: Colors.red[700]),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Đóng'),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _state = TransferState.selectMentor;
                  _previewResults = [];
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      ],
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0].substring(0, parts[0].length.clamp(0, 2)).toUpperCase();
    }
    return '?';
  }
}
