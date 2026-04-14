import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:smet/service/common/base_url.dart';
import 'package:smet/model/pm_dashboard_models.dart';
import 'package:smet/service/common/auth_service.dart';
import 'dart:developer';

/// PM Dashboard Service
/// Backend endpoints:
///   GET /api/pm/dashboard              → PmDashboardSummary
///   GET /api/pm/dashboard/trends      → PmTrendData
///   GET /api/pm/dashboard/team        → PageResponse<UserCourseReview>
///   GET /api/pm/dashboard/risks       → PageResponse<PmRiskItem>
///   GET /api/pm/dashboard/insights    → List<DashboardInsight>
///   GET /api/pm/insights/{id}         → InsightDetail
///   GET /api/pm/insights/{id}/preview → InsightPreview
///   POST /api/pm/insights/{id}/execute → ExecuteAction
///   GET /api/courses                  → List<CourseOption> (for dropdown)
class PmDashboardService {
  static const String _baseUrl = '$baseUrl';

  // ============================================
  // TOKEN HELPERS
  // ============================================
  Future<Map<String, String>> _headers() async {
    final token = await AuthService.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  void _log(String label, dynamic msg) {
    log('[PmDashboardService] $label: $msg');
  }

  // ============================================
  // GET /api/pm/dashboard
  // Dashboard KPIs: totalUsers, activeCourses, completionRate, overdueCount, atRiskUsers
  // ============================================
  Future<PmDashboardSummary> getDashboard() async {
    try {
      _log('getDashboard', 'Fetching PM dashboard...');
      final headers = await _headers();
      final response = await http.get(
        Uri.parse('$_baseUrl/pm/dashboard'),
        headers: headers,
      );
      _log('getDashboard status', response.statusCode);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return PmDashboardSummary.fromJson(json);
      }
      throw Exception('Failed to load dashboard: ${response.statusCode}');
    } catch (e) {
      _log('getDashboard error', e);
      rethrow;
    }
  }

  // ============================================
  // GET /api/pm/dashboard/trends?from=&to=
  // Line chart data: enrollments vs completions over time
  // ============================================
  Future<PmTrendData> getTrends({DateTime? from, DateTime? to}) async {
    try {
      _log('getTrends', 'Fetching trend data...');
      final headers = await _headers();
      final params = <String, String>{};
      if (from != null) params['from'] = from.toIso8601String();
      if (to != null) params['to'] = to.toIso8601String();

      final uri = Uri.parse(
        '$_baseUrl/pm/dashboard/trends',
      ).replace(queryParameters: params.isEmpty ? null : params);

      final response = await http.get(uri, headers: headers);
      _log('getTrends status', response.statusCode);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return PmTrendData.fromJson(json);
      }
      throw Exception('Failed to load trends: ${response.statusCode}');
    } catch (e) {
      _log('getTrends error', e);
      rethrow;
    }
  }

  // ============================================
  // GET /api/pm/dashboard/team?courseId=&minScore=&page=&size=
  // Team performance — requires courseId
  // ============================================
  Future<PageResponse<UserCourseReview>> getTeamProgress({
    required int courseId,
    double? minScore,
    int page = 0,
    int size = 10,
  }) async {
    try {
      _log('getTeamProgress', 'courseId=$courseId, page=$page');
      final headers = await _headers();
      final params = <String, String>{
        'courseId': courseId.toString(),
        'page': page.toString(),
        'size': size.toString(),
      };
      if (minScore != null) params['minScore'] = minScore.toString();

      final uri = Uri.parse(
        '$_baseUrl/pm/dashboard/team',
      ).replace(queryParameters: params);

      final response = await http.get(uri, headers: headers);
      _log('getTeamProgress status', response.statusCode);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return PageResponse.fromJson(json, UserCourseReview.fromJson);
      }
      throw Exception('Failed to load team progress: ${response.statusCode}');
    } catch (e) {
      _log('getTeamProgress error', e);
      rethrow;
    }
  }

  // ============================================
  // GET /api/pm/dashboard/risks?page=&size=
  // Paginated list of at-risk users
  // ============================================
  Future<PageResponse<PmRiskItem>> getRisks({
    int page = 0,
    int size = 10,
  }) async {
    try {
      _log('getRisks', 'page=$page');
      final headers = await _headers();
      final params = <String, String>{
        'page': page.toString(),
        'size': size.toString(),
      };

      final uri = Uri.parse(
        '$_baseUrl/pm/dashboard/risks',
      ).replace(queryParameters: params);

      final response = await http.get(uri, headers: headers);
      _log('getRisks status', response.statusCode);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return PageResponse.fromJson(json, PmRiskItem.fromJson);
      }
      throw Exception('Failed to load risks: ${response.statusCode}');
    } catch (e) {
      _log('getRisks error', e);
      rethrow;
    }
  }

  // ============================================
  // GET /api/pm/dashboard/insights
  // All dashboard insights sorted by createdAt DESC
  // ============================================
  Future<List<DashboardInsight>> getInsights() async {
    try {
      _log('getInsights', 'Fetching insights...');
      final headers = await _headers();
      final response = await http.get(
        Uri.parse('$_baseUrl/pm/dashboard/insights'),
        headers: headers,
      );
      _log('getInsights status', response.statusCode);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json is List) {
          return json.map((e) => DashboardInsight.fromJson(e)).toList();
        }
        return [];
      }
      throw Exception('Failed to load insights: ${response.statusCode}');
    } catch (e) {
      _log('getInsights error', e);
      rethrow;
    }
  }

  // ============================================
  // GET /api/courses — for team progress course dropdown
  // ============================================
  Future<List<CourseOption>> getCourses({int page = 0, int size = 100}) async {
    try {
      _log('getCourses', 'Fetching course list...');
      final headers = await _headers();
      final uri = Uri.parse('$_baseUrl/lms/courses').replace(
        queryParameters: {'page': page.toString(), 'size': size.toString()},
      );

      final response = await http.get(uri, headers: headers);
      _log('getCourses status', response.statusCode);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final content = json['data'] as List? ?? [];
        return content.map((e) => CourseOption.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      _log('getCourses error', e);
      return [];
    }
  }

  // ============================================
  // GET /api/pm/insights/{id}
  // ============================================
  Future<InsightDetail> getInsightDetail(int insightId) async {
    try {
      _log('getInsightDetail', 'insightId=$insightId');
      final headers = await _headers();
      final response = await http.get(
        Uri.parse('$_baseUrl/pm/insights/$insightId'),
        headers: headers,
      );
      _log('getInsightDetail status', response.statusCode);
      if (response.statusCode == 200) {
        return InsightDetail.fromJson(jsonDecode(response.body));
      }
      throw Exception('Failed to load insight detail');
    } catch (e) {
      _log('getInsightDetail error', e);
      rethrow;
    }
  }

  // ============================================
  // GET /api/pm/insights/{id}/preview
  // ============================================
  Future<InsightPreview> getInsightPreview(int insightId) async {
    try {
      _log('getInsightPreview', 'insightId=$insightId');
      final headers = await _headers();
      final response = await http.get(
        Uri.parse('$_baseUrl/pm/insights/$insightId/preview'),
        headers: headers,
      );
      _log('getInsightPreview status', response.statusCode);
      if (response.statusCode == 200) {
        return InsightPreview.fromJson(jsonDecode(response.body));
      }
      throw Exception('Failed to load insight preview');
    } catch (e) {
      _log('getInsightPreview error', e);
      rethrow;
    }
  }

  // ============================================
  // POST /api/pm/insights/{id}/execute
  // Body: { actionType, message?, extendDays?, mentorId? }
  // ============================================
  Future<void> executeInsightAction({
    required int insightId,
    required String actionType,
    String? message,
    int? extendDays,
    int? mentorId,
  }) async {
    try {
      _log(
        'executeInsightAction',
        'insightId=$insightId, actionType=$actionType',
      );
      final headers = await _headers();
      final body = <String, dynamic>{'actionType': actionType};
      if (message != null && message.isNotEmpty) body['message'] = message;
      if (extendDays != null) body['extendDays'] = extendDays;
      if (mentorId != null) body['mentorId'] = mentorId;

      final response = await http.post(
        Uri.parse('$_baseUrl/pm/insights/$insightId/execute'),
        headers: headers,
        body: jsonEncode(body),
      );
      _log('executeInsightAction status', response.statusCode);
      if (response.statusCode != 200) {
        final err = jsonDecode(response.body);
        throw Exception(err['message'] ?? 'Failed to execute action');
      }
    } catch (e) {
      _log('executeInsightAction error', e);
      rethrow;
    }
  }
}

// ============================================
// SUPPORT DTOs
// ============================================

class CourseOption {
  final int id;
  final String title;

  CourseOption({required this.id, required this.title});

  factory CourseOption.fromJson(Map<String, dynamic> json) {
    return CourseOption(
      id: (json['id'] is int) ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      title: json['title'] ?? json['name'] ?? '',
    );
  }
}

class InsightDetail {
  final int id;
  final String insightKey;
  final String content;
  final String? actionLabel;
  final String? actionUrl;
  final DateTime createdAt;

  InsightDetail({
    required this.id,
    required this.insightKey,
    required this.content,
    this.actionLabel,
    this.actionUrl,
    required this.createdAt,
  });

  factory InsightDetail.fromJson(Map<String, dynamic> json) {
    return InsightDetail(
      id: _parseInt(json['id']),
      insightKey: json['insightKey'] ?? '',
      content: json['content'] ?? '',
      actionLabel: json['actionLabel'],
      actionUrl: json['actionUrl'],
      createdAt: _parseDateTime(json['createdAt']) ?? DateTime.now(),
    );
  }
}

class InsightPreview {
  final int affectedUsers;
  final int affectedCourses;
  final String description;

  InsightPreview({
    required this.affectedUsers,
    required this.affectedCourses,
    required this.description,
  });

  factory InsightPreview.fromJson(Map<String, dynamic> json) {
    return InsightPreview(
      affectedUsers: _parseInt(json['affectedUsers']),
      affectedCourses: _parseInt(json['affectedCourses']),
      description: json['description'] ?? '',
    );
  }
}

// ============================================
// UTILITIES
// ============================================
int _parseInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

DateTime? _parseDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String && value.isNotEmpty) {
    return DateTime.tryParse(value);
  }
  return null;
}
