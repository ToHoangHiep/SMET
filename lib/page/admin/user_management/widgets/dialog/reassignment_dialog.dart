import 'package:flutter/material.dart';
import 'package:smet/model/course_model.dart';
import 'package:smet/model/user_model.dart';
import 'package:smet/model/department_model.dart';
import 'package:smet/model/bulk_assign_result_model.dart';
import 'package:smet/service/admin/reassignment/reassignment_service.dart';

enum ReassignmentState {
  selectDepartment,
  blocked,
  preview,
  applying,
  success,
  error,
}

class ReassignmentDialog extends StatefulWidget {
  final UserModel mentor;
  final List<DepartmentModel> departments;
  final Color primaryColor;
  final VoidCallback onComplete;

  const ReassignmentDialog({
    super.key,
    required this.mentor,
    required this.departments,
    required this.primaryColor,
    required this.onComplete,
  });

  static Future<void> show({
    required BuildContext context,
    required UserModel mentor,
    required List<DepartmentModel> departments,
    required Color primaryColor,
    required VoidCallback onComplete,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => ReassignmentDialog(
        mentor: mentor,
        departments: departments,
        primaryColor: primaryColor,
        onComplete: onComplete,
      ),
    );
  }

  @override
  State<ReassignmentDialog> createState() => _ReassignmentDialogState();
}

class _ReassignmentDialogState extends State<ReassignmentDialog> {
  final _service = ReassignmentService();
  late ReassignmentState _state;
  DepartmentModel? _selectedDepartment;
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
    _state = ReassignmentState.selectDepartment;
  }

  Future<void> _handleChangeDepartment() async {
    if (_selectedDepartment == null) return;

    setState(() => _isLoading = true);

    try {
      final error = await _service.tryChangeDepartment(
        userId: widget.mentor.id,
        newDepartmentId: _selectedDepartment!.id,
        mentorName: widget.mentor.fullName,
        mentor: widget.mentor,
      );

      if (!mounted) return;

      if (error == null) {
        // Thành công luôn
        setState(() {
          _state = ReassignmentState.success;
          _isLoading = false;
        });
        return;
      }

      // Bị chặn → load courses + mentor thay thế.
      // Backend bulkChangeMentorSafe yêu cầu mentor mới cùng department với *khóa học*,
      // không phải phòng ban đích khi đổi mentor — phải lấy mentor cùng phòng ban hiện tại
      // (hoặc suy ra từ departmentId trên khóa học nếu user chưa có departmentId).
      List<CourseModel> loadedCourses;
      List<UserModel> loadedMentors;

      final int? mentorDeptId = widget.mentor.departmentId;
      if (mentorDeptId != null) {
        final results = await Future.wait([
          _service.getCoursesByMentor(widget.mentor.id),
          _service.getMentorsByDepartment(
            departmentId: mentorDeptId,
            excludeUserId: widget.mentor.id,
          ),
        ]);
        loadedCourses = results[0] as List<CourseModel>;
        loadedMentors = results[1] as List<UserModel>;
      } else {
        loadedCourses = await _service.getCoursesByMentor(widget.mentor.id);
        if (!mounted) return;
        int? deptForPeers;
        for (final c in loadedCourses) {
          if (c.departmentId != null) {
            deptForPeers = c.departmentId;
            break;
          }
        }
        if (deptForPeers == null) {
          setState(() {
            _state = ReassignmentState.error;
            _errorMessage =
                'Không xác định được phòng ban của khóa học để tìm mentor thay thế.';
            _isLoading = false;
          });
          return;
        }
        loadedMentors = await _service.getMentorsByDepartment(
          departmentId: deptForPeers,
          excludeUserId: widget.mentor.id,
        );
      }

      if (!mounted) return;

      setState(() {
        _state = ReassignmentState.blocked;
        _courses = loadedCourses;
        _availableMentors = loadedMentors;
        _selectedCourseIds = _courses.map((c) => c.id).toSet();
        // Đồng bộ _selectedMentor với instance mới từ API
        // để DropdownButton<UserModel> so sánh đúng reference
        if (_selectedMentor != null) {
          _selectedMentor = _availableMentors.cast<UserModel?>().firstWhere(
            (m) => m?.id == _selectedMentor!.id,
            orElse: () => null,
          );
        }
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _state = ReassignmentState.error;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _handlePreview() async {
    if (_selectedMentor == null || _selectedCourseIds.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final results = await _service.previewBulkChange(
        courseIds: _selectedCourseIds.toList(),
        newMentorId: _selectedMentor!.id,
      );

      if (!mounted) return;

      setState(() {
        _previewResults = results;
        _state = ReassignmentState.preview;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _state = ReassignmentState.error;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _handleConfirm() async {
    if (_selectedMentor == null) return;

    setState(() {
      _state = ReassignmentState.applying;
      _isLoading = true;
    });

    try {
      await _service.applyBulkChange(
        courseIds: _selectedCourseIds.toList(),
        newMentorId: _selectedMentor!.id,
      );

      if (!mounted) return;

      // Sau khi bulk reassign xong → gọi lại đổi department
      final error = await _service.tryChangeDepartment(
        userId: widget.mentor.id,
        newDepartmentId: _selectedDepartment!.id,
        mentorName: widget.mentor.fullName,
        mentor: widget.mentor,
      );

      if (!mounted) return;

      if (error != null) {
        setState(() {
          _state = ReassignmentState.error;
          _errorMessage = 'Đã chuyển khóa học nhưng không thể đổi phòng ban: ${error.rawMessage}';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _state = ReassignmentState.success;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _state = ReassignmentState.error;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 560,
        constraints: const BoxConstraints(maxHeight: 680),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            Flexible(
              child: _isLoading
                  ? _buildLoading()
                  : SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      child: _buildBody(),
                    ),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: widget.primaryColor.withValues(alpha: 0.05),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
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
                  'Chuyển phòng ban cho Mentor',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.mentor.fullName,
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
      ),
    );
  }

  Widget _buildBody() {
    switch (_state) {
      case ReassignmentState.selectDepartment:
        return _buildSelectDepartmentBody();
      case ReassignmentState.blocked:
        return _buildBlockedBody();
      case ReassignmentState.preview:
        return _buildPreviewBody();
      case ReassignmentState.success:
        return _buildSuccessBody();
      case ReassignmentState.error:
        return _buildErrorBody();
      case ReassignmentState.applying:
        return const SizedBox.shrink();
    }
  }

  Widget _buildSelectDepartmentBody() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current department info
          _buildInfoRow(
            icon: Icons.business_outlined,
            label: 'Phòng ban hiện tại',
            value: widget.mentor.department ?? 'Chưa có',
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
                    .where((d) => d.id != widget.mentor.departmentId)
                    .map((d) => DropdownMenuItem(
                          value: d,
                          child: Text(d.name),
                        ))
                    .toList(),
                onChanged: (val) => setState(() => _selectedDepartment = val),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlockedBody() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Không thể đổi phòng ban ngay',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF92400E),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Mentor đang quản lý ${_courses.length} khóa học. Cần chuyển cho mentor khác cùng phòng ban với khóa học (thường là phòng ban hiện tại của mentor), rồi mới đổi sang phòng ban đã chọn.',
                        style: const TextStyle(
                          color: Color(0xFF92400E),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Course list header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Danh sách khóa học (${_selectedCourseIds.length}/${_courses.length})',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF374151),
                  fontSize: 14,
                ),
              ),
              Row(
                children: [
                  _SelectAllButton(
                    allSelected: _selectedCourseIds.length == _courses.length,
                    primaryColor: widget.primaryColor,
                    onSelectAll: () => setState(
                      () => _selectedCourseIds = _courses.map((c) => c.id).toSet(),
                    ),
                    onDeselectAll: () => setState(() => _selectedCourseIds.clear()),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Course list
          Container(
            height: 160,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _courses.length,
              separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade100),
              itemBuilder: (context, index) {
                final course = _courses[index];
                final selected = _selectedCourseIds.contains(course.id);
                return CheckboxListTile(
                  value: selected,
                  onChanged: (val) {
                    setState(() {
                      if (val == true) {
                        _selectedCourseIds.add(course.id);
                      } else {
                        _selectedCourseIds.remove(course.id);
                      }
                    });
                  },
                  title: Text(
                    course.title,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    [
                      course.statusDisplayName,
                      if (course.departmentName != null &&
                          course.departmentName!.trim().isNotEmpty)
                        course.departmentName!.trim(),
                    ].join(' · '),
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
                  dense: true,
                  controlAffinity: ListTileControlAffinity.leading,
                  activeColor: widget.primaryColor,
                );
              },
            ),
          ),
          const SizedBox(height: 20),

          // Mentor dropdown (cùng phòng ban với khóa học / mentor hiện tại — không phải phòng ban đích)
          const Text(
            'Chọn mentor nhận khóa học (cùng phòng ban với khóa học)',
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
              child: DropdownButton<UserModel>(
                value: _availableMentors.cast<UserModel?>().firstWhere(
                      (m) => m?.id == _selectedMentor?.id,
                      orElse: () => null,
                    ),
                isExpanded: true,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                borderRadius: BorderRadius.circular(12),
                hint: Text('Chọn mentor', style: TextStyle(color: Colors.grey[400])),
                items: _availableMentors
                    .map((m) => DropdownMenuItem(
                          value: m,
                          child: Text('${m.fullName} (${m.email})'),
                        ))
                    .toList(),
                onChanged: (val) {
                  if (val != null) {
                    // Đảm bảo _selectedMentor luôn là instance trong _availableMentors
                    final matched = _availableMentors.cast<UserModel?>().firstWhere(
                      (m) => m?.id == val.id,
                      orElse: () => val,
                    );
                    setState(() => _selectedMentor = matched);
                  }
                },
              ),
            ),
          ),
          if (_availableMentors.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Không có mentor nào khác trong phòng ban của khóa học để nhận chuyển giao. '
                'Hãy thêm mentor vào đúng phòng ban đó (thường là phòng ban hiện tại của mentor này), không phải phòng ban đích.',
                style: TextStyle(fontSize: 12, color: Colors.red[400]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPreviewBody() {
    final failCount = _previewResults.where((r) => r.isFailed).length;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Preview summary
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFBBF7D0)),
            ),
            child: Row(
              children: [
                Icon(
                  failCount == 0 ? Icons.check_circle : Icons.info_outline,
                  color: failCount == 0 ? const Color(0xFF16A34A) : const Color(0xFFD97706),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        failCount == 0
                            ? 'Tất cả khóa học sẽ được chuyển thành công'
                            : 'Có $failCount khóa học không thể chuyển',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: failCount == 0 ? const Color(0xFF15803D) : const Color(0xFFD97706),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Mentor mới: ${_selectedMentor?.fullName ?? ""}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Results list
          const Text(
            'Kết quả xem trước',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _previewResults.length,
              separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade100),
              itemBuilder: (context, index) {
                final result = _previewResults[index];
                return ListTile(
                  dense: true,
                  leading: Icon(
                    result.isSuccess
                        ? Icons.check_circle
                        : Icons.cancel,
                    color: result.isSuccess
                        ? const Color(0xFF16A34A)
                        : const Color(0xFFDC2626),
                    size: 20,
                  ),
                  title: Text(
                    result.courseName ?? 'Khóa học #${result.courseId}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    result.code.displayName,
                    style: TextStyle(
                      fontSize: 11,
                      color: result.isSuccess ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessBody() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
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
            'Chuyển phòng ban thành công!',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Mentor đã được chuyển sang phòng ban mới cùng với các khóa học.',
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

  Widget _buildErrorBody() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFFEE2E2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              color: Color(0xFFDC2626),
              size: 48,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Đã xảy ra lỗi',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage,
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
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
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildLoading() {
    return Padding(
      padding: const EdgeInsets.all(60),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: widget.primaryColor),
            const SizedBox(height: 16),
            Text(
              'Đang xử lý...',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFBFC),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        border: Border(top: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        children: _buildFooterActions(),
      ),
    );
  }

  List<Widget> _buildFooterActions() {
    switch (_state) {
      case ReassignmentState.selectDepartment:
        return [
          const Spacer(),
          _DialogButton(
            label: 'Hủy',
            onPressed: () => Navigator.pop(context),
            isSecondary: true,
            primaryColor: widget.primaryColor,
          ),
          const SizedBox(width: 12),
          _DialogButton(
            label: 'Đổi phòng ban',
            onPressed: _selectedDepartment != null ? _handleChangeDepartment : null,
            primaryColor: widget.primaryColor,
          ),
        ];

      case ReassignmentState.blocked:
        return [
          const Spacer(),
          _DialogButton(
            label: 'Hủy',
            onPressed: () => Navigator.pop(context),
            isSecondary: true,
            primaryColor: widget.primaryColor,
          ),
          const SizedBox(width: 12),
          _DialogButton(
            label: 'Xem trước thay đổi',
            onPressed: (_selectedMentor != null && _selectedCourseIds.isNotEmpty)
                ? _handlePreview
                : null,
            primaryColor: widget.primaryColor,
          ),
        ];

      case ReassignmentState.preview:
        return [
          const Spacer(),
          _DialogButton(
            label: 'Quay lại',
            onPressed: () => setState(() => _state = ReassignmentState.blocked),
            isSecondary: true,
            primaryColor: widget.primaryColor,
          ),
          const SizedBox(width: 12),
          _DialogButton(
            label: 'Xác nhận chuyển',
            onPressed: _handleConfirm,
            primaryColor: widget.primaryColor,
          ),
        ];

      case ReassignmentState.applying:
        return [
          const Spacer(),
          _DialogButton(
            label: 'Đang xử lý...',
            onPressed: null,
            primaryColor: widget.primaryColor,
          ),
        ];

      case ReassignmentState.success:
        return [
          const Spacer(),
          _DialogButton(
            label: 'Đóng',
            onPressed: () {
              widget.onComplete();
              Navigator.pop(context);
            },
            primaryColor: widget.primaryColor,
          ),
        ];

      case ReassignmentState.error:
        return [
          const Spacer(),
          _DialogButton(
            label: 'Đóng',
            onPressed: () => Navigator.pop(context),
            isSecondary: true,
            primaryColor: widget.primaryColor,
          ),
          const SizedBox(width: 12),
          _DialogButton(
            label: 'Thử lại',
            onPressed: () => setState(() => _state = ReassignmentState.selectDepartment),
            primaryColor: widget.primaryColor,
          ),
        ];
    }
  }
}

class _DialogButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isSecondary;
  final Color primaryColor;

  const _DialogButton({
    required this.label,
    required this.onPressed,
    this.isSecondary = false,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null;

    if (isSecondary) {
      return TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: Colors.grey.shade300),
          ),
          foregroundColor: Colors.grey[700],
        ),
        child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      );
    }

    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isDisabled
            ? primaryColor.withValues(alpha: 0.4)
            : primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 0,
      ),
      child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
    );
  }
}

class _SelectAllButton extends StatelessWidget {
  final bool allSelected;
  final Color primaryColor;
  final VoidCallback onSelectAll;
  final VoidCallback onDeselectAll;

  const _SelectAllButton({
    required this.allSelected,
    required this.primaryColor,
    required this.onSelectAll,
    required this.onDeselectAll,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: allSelected ? onDeselectAll : onSelectAll,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        allSelected ? 'Bỏ chọn tất cả' : 'Chọn tất cả',
        style: TextStyle(
          fontSize: 12,
          color: primaryColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
