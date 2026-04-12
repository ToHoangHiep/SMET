import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smet/model/report_model.dart';
import 'package:smet/model/user_model.dart';
import 'package:smet/service/common/base_url.dart';

// ================================================================
// REPORT SERVICE
// Backend: base.api.report.controller.ReportController
//
// Endpoints:
//   POST   /api/reports                          - Generate report
//   GET    /api/reports                          - List (paginated, filtered)
//   GET    /api/reports/{id}                     - Detail
//   PUT    /api/reports/{id}                     - Update
//   POST   /api/reports/{id}/submit              - Submit
//   POST   /api/reports/{id}/approve             - Approve (ADMIN only)
//   POST   /api/reports/{id}/reject?comment=     - Reject (ADMIN only)
//   GET    /api/reports/{id}/versions            - Version history
//   GET    /api/reports/{id}/export?format=      - Export (pdf|excel|csv)
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

        return PageResponse.fromJson(map.cast<String, dynamic>(), ReportResponse.fromJson);
      }

      _log('listReports failed: HTTP ${res.statusCode}');
      throw _parseError(res);
    } catch (e) {
      _log('listReports error: $e');
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
    final body = ReportUpdateRequest(
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
  // POST /api/reports/{id}/approve
  // ============================================
  Future<void> approveReport(int id) async {
    final token = await _getToken();
    if (token == null) throw Exception('Token not found');

    final uri = Uri.parse('$baseUrl/reports/$id/approve');
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
  // POST /api/reports/{id}/reject?comment=
  // ============================================
  Future<void> rejectReport(int id, String comment) async {
    final token = await _getToken();
    if (token == null) throw Exception('Token not found');

    final uri = Uri.parse('$baseUrl/reports/$id/reject')
        .replace(queryParameters: {'comment': comment});

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
  // GET /api/reports/{id}/export?format=pdf|excel|csv
  // Returns binary bytes
  // ============================================
  Future<ExportResult> exportReport(int id, String format) async {
    final token = await _getToken();
    if (token == null) throw Exception('Token not found');

    final uri = Uri.parse('$baseUrl/reports/$id/export')
        .replace(queryParameters: {'format': format.toLowerCase()});

    _log('exportReport: $uri');

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
  // GENERATE REPORT (Create new report with snapshot)
  // POST /api/reports?type={type}&scopeId={id}
  // ============================================
  Future<ReportResponse> generateReport({
    required ReportType type,
    int? scopeId,
  }) async {
    final token = await _getToken();
    if (token == null) throw Exception('Token not found');

    final params = <String, String>{'type': type.name};
    if (scopeId != null) params['scopeId'] = scopeId.toString();

    final uri = Uri.parse('$baseUrl/reports').replace(queryParameters: params);

    _log('generateReport: $uri');

    try {
      final res = await http.post(uri, headers: _headers(token));

      if (res.statusCode == 200 || res.statusCode == 201) {
        final decoded = jsonDecode(res.body);
        _log('generateReport OK');
        return ReportResponse.fromJson(
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
