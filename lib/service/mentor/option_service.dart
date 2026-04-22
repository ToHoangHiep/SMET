import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smet/model/learning_path_model.dart';
import 'package:smet/model/option_model.dart';
import 'package:smet/service/common/base_url.dart';

class MentorOptionService {
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

  Future<OptionModel> createOption(OptionModel option) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception("No auth token found. Please login again.");
    }

    final response = await http.post(
      Uri.parse("$baseUrl/lms/options"),
      headers: _headers(token),
      body: jsonEncode(option.toJson()),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return OptionModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception("Create option failed: ${response.body}");
    }
  }

  Future<OptionModel> updateOption(Long optionId, OptionModel option) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception("No auth token found. Please login again.");
    }

    final response = await http.put(
      Uri.parse("$baseUrl/lms/options/${optionId.value}"),
      headers: _headers(token),
      body: jsonEncode(option.toJson()),
    );

    if (response.statusCode == 200) {
      return OptionModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception("Update option failed: ${response.body}");
    }
  }

  Future<OptionModel> getOptionById(Long optionId) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception("No auth token found. Please login again.");
    }

    final response = await http.get(
      Uri.parse("$baseUrl/lms/options/${optionId.value}"),
      headers: _headers(token),
    );

    if (response.statusCode == 200) {
      return OptionModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception("Get option failed: ${response.body}");
    }
  }

  Future<List<OptionModel>> getOptionsByQuestion(Long questionId) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception("No auth token found. Please login again.");
    }

    final response = await http.get(
      Uri.parse("$baseUrl/lms/options/question/${questionId.value}"),
      headers: _headers(token),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => OptionModel.fromJson(e)).toList();
    } else {
      throw Exception("Get options by question failed: ${response.body}");
    }
  }

  Future<void> deleteOption(Long optionId) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception("No auth token found. Please login again.");
    }

    final response = await http.delete(
      Uri.parse("$baseUrl/lms/options/${optionId.value}"),
      headers: _headers(token),
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception("Delete option failed: ${response.body}");
    }
  }
}