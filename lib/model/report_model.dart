import 'dart:convert';
import 'dart:developer';

// ================================================================
// REPORT ENUMS
// Backend: base.api.report.enums.*
// ================================================================

enum ReportStatus {
  DRAFT,
  SUBMITTED,
  APPROVED,
  REJECTED;

  String get displayName {
    switch (this) {
      case ReportStatus.DRAFT:
        return 'Nháp';
      case ReportStatus.SUBMITTED:
        return 'Đã gửi';
      case ReportStatus.APPROVED:
        return 'Đã duyệt';
      case ReportStatus.REJECTED:
        return 'Từ chối';
    }
  }

  static ReportStatus fromString(String? value) {
    if (value == null) return ReportStatus.DRAFT;
    switch (value.toUpperCase()) {
      case 'DRAFT':
        return ReportStatus.DRAFT;
      case 'SUBMITTED':
        return ReportStatus.SUBMITTED;
      case 'APPROVED':
        return ReportStatus.APPROVED;
      case 'REJECTED':
        return ReportStatus.REJECTED;
      default:
        return ReportStatus.DRAFT;
    }
  }
}

enum ReportType {
  MENTOR_WEEKLY,
  MENTOR_MONTHLY,
  PM_WEEKLY,
  PM_MONTHLY,
  ADMIN_WEEKLY,
  ADMIN_MONTHLY;

  String get displayName {
    switch (this) {
      case ReportType.MENTOR_WEEKLY:
        return 'Báo cáo tuần - Mentor';
      case ReportType.MENTOR_MONTHLY:
        return 'Báo cáo tháng - Mentor';
      case ReportType.PM_WEEKLY:
        return 'Báo cáo tuần - Quản lý dự án';
      case ReportType.PM_MONTHLY:
        return 'Báo cáo tháng - Quản lý dự án';
      case ReportType.ADMIN_WEEKLY:
        return 'Báo cáo tuần - Quản trị';
      case ReportType.ADMIN_MONTHLY:
        return 'Báo cáo tháng - Quản trị';
    }
  }

  String get shortName {
    switch (this) {
      case ReportType.MENTOR_WEEKLY:
        return 'Mentor Tuần';
      case ReportType.MENTOR_MONTHLY:
        return 'Mentor Tháng';
      case ReportType.PM_WEEKLY:
        return 'PM Tuần';
      case ReportType.PM_MONTHLY:
        return 'PM Tháng';
      case ReportType.ADMIN_WEEKLY:
        return 'Admin Tuần';
      case ReportType.ADMIN_MONTHLY:
        return 'Admin Tháng';
    }
  }

  static ReportType fromString(String? value) {
    if (value == null) return ReportType.MENTOR_WEEKLY;
    return ReportType.values.firstWhere(
      (e) => e.name == value.toUpperCase(),
      orElse: () => ReportType.MENTOR_WEEKLY,
    );
  }
}

enum ReportScope {
  COURSE,
  PROJECT,
  SYSTEM;

  String get displayName {
    switch (this) {
      case ReportScope.COURSE:
        return 'Khóa học';
      case ReportScope.PROJECT:
        return 'Dự án';
      case ReportScope.SYSTEM:
        return 'Hệ thống';
    }
  }

  static ReportScope fromString(String? value) {
    if (value == null) return ReportScope.COURSE;
    return ReportScope.values.firstWhere(
      (e) => e.name == value.toUpperCase(),
      orElse: () => ReportScope.COURSE,
    );
  }
}

enum ReportActionType {
  EDIT,
  SUBMIT,
  APPROVE,
  REJECT;

  String get displayName {
    switch (this) {
      case ReportActionType.EDIT:
        return 'Chỉnh sửa';
      case ReportActionType.SUBMIT:
        return 'Gửi duyệt';
      case ReportActionType.APPROVE:
        return 'Phê duyệt';
      case ReportActionType.REJECT:
        return 'Từ chối';
    }
  }

  static ReportActionType fromString(String? value) {
    if (value == null) return ReportActionType.EDIT;
    return ReportActionType.values.firstWhere(
      (e) => e.name == value.toUpperCase(),
      orElse: () => ReportActionType.EDIT,
    );
  }
}

// ================================================================
// REPORT RESPONSE (List item)
// Backend: ReportResponse DTO
// GET /api/reports → PageResponse<ReportResponse>
// ================================================================

class ReportResponse {
  final int id;
  final ReportType type;
  final ReportStatus status;
  final int ownerId;
  final String ownerName;
  final ReportScope scope;
  final DateTime? generatedAt;
  final DateTime? submittedAt;
  final DateTime? periodStart;
  final DateTime? periodEnd;
  final int version;

  ReportResponse({
    required this.id,
    required this.type,
    required this.status,
    required this.ownerId,
    required this.ownerName,
    required this.scope,
    this.generatedAt,
    this.submittedAt,
    this.periodStart,
    this.periodEnd,
    required this.version,
  });

  factory ReportResponse.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      return DateTime.tryParse(val.toString());
    }

    return ReportResponse(
      id: json['id'] ?? 0,
      type: ReportType.fromString(json['type']),
      status: ReportStatus.fromString(json['status']),
      ownerId: json['ownerId'] ?? 0,
      ownerName: json['ownerName']?.toString() ?? '—',
      scope: ReportScope.fromString(json['scope']),
      generatedAt: parseDate(json['generatedAt']),
      submittedAt: parseDate(json['submittedAt']),
      periodStart: parseDate(json['periodStart']),
      periodEnd: parseDate(json['periodEnd']),
      version: json['version'] ?? 1,
    );
  }
}

// ================================================================
// REPORT DETAIL RESPONSE
// Backend: ReportDetailResponse DTO
// GET /api/reports/{id}
// ================================================================

class ReportDetailResponse {
  final int id;
  final ReportType type;
  final ReportStatus status;
  final String? dataJson;
  final String? editableJson;
  final String? comment;
  final String? reviewerComment;
  final int version;

  ReportDetailResponse({
    required this.id,
    required this.type,
    required this.status,
    this.dataJson,
    this.editableJson,
    this.comment,
    this.reviewerComment,
    required this.version,
  });

  factory ReportDetailResponse.fromJson(Map<String, dynamic> json) {
    return ReportDetailResponse(
      id: json['id'] ?? 0,
      type: ReportType.fromString(json['type']),
      status: ReportStatus.fromString(json['status']),
      dataJson: json['dataJson']?.toString(),
      editableJson: json['editableJson']?.toString(),
      comment: json['comment']?.toString(),
      reviewerComment: json['reviewerComment']?.toString(),
      version: json['version'] ?? 1,
    );
  }

  /// Parse snapshot data from dataJson into typed structure
  ReportSnapshotData? get snapshotData {
    if (dataJson == null || dataJson!.isEmpty) return null;
    try {
      return ReportSnapshotData.fromJsonString(dataJson!);
    } catch (e) {
      log('[ReportModel] snapshotData parse error: $e');
      return null;
    }
  }
}

// ================================================================
// REPORT VERSION RESPONSE
// Backend: ReportVersionResponse DTO
// GET /api/reports/{id}/versions
// ================================================================

class ReportVersionResponse {
  final int version;
  final ReportActionType actionType;
  final int changedBy;
  final String changedByName;
  final DateTime? changedAt;
  final String? editableJson;
  final String? comment;

  ReportVersionResponse({
    required this.version,
    required this.actionType,
    required this.changedBy,
    required this.changedByName,
    this.changedAt,
    this.editableJson,
    this.comment,
  });

  factory ReportVersionResponse.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      return DateTime.tryParse(val.toString());
    }

    return ReportVersionResponse(
      version: json['version'] ?? 1,
      actionType: ReportActionType.fromString(json['actionType']),
      changedBy: json['changedBy'] ?? 0,
      changedByName: json['changedByName']?.toString() ?? '—',
      changedAt: parseDate(json['changedAt']),
      editableJson: json['editableJson']?.toString(),
      comment: json['comment']?.toString(),
    );
  }
}

// ================================================================
// REPORT UPDATE REQUEST
// Backend: ReportUpdateRequest DTO
// PUT /api/reports/{id}
// ================================================================

class ReportUpdateRequest {
  final String? editableJson;
  final String? comment;

  ReportUpdateRequest({
    this.editableJson,
    this.comment,
  });

  Map<String, dynamic> toJson() {
    return {
      if (editableJson != null) 'editableJson': editableJson,
      if (comment != null) 'comment': comment,
    };
  }
}

// ================================================================
// REPORT SNAPSHOT DATA (parsed from dataJson)
// Backend: built by ReportService.buildSnapshot()
// ================================================================

class ReportSnapshotData {
  /// MENTOR report: summary + atRiskUsers
  final MentorSnapshot? mentor;

  /// PM report: totalUsers + completed + completionRate
  final PmSnapshot? pm;

  /// ADMIN report: totalUsers + totalCourses + completedUsers
  final AdminSnapshot? admin;

  ReportSnapshotData._({this.mentor, this.pm, this.admin});

  factory ReportSnapshotData.fromJsonString(String json) {
    final map = _parseJson(json);

    // Detect type by looking at keys
    if (map.containsKey('summary') && map.containsKey('atRiskUsers')) {
      return ReportSnapshotData._(
        mentor: MentorSnapshot.fromMap(map),
      );
    } else if (map.containsKey('totalUsers') && !map.containsKey('totalCourses')) {
      return ReportSnapshotData._(
        pm: PmSnapshot.fromMap(map),
      );
    } else if (map.containsKey('totalUsers') && map.containsKey('totalCourses')) {
      return ReportSnapshotData._(
        admin: AdminSnapshot.fromMap(map),
      );
    }

    return ReportSnapshotData._();
  }

  static Map<String, dynamic> _parseJson(String json) {
    if (json.isEmpty) return {};
    try {
      return Map<String, dynamic>.from(jsonDecode(json));
    } catch (_) {
      return {};
    }
  }
}

class MentorSnapshot {
  final int totalStudents;
  final int completedStudents;
  final double completionRate;
  final double avgScore;
  final List<AtRiskUser> atRiskUsers;

  MentorSnapshot({
    required this.totalStudents,
    required this.completedStudents,
    required this.completionRate,
    required this.avgScore,
    required this.atRiskUsers,
  });

  factory MentorSnapshot.fromMap(Map<String, dynamic> map) {
    final summary = map['summary'] as Map<String, dynamic>? ?? {};
    final atRiskList = map['atRiskUsers'] as List<dynamic>? ?? [];

    return MentorSnapshot(
      totalStudents: (summary['totalStudents'] ?? 0).toInt(),
      completedStudents: (summary['completedStudents'] ?? 0).toInt(),
      completionRate: (summary['completionRate'] ?? 0).toDouble(),
      avgScore: (summary['avgScore'] ?? 0).toDouble(),
      atRiskUsers: atRiskList
          .map((e) => AtRiskUser.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}

class PmSnapshot {
  final int totalUsers;
  final int completed;
  final double completionRate;

  PmSnapshot({
    required this.totalUsers,
    required this.completed,
    required this.completionRate,
  });

  factory PmSnapshot.fromMap(Map<String, dynamic> map) {
    return PmSnapshot(
      totalUsers: (map['totalUsers'] ?? 0).toInt(),
      completed: (map['completed'] ?? 0).toInt(),
      completionRate: (map['completionRate'] ?? 0).toDouble(),
    );
  }
}

class AdminSnapshot {
  final int totalUsers;
  final int totalCourses;
  final int completedUsers;

  AdminSnapshot({
    required this.totalUsers,
    required this.totalCourses,
    required this.completedUsers,
  });

  factory AdminSnapshot.fromMap(Map<String, dynamic> map) {
    return AdminSnapshot(
      totalUsers: (map['totalUsers'] ?? 0).toInt(),
      totalCourses: (map['totalCourses'] ?? 0).toInt(),
      completedUsers: (map['completedUsers'] ?? 0).toInt(),
    );
  }
}

class AtRiskUser {
  final int userId;
  final String? userName;
  final DateTime? deadline;
  final int? progress;

  AtRiskUser({
    required this.userId,
    this.userName,
    this.deadline,
    this.progress,
  });

  factory AtRiskUser.fromMap(Map<String, dynamic> map) {
    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      return DateTime.tryParse(val.toString());
    }

    return AtRiskUser(
      userId: (map['userId'] ?? 0).toInt(),
      userName: map['userName']?.toString(),
      deadline: parseDate(map['deadline']),
      progress: map['progress'] != null ? (map['progress']).toInt() : null,
    );
  }
}

// ================================================================
// PAGE RESPONSE WRAPPER
// Backend: base.api.lms_core.dto.user.PageResponse
// ================================================================

class PageResponse<T> {
  final List<T> data;
  final int page;
  final int size;
  final int totalPages;
  final int totalElements;

  PageResponse({
    required this.data,
    required this.page,
    required this.size,
    required this.totalPages,
    required this.totalElements,
  });

  factory PageResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    List<T> parseData(dynamic raw) {
      if (raw == null) return [];
      if (raw is List) {
        return raw
            .whereType<Map<String, dynamic>>()
            .map(fromJsonT)
            .toList();
      }
      return [];
    }

    int parseInt(dynamic val) {
      if (val == null) return 0;
      if (val is int) return val;
      return int.tryParse(val.toString()) ?? 0;
    }

    return PageResponse(
      data: parseData(json['data']),
      page: parseInt(json['page']),
      size: parseInt(json['size']),
      totalPages: parseInt(json['totalPages']),
      totalElements: parseInt(json['totalElements']),
    );
  }
}
