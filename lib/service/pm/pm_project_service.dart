import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:smet/service/common/base_url.dart';
import 'package:smet/service/common/auth_service.dart';
import 'package:smet/model/project_model.dart';
import 'package:smet/service/employee/employee_project_service.dart';
import 'dart:developer';

// Re-export DTOs từ employee_project_service để các file khác chỉ cần import pm_project_service
export 'package:smet/service/employee/employee_project_service.dart'
    show ProjectReviewStateData, ProjectDashboardData, MemberProgressData;

/// Service dành riêng cho PM - quản lý phê duyệt dự án
///
/// Backend API:
///
/// GET  /api/projects?page=0&size=20&status=REVIEW_PENDING
///      → Lấy danh sách dự án cần phê duyệt (PM tự filter status=REVIEW_PENDING)
///
/// GET  /api/projects/get/{id}
///      → Lấy chi tiết dự án (trả về submissionLink, feedback, timestamps)
///
/// GET  /api/projects/{id}/review-state
///      → Lấy trạng thái review (submitted, hasMentor, mentorApproved, hasPM, pmApproved, currentStage)
///
/// POST /api/projects/{id}/approve/pm
///      → PM phê duyệt dự án
///
/// POST /api/projects/{id}/reject/pm?reason=...
///      → PM từ chối dự án
///
/// GET  /api/projects/{id}/dashboard
///      → Lấy dashboard với review state
class PmProjectService {
  static const String _baseEndpoint = '$baseUrl/projects';

  static Future<Map<String, String>> get _headers async {
    final token = await AuthService.getToken();
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  // ============================================================
  // GET /api/projects?page=0&size=20&status=REVIEW_PENDING
  // Lấy danh sách dự án cần PM phê duyệt
  // Backend trả về phân trang - PM filter tất cả dự án của phòng ban
  // ============================================================
  static Future<PmProjectListResponse> getProjectsForReview({
    int page = 0,
    int size = 20,
    String? keyword,
    String? status,
  }) async {
    try {
      final headers = await _headers;

      final queryParams = <String, String>{
        'page': page.toString(),
        'size': size.toString(),
      };

      if (keyword != null && keyword.isNotEmpty) {
        queryParams['keyword'] = keyword;
      }
      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }

      final uri = Uri.parse('$_baseEndpoint')
          .replace(queryParameters: queryParams);

      final response = await http.get(uri, headers: headers);

      log('GET PM PROJECTS FOR REVIEW STATUS: ${response.statusCode}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return PmProjectListResponse.fromJson(json);
      } else {
        throw Exception('Khong the tai danh sach du an cho PM');
      }
    } catch (e) {
      log('PmProjectService.getProjectsForReview failed: $e');
      rethrow;
    }
  }

  // ============================================================
  // GET /api/projects/get/{id}
  // Lấy chi tiết dự án cho PM xem
  // ============================================================
  static Future<PmProjectDetail> getProjectDetail(int projectId) async {
    try {
      final headers = await _headers;
      final url = Uri.parse('$_baseEndpoint/get/$projectId');

      final response = await http.get(url, headers: headers);

      log('GET PM PROJECT DETAIL STATUS: ${response.statusCode}, projectId=$projectId');

      if (response.statusCode == 200) {
        return PmProjectDetail.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Khong the tai chi tiet du an');
      }
    } catch (e) {
      log('PmProjectService.getProjectDetail failed: $e');
      rethrow;
    }
  }

  // ============================================================
  // GET /api/projects/{id}/review-state
  // Lấy trạng thái review của dự án
  // ============================================================
  static Future<ProjectReviewStateData> getReviewState(int projectId) async {
    try {
      final headers = await _headers;
      final url = Uri.parse('$_baseEndpoint/$projectId/review-state');

      final response = await http.get(url, headers: headers);

      log('GET PM REVIEW STATE STATUS: ${response.statusCode}, projectId=$projectId');

      if (response.statusCode == 200) {
        return ProjectReviewStateData.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Khong the tai trang thai review');
      }
    } catch (e) {
      log('PmProjectService.getReviewState failed: $e');
      rethrow;
    }
  }

  // ============================================================
  // POST /api/projects/{id}/approve/pm
  // PM phê duyệt dự án
  // Backend validate: phải là PM của department, dự án đã submit
  // Nếu có mentor → mentor phải approve trước
  // ============================================================
  static Future<void> approveByPM(int projectId) async {
    try {
      final headers = await _headers;
      final url = Uri.parse('$_baseEndpoint/$projectId/approve/pm');

      final response = await http.post(url, headers: headers);

      log('PM APPROVE STATUS: ${response.statusCode}, projectId=$projectId');

      if (response.statusCode != 200) {
        final body = jsonDecode(response.body);
        throw Exception(body['message'] ?? 'Khong the duyet du an');
      }
    } catch (e) {
      log('PmProjectService.approveByPM failed: $e');
      rethrow;
    }
  }

  // ============================================================
  // POST /api/projects/{id}/reject/pm?reason=...
  // PM từ chối dự án
  // Backend validate: phải là PM của department
  // ============================================================
  static Future<void> rejectByPM(int projectId, String reason) async {
    try {
      final headers = await _headers;
      final url = Uri.parse('$_baseEndpoint/$projectId/reject/pm?reason=${Uri.encodeComponent(reason)}');

      final response = await http.post(url, headers: headers);

      log('PM REJECT STATUS: ${response.statusCode}, projectId=$projectId');

      if (response.statusCode != 200) {
        final body = jsonDecode(response.body);
        throw Exception(body['message'] ?? 'Khong the tu choi du an');
      }
    } catch (e) {
      log('PmProjectService.rejectByPM failed: $e');
      rethrow;
    }
  }

  // ============================================================
  // GET /api/projects/{id}/dashboard
  // Lấy dashboard để xem tiến độ thành viên
  // ============================================================
  static Future<ProjectDashboardData> getDashboard(int projectId) async {
    try {
      final headers = await _headers;
      final url = Uri.parse('$_baseEndpoint/$projectId/dashboard');

      final response = await http.get(url, headers: headers);

      log('GET PM DASHBOARD STATUS: ${response.statusCode}, projectId=$projectId');

      if (response.statusCode == 200) {
        return ProjectDashboardData.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Khong the tai dashboard');
      }
    } catch (e) {
      log('PmProjectService.getDashboard failed: $e');
      rethrow;
    }
  }
}

// ============================================================
// DTO: PM Project List Response (phân trang)
// ============================================================
class PmProjectListResponse {
  final List<PmProjectListItem> content;
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;

  PmProjectListResponse({
    required this.content,
    required this.page,
    required this.size,
    required this.totalElements,
    required this.totalPages,
  });

  factory PmProjectListResponse.fromJson(Map<String, dynamic> json) {
    final contentJson = json['content'];
    List<PmProjectListItem> items = [];

    if (contentJson is List) {
      items = contentJson.map((item) => PmProjectListItem.fromJson(item)).toList();
    }

    return PmProjectListResponse(
      content: items,
      page: json['page'] ?? json['number'] ?? 0,
      size: json['size'] ?? json['pageable']?['pageSize'] ?? 20,
      totalElements: json['totalElements'] ?? 0,
      totalPages: json['totalPages'] ?? 0,
    );
  }
}

// ============================================================
// DTO: PM Project List Item
// ============================================================
class PmProjectListItem {
  final int id;
  final String title;
  final String? description;
  final int departmentId;
  final ProjectStatus status;
  final int leaderId;
  final String? leaderName;
  final int? mentorId;
  final String? mentorName;
  final List<int>? memberIds;
  final List<String>? memberNames;

  // Trường bổ sung cho PM review
  final bool? submitted;
  final String? submissionLink;
  final DateTime? submittedAt;
  final bool? mentorApproved;
  final DateTime? mentorApprovedAt;
  final String? mentorFeedback;
  final bool? pmApproved;
  final DateTime? pmApprovedAt;
  final String? pmFeedback;

  PmProjectListItem({
    required this.id,
    required this.title,
    this.description,
    required this.departmentId,
    required this.status,
    required this.leaderId,
    this.leaderName,
    this.mentorId,
    this.mentorName,
    this.memberIds,
    this.memberNames,
    this.submitted,
    this.submissionLink,
    this.submittedAt,
    this.mentorApproved,
    this.mentorApprovedAt,
    this.mentorFeedback,
    this.pmApproved,
    this.pmApprovedAt,
    this.pmFeedback,
  });

  factory PmProjectListItem.fromJson(Map<String, dynamic> json) {
    return PmProjectListItem(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description']?.toString(),
      departmentId: json['departmentId'] ?? json['department']?['id'] ?? 0,
      status: ProjectStatus.fromString(json['status']),
      leaderId: json['leaderId'] ?? 0,
      leaderName: json['leaderName']?.toString(),
      mentorId: json['mentorId'] as int?,
      mentorName: json['mentorName']?.toString(),
      memberIds: json['memberIds'] != null ? List<int>.from(json['memberIds']) : null,
      memberNames: json['memberNames'] != null ? List<String>.from(json['memberNames']) : null,
      // Bổ sung fields cho PM review
      submitted: json['submitted'] as bool?,
      submissionLink: json['submissionLink']?.toString(),
      submittedAt: json['submittedAt'] != null
          ? DateTime.tryParse(json['submittedAt'].toString())
          : null,
      mentorApproved: json['mentorApproved'] as bool?,
      mentorApprovedAt: json['mentorApprovedAt'] != null
          ? DateTime.tryParse(json['mentorApprovedAt'].toString())
          : null,
      mentorFeedback: json['mentorFeedback']?.toString(),
      pmApproved: json['pmApproved'] as bool?,
      pmApprovedAt: json['pmApprovedAt'] != null
          ? DateTime.tryParse(json['pmApprovedAt'].toString())
          : null,
      pmFeedback: json['pmFeedback']?.toString(),
    );
  }

  /// Trạng thái review hiển thị cho PM
  String get reviewStatusLabel {
    if (submitted != true) return 'Chua nop';
    if (pmApproved == true) return 'Da duyet';
    if (mentorApproved == true) return 'Cho PM duyet';
    if (hasMentor) return 'Cho mentor duyet';
    return 'Cho PM duyet';
  }

  bool get hasMentor => mentorId != null;

  bool get canApproveByPM {
    if (submitted != true) return false;
    if (pmApproved == true) return false;
    // Có mentor → phải approve trước
    if (hasMentor && mentorApproved != true) return false;
    return true;
  }

  String get currentStage {
    if (submitted != true) return 'NOT_SUBMITTED';
    if (pmApproved == true) return 'COMPLETED';
    if (hasMentor && mentorApproved != true) return 'WAITING_MENTOR';
    return 'WAITING_PM';
  }
}

// ============================================================
// DTO: PM Project Detail
// ============================================================
class PmProjectDetail {
  final int id;
  final String title;
  final String? description;
  final int departmentId;
  final ProjectStatus status;
  final int leaderId;
  final String? leaderName;
  final int? mentorId;
  final String? mentorName;
  final List<int>? memberIds;
  final List<String>? memberNames;

  // Trường phê duyệt
  final bool submitted;
  final String? submissionLink;
  final DateTime? submittedAt;
  final int? submittedBy;
  final bool mentorApproved;
  final int? mentorApprovedBy;
  final DateTime? mentorApprovedAt;
  final String? mentorFeedback;
  final bool pmApproved;
  final int? pmApprovedBy;
  final DateTime? pmApprovedAt;
  final String? pmFeedback;
  final ProjectReviewStateData? reviewState;

  PmProjectDetail({
    required this.id,
    required this.title,
    this.description,
    required this.departmentId,
    required this.status,
    required this.leaderId,
    this.leaderName,
    this.mentorId,
    this.mentorName,
    this.memberIds,
    this.memberNames,
    required this.submitted,
    this.submissionLink,
    this.submittedAt,
    this.submittedBy,
    required this.mentorApproved,
    this.mentorApprovedBy,
    this.mentorApprovedAt,
    this.mentorFeedback,
    required this.pmApproved,
    this.pmApprovedBy,
    this.pmApprovedAt,
    this.pmFeedback,
    this.reviewState,
  });

  factory PmProjectDetail.fromJson(Map<String, dynamic> json) {
    return PmProjectDetail(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description']?.toString(),
      departmentId: json['departmentId'] ?? json['department']?['id'] ?? 0,
      status: ProjectStatus.fromString(json['status']),
      leaderId: json['leaderId'] ?? 0,
      leaderName: json['leaderName']?.toString(),
      mentorId: json['mentorId'] as int?,
      mentorName: json['mentorName']?.toString(),
      memberIds: json['memberIds'] != null ? List<int>.from(json['memberIds']) : null,
      memberNames: json['memberNames'] != null ? List<String>.from(json['memberNames']) : null,
      submitted: json['submitted'] == true,
      submissionLink: json['submissionLink']?.toString(),
      submittedAt: json['submittedAt'] != null
          ? DateTime.tryParse(json['submittedAt'].toString())
          : null,
      submittedBy: json['submittedBy'] as int?,
      mentorApproved: json['mentorApproved'] == true,
      mentorApprovedBy: json['mentorApprovedBy'] as int?,
      mentorApprovedAt: json['mentorApprovedAt'] != null
          ? DateTime.tryParse(json['mentorApprovedAt'].toString())
          : null,
      mentorFeedback: json['mentorFeedback']?.toString(),
      pmApproved: json['pmApproved'] == true,
      pmApprovedBy: json['pmApprovedBy'] as int?,
      pmApprovedAt: json['pmApprovedAt'] != null
          ? DateTime.tryParse(json['pmApprovedAt'].toString())
          : null,
      pmFeedback: json['pmFeedback']?.toString(),
      reviewState: json['reviewState'] != null
          ? ProjectReviewStateData.fromJson(json['reviewState'])
          : null,
    );
  }

  bool get hasMentor => mentorId != null;

  bool get canApproveByPM {
    if (!submitted) return false;
    if (pmApproved) return false;
    // Có mentor → phải approve trước
    if (hasMentor && !mentorApproved) return false;
    return true;
  }

  String get currentStage {
    if (!submitted) return 'NOT_SUBMITTED';
    if (pmApproved) return 'COMPLETED';
    if (hasMentor && !mentorApproved) return 'WAITING_MENTOR';
    return 'WAITING_PM';
  }

  String get currentStageLabel {
    switch (currentStage) {
      case 'NOT_SUBMITTED':
        return 'Chua nop';
      case 'WAITING_MENTOR':
        return 'Cho mentor duyet';
      case 'WAITING_PM':
        return 'Cho PM duyet';
      case 'COMPLETED':
        return 'Da hoan thanh';
      default:
        return currentStage;
    }
  }
}
