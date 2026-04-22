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
  MENTOR_MONTHLY,
  MENTOR_QUARTERLY,
  PM_MONTHLY,
  PM_QUARTERLY,
  ADMIN_MONTHLY,
  ADMIN_QUARTERLY;

  String get displayName {
    switch (this) {
      case ReportType.MENTOR_MONTHLY:
        return 'Báo cáo tháng - Mentor';
      case ReportType.MENTOR_QUARTERLY:
        return 'Báo cáo quý - Mentor';
      case ReportType.PM_MONTHLY:
        return 'Báo cáo tháng - Quản lý dự án';
      case ReportType.PM_QUARTERLY:
        return 'Báo cáo quý - Quản lý dự án';
      case ReportType.ADMIN_MONTHLY:
        return 'Báo cáo tháng - Quản trị';
      case ReportType.ADMIN_QUARTERLY:
        return 'Báo cáo quý - Quản trị';
    }
  }

  String get shortName {
    switch (this) {
      case ReportType.MENTOR_MONTHLY:
        return 'Mentor Tháng';
      case ReportType.MENTOR_QUARTERLY:
        return 'Mentor Quý';
      case ReportType.PM_MONTHLY:
        return 'PM Tháng';
      case ReportType.PM_QUARTERLY:
        return 'PM Quý';
      case ReportType.ADMIN_MONTHLY:
        return 'Admin Tháng';
      case ReportType.ADMIN_QUARTERLY:
        return 'Admin Quý';
    }
  }

  static ReportType fromString(String? value) {
    if (value == null) return ReportType.MENTOR_MONTHLY;
    return ReportType.values.firstWhere(
      (e) => e.name == value.toUpperCase(),
      orElse: () => ReportType.MENTOR_MONTHLY,
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
  REJECT,
  DELETE;

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
      case ReportActionType.DELETE:
        return 'Xóa';
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
  final int? scopeId;
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
    this.scopeId,
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
      scopeId:
          json['scopeId'] != null && (json['scopeId'] as num).toInt() > 0
              ? (json['scopeId'] as num).toInt()
              : null,
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
  final int? scopeId;
  final int? ownerId;
  final String? ownerName;
  final ReportScope? scope;
  final DateTime? generatedAt;
  final DateTime? submittedAt;
  final DateTime? reviewedAt;
  final DateTime? periodStart;
  final DateTime? periodEnd;
  final int version;

  ReportDetailResponse({
    required this.id,
    required this.type,
    required this.status,
    this.dataJson,
    this.editableJson,
    this.comment,
    this.reviewerComment,
    this.scopeId,
    this.periodStart,
    this.periodEnd,
    required this.version,
    this.ownerId,
    this.ownerName,
    this.scope,
    this.generatedAt,
    this.submittedAt,
    this.reviewedAt,
  });

  factory ReportDetailResponse.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      return DateTime.tryParse(val.toString());
    }

    return ReportDetailResponse(
      id: json['id'] != null ? (json['id'] as num).toInt() : 0,
      type: ReportType.fromString(json['type']?.toString()),
      status: ReportStatus.fromString(json['status']?.toString()),
      dataJson: json['dataJson']?.toString(),
      editableJson: json['editableJson']?.toString(),
      comment: json['comment']?.toString(),
      reviewerComment: json['reviewerComment']?.toString(),
      scopeId:
          json['scopeId'] != null && (json['scopeId'] as num).toInt() > 0
              ? (json['scopeId'] as num).toInt()
              : null,
      periodStart: parseDate(json['periodStart']),
      periodEnd: parseDate(json['periodEnd']),
      version: json['version'] != null ? (json['version'] as num).toInt() : 1,
      ownerId:
          json['ownerId'] != null ? (json['ownerId'] as num).toInt() : null,
      ownerName: json['ownerName']?.toString(),
      scope: ReportScope.fromString(json['scope']?.toString()),
      generatedAt: parseDate(json['generatedAt']),
      submittedAt: parseDate(json['submittedAt']),
      reviewedAt: parseDate(json['reviewedAt']),
    );
  }

  ReportSnapshotData? get snapshotData {
    // Prefer editableJson over dataJson so the UI shows the latest user edits.
    final source = editableJson != null && editableJson!.isNotEmpty
        ? editableJson
        : dataJson;
    if (source == null || source.isEmpty) return null;
    try {
      return ReportSnapshotData.fromJsonString(source);
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

  ReportUpdateRequest({this.editableJson, this.comment});

  Map<String, dynamic> toJson() {
    return {
      if (editableJson != null) 'editableJson': editableJson,
      if (comment != null) 'comment': comment,
    };
  }
}

// ================================================================
// REPORT SNAPSHOT DATA (parsed from dataJson)
// Backend: built by ReportService.buildPmReport / buildMentorReport / buildAdminReport
// Backend dataJson keys:
//   MENTOR  → assignedProjects, completedCourses, inProgressCourses, notStartedCourses, reportName
//   PM      → totalProjects, completedProjects, completedCourses, inProgressCourses, notStartedCourses, reportName
//   ADMIN   → totalUsers, totalProjects, completedCourses, inProgressCourses, notStartedCourses, reportName
// ================================================================

class ReportSnapshotData {
  final int? assignedProjects;
  final int? totalProjects;
  final int? completedProjects;
  final int? totalUsers;
  final int? completedCourses;
  final int? inProgressCourses;
  final int? notStartedCourses;
  final String? reportName;

  ReportSnapshotData._({
    this.assignedProjects,
    this.totalProjects,
    this.completedProjects,
    this.totalUsers,
    this.completedCourses,
    this.inProgressCourses,
    this.notStartedCourses,
    this.reportName,
  });

  /// Detect report role from data keys and return typed snapshot.
  factory ReportSnapshotData.fromJsonString(String json) {
    final map = _parseJson(json);
    if (map.isEmpty) return ReportSnapshotData._();

    // ADMIN: has totalUsers
    if (map.containsKey('totalUsers') && map['totalUsers'] != null) {
      return ReportSnapshotData._(
        totalUsers: _toInt(map['totalUsers']),
        totalProjects: _toInt(map['totalProjects']),
        completedCourses: _toInt(map['completedCourses']),
        inProgressCourses: _toInt(map['inProgressCourses']),
        notStartedCourses: _toInt(map['notStartedCourses']),
        reportName: map['reportName']?.toString(),
      );
    }

    // PM: has completedProjects (mentor does not)
    if (map.containsKey('completedProjects') && map['completedProjects'] != null) {
      return ReportSnapshotData._(
        totalProjects: _toInt(map['totalProjects']),
        completedProjects: _toInt(map['completedProjects']),
        completedCourses: _toInt(map['completedCourses']),
        inProgressCourses: _toInt(map['inProgressCourses']),
        notStartedCourses: _toInt(map['notStartedCourses']),
        reportName: map['reportName']?.toString(),
      );
    }

    // MENTOR: has assignedProjects
    return ReportSnapshotData._(
      assignedProjects: _toInt(map['assignedProjects']),
      completedCourses: _toInt(map['completedCourses']),
      inProgressCourses: _toInt(map['inProgressCourses']),
      notStartedCourses: _toInt(map['notStartedCourses']),
      reportName: map['reportName']?.toString(),
    );
  }

  static int _toInt(dynamic val) {
    if (val == null) return 0;
    if (val is int) return val;
    if (val is num) return val.toInt();
    return int.tryParse(val.toString()) ?? 0;
  }

  static Map<String, dynamic> _parseJson(String json) {
    if (json.isEmpty) return {};
    try {
      return Map<String, dynamic>.from(jsonDecode(json));
    } catch (_) {
      return {};
    }
  }

  bool get isMentor => assignedProjects != null && completedProjects == null && totalUsers == null;
  bool get isPm => completedProjects != null;
  bool get isAdmin => totalUsers != null;

  int get totalCourses => (completedCourses ?? 0) + (inProgressCourses ?? 0) + (notStartedCourses ?? 0);

  double get completionRate {
    final total = totalCourses;
    if (total == 0) return 0;
    return ((completedCourses ?? 0) / total * 100 * 100).round() / 100;
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
        return raw.whereType<Map<String, dynamic>>().map(fromJsonT).toList();
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

// ================================================================
// PM REPORT DETAIL RESPONSE
// Backend: PmReportDetailResponse DTO
// GET /api/reports/{id}/pm-detail
// ================================================================

class PmReportDetailResponse {
  final int id;
  final String name;
  final String? type;
  final String? scope;
  final int? scopeId;
  final String? ownerName;
  final String? departmentName;
  final String? status;
  final DateTime? periodStart;
  final DateTime? periodEnd;
  final Map<String, dynamic>? metrics;
  final Map<String, dynamic>? summary;
  final dynamic data;
  final String? comment;
  final String? reviewerComment;
  final List<PmReportHistoryEntry>? history;

  PmReportDetailResponse({
    required this.id,
    required this.name,
    this.type,
    this.scope,
    this.scopeId,
    this.ownerName,
    this.departmentName,
    this.status,
    this.periodStart,
    this.periodEnd,
    this.metrics,
    this.summary,
    this.data,
    this.comment,
    this.reviewerComment,
    this.history,
  });

  factory PmReportDetailResponse.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      return DateTime.tryParse(val.toString());
    }

    List<PmReportHistoryEntry> parseHistory(dynamic raw) {
      if (raw == null) return [];
      if (raw is List) {
        return raw
            .whereType<Map<String, dynamic>>()
            .map((e) => PmReportHistoryEntry.fromJson(e))
            .toList();
      }
      return [];
    }

    return PmReportDetailResponse(
      id: json['id'] != null ? (json['id'] as num).toInt() : 0,
      name: json['name']?.toString() ?? '—',
      type: json['type']?.toString(),
      scope: json['scope']?.toString(),
      scopeId:
          json['scopeId'] != null && (json['scopeId'] as num).toInt() > 0
              ? (json['scopeId'] as num).toInt()
              : null,
      ownerName: json['ownerName']?.toString(),
      departmentName: json['departmentName']?.toString(),
      status: json['status']?.toString(),
      periodStart: parseDate(json['periodStart']),
      periodEnd: parseDate(json['periodEnd']),
      metrics: json['metrics'] is Map<String, dynamic>
          ? json['metrics'] as Map<String, dynamic>
          : null,
      summary: json['summary'] is Map<String, dynamic>
          ? json['summary'] as Map<String, dynamic>
          : null,
      data: json['data'],
      comment: json['comment']?.toString(),
      reviewerComment: json['reviewerComment']?.toString(),
      history: parseHistory(json['history']),
    );
  }

  double get completionRate {
    if (metrics == null) return 0;
    final val = metrics!['completionRate'];
    if (val == null) return 0;
    if (val is double) return val;
    if (val is int) return val.toDouble();
    return double.tryParse(val.toString()) ?? 0;
  }

  String get riskLevel {
    return summary?['riskLevel']?.toString() ?? 'UNKNOWN';
  }

  String get summaryText {
    return summary?['summaryText']?.toString() ?? '';
  }

  int get totalUsers => metrics?['totalUsers']?.toInt() ?? 0;
  int get completedUsers => metrics?['completedUsers']?.toInt() ?? 0;
  int get overdueUsers => metrics?['overdueUsers']?.toInt() ?? 0;
  int get inactiveUsers => metrics?['inactiveUsers']?.toInt() ?? 0;
  double get avgScore => (metrics?['avgScore'] ?? 0).toDouble();
  int get riskUsers => metrics?['riskUsers']?.toInt() ?? 0;
}

// ================================================================
// PM REPORT HISTORY ENTRY
// Backend: ReportHistoryDto
// ================================================================

class PmReportHistoryEntry {
  final int version;
  final String action;
  final DateTime? changedAt;
  final String? changedBy;

  PmReportHistoryEntry({
    required this.version,
    required this.action,
    this.changedAt,
    this.changedBy,
  });

  factory PmReportHistoryEntry.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      return DateTime.tryParse(val.toString());
    }

    return PmReportHistoryEntry(
      version: json['version'] ?? 1,
      action: json['action']?.toString() ?? '—',
      changedAt: parseDate(json['changedAt']),
      changedBy: json['changedBy']?.toString(),
    );
  }
}

