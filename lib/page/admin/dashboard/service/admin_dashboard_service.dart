import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smet/service/common/base_url.dart';
import 'package:smet/page/admin/dashboard/models/admin_dashboard_models.dart';

class AdminDashboardApi {
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("token");
  }

  Map<String, String> _headers(String token) {
    return {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    };
  }

  void _logRequest(String title, String url) {
    log("========== $title REQUEST ==========");
    log("URL: $url");
  }

  void _logResponse(http.Response res) {
    log("STATUS: ${res.statusCode}");
    log("RESPONSE: ${res.body}");
    log("====================================");
  }
  
  String _buildUrl(String endpoint, {DateTime? from, DateTime? to}) {
    final uri = Uri.parse("$baseUrl/admin/dashboard/$endpoint");
    final params = <String, String>{};
    if (from != null) {
      params['from'] = from.toIso8601String();
    }
    if (to != null) {
      params['to'] = to.toIso8601String();
    }
    
    if (params.isNotEmpty) {
      return uri.replace(queryParameters: params).toString();
    }
    return uri.toString();
  }

  Future<DashboardSummary> getSummary({DateTime? from, DateTime? to}) async {
    try {
      final token = await _getToken();
      final url = _buildUrl('summary', from: from, to: to);
      _logRequest("GET SUMMARY", url);

      final res = await http.get(Uri.parse(url), headers: _headers(token!));
      _logResponse(res);

      if (res.statusCode == 200) {
        return DashboardSummary.fromJson(jsonDecode(utf8.decode(res.bodyBytes)));
      }
      throw Exception("Get summary failed");
    } catch (e) {
      log("GET SUMMARY ERROR: $e");
      rethrow;
    }
  }

  Future<DashboardTrend> getTrends({DateTime? from, DateTime? to}) async {
    try {
      final token = await _getToken();
      // Default to last 7 days if not provided
      final dateFrom = from ?? DateTime.now().subtract(const Duration(days: 7));
      final dateTo = to ?? DateTime.now();

      final url = _buildUrl('trends', from: dateFrom, to: dateTo);
      _logRequest("GET TRENDS", url);

      final res = await http.get(Uri.parse(url), headers: _headers(token!));
      _logResponse(res);

      if (res.statusCode == 200) {
        return DashboardTrend.fromJson(jsonDecode(utf8.decode(res.bodyBytes)));
      }
      throw Exception("Get trends failed");
    } catch (e) {
      log("GET TRENDS ERROR: $e");
      rethrow;
    }
  }

  Future<List<DashboardAlert>> getAlerts({DateTime? from, DateTime? to}) async {
    try {
      final token = await _getToken();
      final url = _buildUrl('alerts', from: from, to: to);
      _logRequest("GET ALERTS", url);

      final res = await http.get(Uri.parse(url), headers: _headers(token!));
      _logResponse(res);

      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(res.bodyBytes));
        return data.map((e) => DashboardAlert.fromJson(e)).toList();
      }
      throw Exception("Get alerts failed");
    } catch (e) {
      log("GET ALERTS ERROR: $e");
      rethrow;
    }
  }

  Future<DashboardPerformance> getPerformance({DateTime? from, DateTime? to}) async {
    try {
      final token = await _getToken();
      final url = _buildUrl('performance', from: from, to: to);
      _logRequest("GET PERFORMANCE", url);

      final res = await http.get(Uri.parse(url), headers: _headers(token!));
      _logResponse(res);

      if (res.statusCode == 200) {
        return DashboardPerformance.fromJson(jsonDecode(utf8.decode(res.bodyBytes)));
      }
      throw Exception("Get performance failed");
    } catch (e) {
      log("GET PERFORMANCE ERROR: $e");
      rethrow;
    }
  }

  Future<List<DashboardInsight>> getInsights({DateTime? from, DateTime? to}) async {
    try {
      final token = await _getToken();
      final url = _buildUrl('insights', from: from, to: to);
      _logRequest("GET INSIGHTS", url);

      final res = await http.get(Uri.parse(url), headers: _headers(token!));
      _logResponse(res);

      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(res.bodyBytes));
        return data.map((e) => DashboardInsight.fromJson(e)).toList();
      }
      throw Exception("Get insights failed");
    } catch (e) {
      log("GET INSIGHTS ERROR: $e");
      rethrow;
    }
  }
}
