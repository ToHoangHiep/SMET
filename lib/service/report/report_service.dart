import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smet/model/report_model.dart';
import 'package:smet/model/user_model.dart';
import 'package:smet/service/common/auth_service.dart';
import 'package:smet/service/common/base_url.dart';

// ================================================================
// REPORT SERVICE
// Backend endpoints (role-based):
//   CreatorReportController (/api/reports):
//     POST   /api/reports                          - Generate report
//     GET    /api/reports                          - List (paginated, filtered)
//     GET    /api/reports/{id}                     - Detail
//     PUT    /api/reports/{id}                     - Update
//     POST   /api/reports/{id}/submit              - Submit
//     GET    /api/reports/{id}/versions            - Version history
//     GET    /api/reports/{id}/pm-detail           - PM report detail
//   AdminReportController (/api/admin/reports):
//     GET    /api/admin/reports                    - Admin list
//     GET    /api/admin/reports/{id}              - Admin detail
//     POST   /api/admin/reports/{id}/approve       - Approve
//     POST   /api/admin/reports/{id}/reject        - Reject
//     GET    /api/admin/reports/{id}/versions      - Admin version history
//     GET    /api/admin/reports/{id}/export        - Export (pdf|excel|csv)
// ================================================================

class ReportService {
  static void _log(String msg) {
    log('[ReportService] $msg');
  }

  // ============================================
  // Token helpers
  // ============================================
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Map<String, String> _headers(String token) {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // ============================================
  // LIST REPORTS
  // GET /api/reports
  // Role-based filtering (handled by backend):
  //   ADMIN  → all reports
  //   PM     → project reports
  //   MENTOR → course reports
  //   USER   → own reports
  // Default: last 7 days if no date filter
  // ============================================
  Future<PageResponse<ReportResponse>> listReports({
    ReportType? type,
    ReportStatus? status,
    int? ownerId,
    DateTime? fromDate,
    DateTime? toDate,
    int page = 0,
    int size = 10,
  }) async {
    final token = await _getToken();
    if (token == null) throw Exception('Token not found');

    final params = <String, String>{};
    if (type != null) params['type'] = type.name;
    if (status != null) params['status'] = status.name;
    if (ownerId != null) params['ownerId'] = ownerId.toString();
    if (fromDate != null) {
      params['fromDate'] = fromDate.toIso8601String();
    }
    if (toDate != null) {
      params['toDate'] = toDate.toIso8601String();
    }
    params['page'] = page.toString();
    params['size'] = size.toString();

    final uri = Uri.parse('$baseUrl/reports').replace(queryParameters: params);

    _log('listReports: $uri');

    try {
      final res = await http.get(uri, headers: _headers(token));

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final map = decoded is Map<String, dynamic> ? decoded : {};

        _log('listReports OK: ${map['totalElements'] ?? 0} total');

        return PageResponse.fromJson(
          map.cast<String, dynamic>(),
          ReportResponse.fromJson,
        );
      }

      _log('listReports failed: HTTP ${res.statusCode}');
      throw _parseError(res);
    } catch (e) {
      _log('listReports error: $e');
      rethrow;
    }
  }

  // ============================================
  // LIST ADMIN REPORTS
  // GET /api/admin/reports
  // ADMIN only — returns all submitted reports across the system
  // ============================================
  Future<PageResponse<ReportResponse>> listAdminReports({
    ReportType? type,
    ReportStatus? status,
    int? ownerId,
    DateTime? fromDate,
    DateTime? toDate,
    int page = 0,
    int size = 10,
  }) async {
    final token = await _getToken();
    if (token == null) throw Exception('Token not found');

    final params = <String, String>{};
    if (type != null) params['type'] = type.name;
    if (status != null) params['status'] = status.name;
    if (ownerId != null) params['ownerId'] = ownerId.toString();
    if (fromDate != null) {
      params['fromDate'] = fromDate.toIso8601String();
    }
    if (toDate != null) {
      params['toDate'] = toDate.toIso8601String();
    }
    params['page'] = page.toString();
    params['size'] = size.toString();

    final uri = Uri.parse(
      '$baseUrl/admin/reports',
    ).replace(queryParameters: params);

    _log('listAdminReports: $uri');

    try {
      final res = await http.get(uri, headers: _headers(token));

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final map = decoded is Map<String, dynamic> ? decoded : {};

        _log('listAdminReports OK: ${map['totalElements'] ?? 0} total');

        return PageResponse.fromJson(
          map.cast<String, dynamic>(),
          ReportResponse.fromJson,
        );
      }

      _log('listAdminReports failed: HTTP ${res.statusCode}');
      throw _parseError(res);
    } catch (e) {
      _log('listAdminReports error: $e');
      rethrow;
    }
  }

  // ============================================
  // GET REPORT DETAIL
  // GET /api/reports/{id}
  // ============================================
  Future<ReportDetailResponse> getReportDetail(int id) async {
    final token = await _getToken();
    if (token == null) throw Exception('Token not found');

    final uri = Uri.parse('$baseUrl/reports/$id');
    _log('getReportDetail: $uri');

    try {
      final res = await http.get(uri, headers: _headers(token));

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        _log('getReportDetail OK: id=$id');
        return ReportDetailResponse.fromJson(
          decoded is Map<String, dynamic> ? decoded : {},
        );
      }

      _log('getReportDetail failed: HTTP ${res.statusCode}');
      throw _parseError(res);
    } catch (e) {
      _log('getReportDetail error: $e');
      rethrow;
    }
  }

  // ============================================
  // GET ADMIN REPORT DETAIL
  // GET /api/admin/reports/{id}
  // Admin can view any report via /api/reports/{id} (backend checks role)
  // ============================================
  Future<ReportDetailResponse> getAdminReportDetail(int id) async {
    final token = await _getToken();
    if (token == null) throw Exception('Token not found');

    final uri = Uri.parse('$baseUrl/admin/reports/$id');
    _log('getAdminReportDetail: $uri');

    try {
      final res = await http.get(uri, headers: _headers(token));

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        _log('getAdminReportDetail OK: id=$id');
        return ReportDetailResponse.fromJson(
          decoded is Map<String, dynamic> ? decoded : {},
        );
      }

      _log('getAdminReportDetail failed: HTTP ${res.statusCode}');
      throw _parseError(res);
    } catch (e) {
      _log('getAdminReportDetail error: $e');
      rethrow;
    }
  }

  // ============================================
  // GET PM REPORT DETAIL
  // GET /api/reports/{id}/pm-detail
  // Returns enriched PM report with metrics, summary, history
  // ============================================
  Future<PmReportDetailResponse> getPmReportDetail(int id) async {
    final token = await _getToken();
    if (token == null) throw Exception('Token not found');

    final uri = Uri.parse('$baseUrl/reports/$id/pm-detail');
    _log('getPmReportDetail: $uri');

    try {
      final res = await http.get(uri, headers: _headers(token));

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        _log('getPmReportDetail OK: id=$id');
        return PmReportDetailResponse.fromJson(
          decoded is Map<String, dynamic> ? decoded : {},
        );
      }

      _log('getPmReportDetail failed: HTTP ${res.statusCode}');
      throw _parseError(res);
    } catch (e) {
      _log('getPmReportDetail error: $e');
      rethrow;
    }
  }

  // ============================================
  // UPDATE REPORT (Owner only, DRAFT only)
  // PUT /api/reports/{id}
  // ============================================
  Future<ReportDetailResponse> updateReport(
    int id, {
    String? editableJson,
    String? comment,
  }) async {
    final token = await _getToken();
    if (token == null) throw Exception('Token not found');

    final uri = Uri.parse('$baseUrl/reports/$id');
    final body =
        ReportUpdateRequest(
          editableJson: editableJson,
          comment: comment,
        ).toJson();

    _log('updateReport: $uri');

    try {
      final res = await http.put(
        uri,
        headers: _headers(token),
        body: jsonEncode(body),
      );

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        _log('updateReport OK: id=$id');
        return ReportDetailResponse.fromJson(
          decoded is Map<String, dynamic> ? decoded : {},
        );
      }

      _log('updateReport failed: HTTP ${res.statusCode}');
      throw _parseError(res);
    } catch (e) {
      _log('updateReport error: $e');
      rethrow;
    }
  }

  // ============================================
  // SUBMIT REPORT (Owner only, DRAFT only)
  // POST /api/reports/{id}/submit
  // ============================================
  Future<void> submitReport(int id) async {
    final token = await _getToken();
    if (token == null) throw Exception('Token not found');

    final uri = Uri.parse('$baseUrl/reports/$id/submit');
    _log('submitReport: $uri');

    try {
      final res = await http.post(uri, headers: _headers(token));

      if (res.statusCode == 200 || res.statusCode == 204) {
        _log('submitReport OK: id=$id');
        return;
      }

      _log('submitReport failed: HTTP ${res.statusCode}');
      throw _parseError(res);
    } catch (e) {
      _log('submitReport error: $e');
      rethrow;
    }
  }

  // ============================================
  // APPROVE REPORT (Admin only, SUBMITTED only)
  // POST /api/admin/reports/{id}/approve
  // ============================================
  Future<void> approveReport(int id) async {
    final token = await _getToken();
    if (token == null) throw Exception('Token not found');

    final uri = Uri.parse('$baseUrl/admin/reports/$id/approve');
    _log('approveReport: $uri');

    try {
      final res = await http.post(uri, headers: _headers(token));

      if (res.statusCode == 200 || res.statusCode == 204) {
        _log('approveReport OK: id=$id');
        return;
      }

      _log('approveReport failed: HTTP ${res.statusCode}');
      throw _parseError(res);
    } catch (e) {
      _log('approveReport error: $e');
      rethrow;
    }
  }

  // ============================================
  // REJECT REPORT (Admin only, SUBMITTED only)
  // POST /api/admin/reports/{id}/reject?comment=
  // ============================================
  Future<void> rejectReport(int id, String comment) async {
    final token = await _getToken();
    if (token == null) throw Exception('Token not found');

    final uri = Uri.parse(
      '$baseUrl/admin/reports/$id/reject',
    ).replace(queryParameters: {'comment': comment});

    _log('rejectReport: $uri');

    try {
      final res = await http.post(uri, headers: _headers(token));

      if (res.statusCode == 200 || res.statusCode == 204) {
        _log('rejectReport OK: id=$id');
        return;
      }

      _log('rejectReport failed: HTTP ${res.statusCode}');
      throw _parseError(res);
    } catch (e) {
      _log('rejectReport error: $e');
      rethrow;
    }
  }

  // ============================================
  // GET ADMIN VERSION HISTORY
  // GET /api/admin/reports/{id}/versions
  // ============================================
  Future<List<ReportVersionResponse>> getAdminReportVersions(int id) async {
    final token = await _getToken();
    if (token == null) throw Exception('Token not found');

    final uri = Uri.parse('$baseUrl/admin/reports/$id/versions');
    _log('getAdminReportVersions: $uri');

    try {
      final res = await http.get(uri, headers: _headers(token));

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final List<dynamic> list = decoded is List ? decoded : [];
        _log('getAdminReportVersions OK: ${list.length} versions');
        return list
            .whereType<Map<String, dynamic>>()
            .map((e) => ReportVersionResponse.fromJson(e))
            .toList();
      }

      _log('getAdminReportVersions failed: HTTP ${res.statusCode}');
      throw _parseError(res);
    } catch (e) {
      _log('getAdminReportVersions error: $e');
      rethrow;
    }
  }

  // ============================================
  // GET VERSION HISTORY
  // GET /api/reports/{id}/versions
  // ============================================
  Future<List<ReportVersionResponse>> getReportVersions(int id) async {
    final token = await _getToken();
    if (token == null) throw Exception('Token not found');

    final uri = Uri.parse('$baseUrl/reports/$id/versions');
    _log('getReportVersions: $uri');

    try {
      final res = await http.get(uri, headers: _headers(token));

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final List<dynamic> list = decoded is List ? decoded : [];
        _log('getReportVersions OK: ${list.length} versions');
        return list
            .whereType<Map<String, dynamic>>()
            .map((e) => ReportVersionResponse.fromJson(e))
            .toList();
      }

      _log('getReportVersions failed: HTTP ${res.statusCode}');
      throw _parseError(res);
    } catch (e) {
      _log('getReportVersions error: $e');
      rethrow;
    }
  }

  // ============================================
  // EXPORT REPORT
  // GET /api/admin/reports/{id}/export?format=pdf|excel|csv  ← ADMIN
  // GET /api/reports/{id}/export?format=pdf|excel|csv         ← MENTOR, PM, USER
  // ============================================
  Future<ExportResult> exportReport(int id, String format) async {
    final token = await _getToken();
    if (token == null) throw Exception('Token not found');

    // Xác định endpoint theo role — chỉ ADMIN dùng /admin/reports
    final user = await AuthService.getCurrentUser();
    final isAdmin = user.role == UserRole.ADMIN;
    final pathPrefix = isAdmin ? '$baseUrl/admin/reports' : '$baseUrl/reports';

    final uri = Uri.parse(
      '$pathPrefix/$id/export',
    ).replace(queryParameters: {'format': format.toLowerCase()});

    _log('exportReport: $uri (role=${user.role.name})');

    try {
      final res = await http.get(uri, headers: _headers(token));

      if (res.statusCode == 200 && res.bodyBytes.isNotEmpty) {
        _log('exportReport OK: $format, size=${res.bodyBytes.length}');
        return ExportResult(
          bytes: res.bodyBytes,
          format: format.toLowerCase(),
          fileName: 'report.$format',
        );
      }

      _log('exportReport failed: HTTP ${res.statusCode}');
      throw _parseError(res);
    } catch (e) {
      _log('exportReport error: $e');
      rethrow;
    }
  }

  // ============================================
  // DELETE DRAFT REPORT
  // DELETE /api/reports/{id}
  // Owner only, DRAFT only
  // ============================================
  Future<void> deleteDraftReport(int id) async {
    final token = await _getToken();
    if (token == null) throw Exception('Token not found');

    final uri = Uri.parse('$baseUrl/reports/$id');
    _log('deleteDraftReport: $uri');

    try {
      final res = await http.delete(uri, headers: _headers(token));

      if (res.statusCode == 200 || res.statusCode == 204) {
        _log('deleteDraftReport OK: id=$id');
        return;
      }

      _log('deleteDraftReport failed: HTTP ${res.statusCode}');
      throw _parseError(res);
    } catch (e) {
      _log('deleteDraftReport error: $e');
      rethrow;
    }
  }

  // ============================================
  // GENERATE REPORT (Create new report with snapshot)
  // POST /api/reports?type={type}&scopeId={id}
  // Returns ReportDetailResponse
  // Validation: if scopeId is null or <= 0, treat as "all" (send nothing)
  // ============================================
  Future<ReportDetailResponse> generateReport({
    required ReportType type,
    int? scopeId,
  }) async {
    final token = await _getToken();
    if (token == null) throw Exception('Token not found');

    final params = <String, String>{'type': type.name};
    // If scopeId is provided and > 0, include it; otherwise treat as "all"
    if (scopeId != null && scopeId > 0) {
      params['scopeId'] = scopeId.toString();
    }

    final uri = Uri.parse('$baseUrl/reports').replace(queryParameters: params);

    _log('generateReport: $uri');

    try {
      final res = await http.post(uri, headers: _headers(token));

      if (res.statusCode == 200 || res.statusCode == 201) {
        final decoded = jsonDecode(res.body);
        _log('generateReport OK');
        return ReportDetailResponse.fromJson(
          decoded is Map<String, dynamic> ? decoded : {},
        );
      }

      _log('generateReport failed: HTTP ${res.statusCode}');
      throw _parseError(res);
    } catch (e) {
      _log('generateReport error: $e');
      rethrow;
    }
  }

  // ============================================
  // Helpers
  // ============================================

  Exception _parseError(http.Response res) {
    try {
      final body = jsonDecode(res.body);
      final msg = body['message'] ?? body['error'] ?? 'Request failed';
      return Exception(msg);
    } catch (_) {
      return Exception('HTTP ${res.statusCode}');
    }
  }
}

// ================================================================
// EXPORT RESULT
// ================================================================

class ExportResult {
  final Uint8List bytes;
  final String format;
  final String fileName;

  ExportResult({
    required this.bytes,
    required this.format,
    required this.fileName,
  });

  String get mimeType {
    switch (format) {
      case 'pdf':
        return 'application/pdf';
      case 'excel':
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'csv':
        return 'text/csv';
      default:
        return 'application/octet-stream';
    }
  }
}

// ================================================================
// REPORT SERVICE PROVIDER (singleton)
// ================================================================

final reportService = ReportService();
