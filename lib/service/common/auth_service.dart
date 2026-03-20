import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer';
import 'package:smet/model/user_model.dart';
import 'package:smet/service/common/base_url.dart';

class AuthService {
  /// LOGIN
  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    final url = Uri.parse("$baseUrl/auth/login");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email, "password": password}),
    );

    log("LOGIN STATUS: ${response.statusCode}");
    log("LOGIN BODY: ${response.body}");

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final token = data['accessToken'];

      await saveToken(token);

      return data;
    } else {
      try {
        final body = jsonDecode(response.body);
        throw Exception(body["message"] ?? "Login failed");
      } catch (e) {
        throw Exception("Login failed");
      }
    }
  }

  /// GET CURRENT USER (raw Map)
  static Future<Map<String, dynamic>> getMe() async {
    final token = await getToken();

    if (token == null) {
      throw Exception("Token not found");
    }

    final url = Uri.parse("$baseUrl/auth/me");

    final response = await http.get(
      url,
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    log("ME STATUS: ${response.statusCode}");
    log("ME BODY: ${response.body}");

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Cannot get user info");
    }
  }

  /// GET CURRENT USER (typed UserModel)
  static Future<UserModel> getCurrentUser() async {
    final data = await getMe();
    return UserModel.fromJson(data);
  }

  /// SAVE TOKEN
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("token", token);
  }

  /// GET TOKEN
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("token");
  }

  /// CHECK LOGIN
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;
  }

  /// LOGOUT
  static Future<void> logout() async {
    print("LOGOUT CALLED");
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("token");
    print("TOKEN REMOVED");
  }
}
