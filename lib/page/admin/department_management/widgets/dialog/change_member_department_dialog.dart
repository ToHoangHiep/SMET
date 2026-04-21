import 'package:flutter/foundation.dart';
import 'dart:developer';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smet/model/user_model.dart';
import 'package:smet/model/department_model.dart';
import 'package:smet/model/course_model.dart';
import 'package:smet/service/common/base_url.dart';
import 'package:smet/service/common/global_notification_service.dart';
import 'package:smet/service/project/project_member_service.dart';

class MemberDepartmentError {
  final String rawMessage;
  final bool isCourseRelated;

  MemberDepartmentError({
    required this.rawMessage,
    required this.isCourseRelated,
  });

  factory MemberDepartmentError.fromMessage(String message) {
    return MemberDepartmentError(
      rawMessage: message,
      isCourseRelated:
          message.contains('khóa học') || message.contains('course') || message.contains('mentor'),
    );
  }
}

class ChangeMemberDepartmentDialog extends StatefulWidget {
  final Map<String, dynamic> member;
  final List<DepartmentModel> allDepartments;
  final Color primaryColor;
  final int? currentDepartmentId;
  final String? currentDepartmentName;
  final VoidCallback? onSuccess;

  const ChangeMemberDepartmentDialog({
    super.key,
    required this.member,
    required this.allDepartments,
    required this.primaryColor,
    this.currentDepartmentId,
    this.currentDepartmentName,
    this.onSuccess,
  });

  static Future<void> show({
    required BuildContext context,
    required Map<String, dynamic> member,
    required List<DepartmentModel> allDepartments,
    required Color primaryColor,
    int? currentDepartmentId,
    String? currentDepartmentName,
    VoidCallback? onSuccess,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => ChangeMemberDepartmentDialog(
        member: member,
        allDepartments: allDepartments,
        primaryColor: primaryColor,
        currentDepartmentId: currentDepartmentId,
        currentDepartmentName: currentDepartmentName,
        onSuccess: onSuccess,
      ),
    );
  }

  @override
  State<ChangeMemberDepartmentDialog> createState() => _ChangeMemberDepartmentDialogState();
}

class _ChangeMemberDepartmentDialogState extends State<ChangeMemberDepartmentDialog> {
  DepartmentModel? _selectedDepartment;
  bool _isLoading = false;
  String _errorMessage = '';
  bool _isSuccess = false;
  List<CourseModel> _courses = [];
  List<UserModel> _availableMentors = [];
  Set<int> _selectedCourseIds = {};
  UserModel? _selectedMentor;
  bool _isLoadingMentors = false;

  String get _memberRole {
    final r = member['role'] ?? member['roleName'] ?? '';
    return r.toUpperCase();
  }

  bool get _isMentor => _memberRole == 'MENTOR';

  int get _memberId {
    final id = member['id'];
    if (id is int) return id;
    if (id is double) return id.toInt();
    if (id is String) return int.tryParse(id) ?? 0;
    return 0;
  }

  String get _memberName {
    final firstName = member['firstName'] ?? '';
    final lastName = member['lastName'] ?? '';
    if (firstName.isNotEmpty || lastName.isNotEmpty) {
      return '$firstName $lastName'.trim();
    }
    return member['userName'] ?? member['email'] ?? 'Không tên';
  }

  String get _memberEmail => member['email'] ?? '';

  String get _memberRoleLabel {
    switch (_memberRole) {
      case 'ADMIN':
        return 'Admin';
      case 'PROJECT_MANAGER':
        return 'Quản lý';
      case 'MENTOR':
        return 'Mentor';
      default:
        return 'Nhân viên';
    }
  }

  Map<String, dynamic> get member => widget.member;

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("token");
  }

  Future<MemberDepartmentError?> _tryChangeDepartment(int newDeptId) async {
    final token = await _getToken();
    if (token == null) throw Exception("Token not found");

    // Backend: PATCH /api/departments/{id} với body chứa projectManagerId/userIds/mentorIds
    // Nhưng ở đây là đổi department cho 1 user -> dùng PUT /api/admin/users/{id}
    final url = "$baseUrl/admin/users/$_memberId";

    final body = jsonEncode({
      "departmentId": newDeptId,
    });

    log("========== CHANGE MEMBER DEPARTMENT REQUEST ==========");
    log("URL: $url");
    log("BODY: $body");

    final res = await http.patch(
      Uri.parse(url),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: body,
    );

    log("STATUS: ${res.statusCode}");
    log("RESPONSE: ${res.body}");

    if (res.statusCode == 200) {
      return null;
    }

    String msg = 'Không thể thay đổi phòng ban';
    try {
      final body = jsonDecode(res.body);
      msg = (body['message'] ?? body['error'] ?? msg).toString();
    } catch (_) {}
    return MemberDepartmentError.fromMessage(msg);
  }

  Future<void> _loadCoursesAndMentors() async {
    setState(() => _isLoadingMentors = true);

    try {
      final token = await _getToken();
      if (token == null) throw Exception("Token not found");

      final courseResults = await Future.wait([
        _fetchCoursesByMentor(token),
        _fetchAvailableMentors(token),
      ]);

      final courses = courseResults[0] as List<CourseModel>;
      final mentors = courseResults[1] as List<UserModel>;

      if (!mounted) return;

      setState(() {
        _courses = courses;
        _availableMentors = mentors;
        _selectedCourseIds = courses.map((c) => c.id).toSet();
        _isLoadingMentors = false;
      });
    } catch (e) {
      if (!mounted) return;
      GlobalNotificationService.show(
        context: context,
        message: e.toString().replaceFirst('Exception: ', ''),
        type: NotificationType.error,
      );
      setState(() {
        _isLoadingMentors = false;
      });
    }
  }

  Future<List<CourseModel>> _fetchCoursesByMentor(String token) async {
    final uri = Uri.parse("$baseUrl/lms/courses").replace(queryParameters: {
      'mentorId': _memberId.toString(),
      'page': '0',
      'size': '100',
    });

    final res = await http.get(uri, headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    });

    if (res.statusCode == 200) {
      final bodyJson = jsonDecode(res.body);
      final List<dynamic> rawList = bodyJson['data'] ?? bodyJson['content'] ?? [];
      return rawList.map((e) => CourseModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  Future<List<UserModel>> _fetchAvailableMentors(String token) async {
    final currentDeptId = widget.currentDepartmentId ?? member['departmentId'] ?? member['department']?['id'];
    if (currentDeptId == null) return [];

    final uri = Uri.parse("$baseUrl/admin/listUser").replace(queryParameters: {
      'role': 'MENTOR',
      'departmentId': currentDeptId.toString(),
      'isActive': 'true',
      'size': '100',
    });

    final res = await http.get(uri, headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    });

    if (res.statusCode == 200) {
      final bodyJson = jsonDecode(res.body);
      final List<dynamic> rawList = bodyJson['data'] ?? bodyJson['content'] ?? [];
      return rawList
          .map((e) => UserModel.fromJson(e as Map<String, dynamic>))
          .where((u) => u.id != _memberId)
          .toList();
    }
    return [];
  }

  Future<void> _previewBulkChange() async {
    if (_selectedMentor == null || _selectedCourseIds.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final token = await _getToken();
      if (token == null) throw Exception("Token not found");

      final uri = Uri.parse("$baseUrl/lms/courses/bulk-change-mentor-preview").replace(queryParameters: {
        'mentorId': _selectedMentor!.id.toString(),
        'courseIds': _selectedCourseIds.map((id) => id.toString()).toList(),
      });

      final res = await http.get(uri, headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      });

      if (!mounted) return;

      if (res.statusCode == 200) {
        await _applyBulkChange();
      } else {
        GlobalNotificationService.show(
          context: context,
          message: 'Xem trước thất bại',
          type: NotificationType.error,
        );
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      GlobalNotificationService.show(
        context: context,
        message: e.toString().replaceFirst('Exception: ', ''),
        type: NotificationType.error,
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _applyBulkChange() async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception("Token not found");

      final uri = Uri.parse("$baseUrl/lms/courses/bulk-change-mentor-safe").replace(queryParameters: {
        'mentorId': _selectedMentor!.id.toString(),
        'courseIds': _selectedCourseIds.map((id) => id.toString()).toList(),
      });

      final res = await http.put(
        uri,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (!mounted) return;

      if (res.statusCode == 200) {
        final err = await _tryChangeDepartment(_selectedDepartment!.id);
        if (!mounted) return;
        if (err == null) {
          setState(() {
            _isSuccess = true;
            _isLoading = false;
          });
        } else {
          GlobalNotificationService.show(
            context: context,
            message: 'Đã chuyển khóa học nhưng không thể đổi phòng ban: ${err.rawMessage}',
            type: NotificationType.error,
          );
          setState(() {
            _isLoading = false;
          });
        }
      } else {
        GlobalNotificationService.show(
          context: context,
          message: 'Chuyển khóa học thất bại',
          type: NotificationType.error,
        );
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      GlobalNotificationService.show(
        context: context,
        message: e.toString().replaceFirst('Exception: ', ''),
        type: NotificationType.error,
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleConfirm() async {
    if (_selectedDepartment == null) return;

    final currentDeptId = widget.currentDepartmentId ?? member['departmentId'] ?? member['department']?['id'];
    if (currentDeptId != null && _selectedDepartment!.id == currentDeptId) {
      Navigator.pop(context);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

      try {
        final currentDeptId = widget.currentDepartmentId ?? member['departmentId'] ?? member['department']?['id'];
        if (currentDeptId != null) {
          log("[ChangeDepartment] checking active project for ${_memberRole} id=$_memberId, deptId=$currentDeptId");
          final activeProjects = await ProjectMemberService.checkUserProjects(
            departmentId: currentDeptId,
            userId: _memberId,
          );
          log("[ChangeDepartment] active projects for $_memberId: ${activeProjects.length}");
          if (activeProjects.isNotEmpty) {
            if (!mounted) return;
            final roleLabel = _isMentor ? 'mentor' : 'nhân viên';
            GlobalNotificationService.show(
              context: context,
              message: 'Không thể đổi phòng ban: $roleLabel "${_memberName}" đang tham gia dự án chưa hoàn thành: "${activeProjects.first.title}". Vui lòng chuyển $roleLabel ra khỏi dự án trước.',
              type: NotificationType.warning,
            );
            setState(() => _isLoading = false);
            return;
          }
        }

        final err = await _tryChangeDepartment(_selectedDepartment!.id);

      if (!mounted) return;

      if (err == null) {
        setState(() {
          _isSuccess = true;
          _isLoading = false;
        });
        return;
      }

      if (err.isCourseRelated && _isMentor) {
        await _loadCoursesAndMentors();
        if (!mounted) return;
        setState(() {
          _isLoading = false;
        });
      } else {
        GlobalNotificationService.show(
          context: context,
          message: err.rawMessage,
          type: NotificationType.error,
        );
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      GlobalNotificationService.show(
        context: context,
        message: e.toString().replaceFirst('Exception: ', ''),
        type: NotificationType.error,
      );
      setState(() {
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
        constraints: const BoxConstraints(maxHeight: 700),
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
                  'Chuyển phòng ban',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _memberName,
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
    if (_isSuccess) {
      return _buildSuccessBody();
    }

    if (_courses.isNotEmpty) {
      return _buildMentorReassignBody();
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMemberInfo(),
          const SizedBox(height: 20),
          _buildDepartmentDropdown(),
          if (_errorMessage.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildErrorBanner(_errorMessage),
          ],
        ],
      ),
    );
  }

  Widget _buildMemberInfo() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: widget.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                _memberName.isNotEmpty ? _memberName[0].toUpperCase() : '?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
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
                  _memberName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _memberEmail,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: widget.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _memberRoleLabel,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: widget.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDepartmentDropdown() {
    final currentDeptId = widget.currentDepartmentId ?? member['departmentId'] ?? member['department']?['id'];
    final currentDeptName = widget.currentDepartmentName ?? member['department']?['name'] ?? member['departmentName'] ?? 'Chưa có';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow(
          icon: Icons.business_outlined,
          label: 'Phòng ban hiện tại',
          value: currentDeptName,
          color: Colors.grey[600]!,
        ),
        const SizedBox(height: 8),
        _buildInfoRow(
          icon: Icons.arrow_downward_rounded,
          label: 'Phòng ban mới',
          value: _selectedDepartment?.name ?? 'Chưa chọn',
          color: widget.primaryColor,
        ),
        const SizedBox(height: 16),
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
              items: widget.allDepartments
                  .where((d) {
                    final deptId = d.id;
                    return currentDeptId == null || deptId != currentDeptId;
                  })
                  .map((d) => DropdownMenuItem(
                        value: d,
                        child: Text(d.name),
                      ))
                  .toList(),
              onChanged: (val) {
                setState(() {
                  _selectedDepartment = val;
                  _errorMessage = '';
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMentorReassignBody() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                        'Mentor đang quản lý ${_courses.length} khóa học. Cần chuyển cho mentor khác cùng phòng ban với khóa học, rồi mới đổi phòng ban.',
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
          Text(
            'Danh sách khóa học (${_selectedCourseIds.length}/${_courses.length})',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: 140,
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
                    course.statusDisplayName,
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
          const Text(
            'Chọn mentor nhận khóa học (cùng phòng ban với khóa học)',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 8),
          if (_isLoadingMentors)
            const Center(child: CircularProgressIndicator())
          else ...[
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
                      setState(() => _selectedMentor = val);
                    }
                  },
                ),
              ),
            ),
            if (_availableMentors.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Không có mentor nào khác trong phòng ban. Hãy thêm mentor vào phòng ban hiện tại trước.',
                  style: TextStyle(fontSize: 12, color: Colors.red[400]),
                ),
              ),
          ],
          if (_errorMessage.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildErrorBanner(_errorMessage),
          ],
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
            'Chuyển phòng ban thành công!',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_memberName} đã được chuyển sang phòng ban ${_selectedDepartment?.name}.',
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

  Widget _buildErrorBanner(String message) {
    return Container(
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
              message,
              style: const TextStyle(
                color: Color(0xFFDC2626),
                fontSize: 13,
              ),
            ),
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
    if (_isSuccess) {
      return [
        const Spacer(),
        ElevatedButton(
          onPressed: () {
            widget.onSuccess?.call();
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 0,
          ),
          child: const Text('Đóng', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        ),
      ];
    }

    if (_courses.isNotEmpty) {
      final canConfirm = _selectedMentor != null && _selectedCourseIds.isNotEmpty;
      return [
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
          onPressed: canConfirm && !_isLoading ? _previewBulkChange : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: canConfirm && !_isLoading
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
                  child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                )
              : const Text('Chuyển khóa học & đổi phòng ban', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        ),
      ];
    }

    return [
      const Spacer(),
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
                child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
              )
            : const Text('Xác nhận', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      ),
    ];
  }
}
