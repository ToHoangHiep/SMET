import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:smet/model/user_model.dart';
import 'package:smet/service/common/base_url.dart';
import 'package:smet/service/common/auth_service.dart';
import 'dart:developer';

class UserService {
  /// GET USER PROFILE — dùng cùng endpoint /auth/me như đăng nhập
  static Future<UserModel> getProfile() async {
    final userJson = await AuthService.getMe();
    return UserModel.fromJson(userJson);
  }

  /// UPDATE PROFILE
  static Future<UserModel> updateProfile({
    required String firstName,
    String? lastName,
    String? phone,
    required String email,
  }) async {
    final token = await AuthService.getToken();

    if (token == null) {
      throw Exception("Token not found");
    }

    final url = Uri.parse("$baseUrl/users/profile");

    final response = await http.put(
      url,
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "firstName": firstName,
        "lastName": lastName,
        "phone": phone,
        "email": email,
      }),
    );

    log("UPDATE PROFILE STATUS: ${response.statusCode}");
    log("UPDATE PROFILE BODY: ${response.body}");

    if (response.statusCode == 200) {
      return UserModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception("Cannot update profile");
    }
  }

  /// CHANGE PASSWORD
  static Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    final token = await AuthService.getToken();

    if (token == null) {
      throw Exception("Token not found");
    }

    final url = Uri.parse("$baseUrl/users/change-password");

    final response = await http.post(
      url,
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "oldPassword": oldPassword,
        "newPassword": newPassword,
      }),
    );

    log("CHANGE PASSWORD STATUS: ${response.statusCode}");
    log("CHANGE PASSWORD BODY: ${response.body}");

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      throw Exception(body["message"] ?? "Cannot change password");
    }
  }
}
