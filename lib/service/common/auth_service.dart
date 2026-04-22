import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer';
import 'package:smet/model/user_model.dart';
import 'package:smet/service/common/base_url.dart';
import 'package:smet/service/common/two_factor_service.dart';

/// Custom exception khi server yêu cầu đổi mật khẩu
class RequirePasswordChangeException implements Exception {
  final String message;
  final bool requirePasswordChange;

  RequirePasswordChangeException({
    required this.message,
    required this.requirePasswordChange,
  });

  @override
  String toString() => message;
}

class AuthService {
  /// Cached user — set sau khi getMe() được gọi thành công
  static UserModel? _cachedUser;

  /// Get cached user (sync, trả về null nếu chưa được cache)
  static UserModel? get currentUserCached => _cachedUser;

  /// LOGIN - trả về Map chứa:
  /// - accessToken: nếu login thành công (không có 2FA)
  /// - twoFactorRequired: true + email + rememberMe: nếu cần xác thực 2FA
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

      // Nếu có accessToken → login thành công (không có 2FA)
      if (data['accessToken'] != null) {
        final token = data['accessToken'];
        await saveToken(token);
        return data;
      }

      // Nếu có twoFactorRequired → cần xác thực 2FA
      if (data['twoFactorRequired'] == true) {
        return {
          'twoFactorRequired': true,
          'email': data['email'],
          'rememberMe': data['rememberMe'] ?? false,
          'requirePasswordChange': data['requirePasswordChange'] ?? false,
        };
      }

      // Trường hợp khác
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

  /// LOGIN WITH 2FA - xác thực mã 2FA sau khi đã xác thực credentials
  static Future<Map<String, dynamic>> loginWith2FA({
    required String email,
    required String code,
    bool rememberMe = false,
  }) async {
    return await TwoFactorService.loginWith2FA(
      email: email,
      code: code,
      rememberMe: rememberMe,
    );
  }

  /// GET CURRENT USER
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
    } else if (response.statusCode == 403) {
      // Server trả về 403 khi cần đổi mật khẩu
      try {
        final body = jsonDecode(response.body);
        throw RequirePasswordChangeException(
          message:
              body["message"] ?? "You must change password before continuing",
          requirePasswordChange: body["requirePasswordChange"] ?? true,
        );
      } catch (e) {
        if (e is RequirePasswordChangeException) rethrow;
        throw RequirePasswordChangeException(
          message: "You must change password before continuing",
          requirePasswordChange: true,
        );
      }
    } else {
      throw Exception("Cannot get user info");
    }
  }

  /// GET CURRENT USER (typed UserModel)
  static Future<UserModel> getCurrentUser() async {
    final data = await getMe();
    _cachedUser = UserModel.fromJson(data);
    return _cachedUser!;
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

  /// LOGOUT - gọi API backend rồi xóa local token
  static Future<void> logout() async {
    log("LOGOUT CALLED");
    final token = await getToken();

    // Gọi API logout phía server để invalidate token
    if (token != null) {
      try {
        final url = Uri.parse("$baseUrl/auth/logout");
        await http.post(
          url,
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
          },
        );
        log("LOGOUT API SUCCESS");
      } catch (e) {
        log("LOGOUT API FAILED: $e — vẫn xóa local token");
      }
    }

    // Xóa token local
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("token");
    _cachedUser = null;
    log("TOKEN REMOVED");
  }

  /// CHANGE PASSWORD (First Login - cần old password tạm thời)
  static Future<void> changePasswordFirstLogin({
    required String oldPassword,
    required String newPassword,
  }) async {
    final token = await getToken();

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

    if (response.statusCode == 200 || response.statusCode == 201) {
      return;
    } else {
      try {
        final body = jsonDecode(response.body);
        throw Exception(body["message"] ?? "Failed to change password");
      } catch (e) {
        if (e is Exception) rethrow;
        throw Exception("Failed to change password");
      }
    }
  }

  /// FORGOT PASSWORD - gui email dat lai mat khau
  /// POST /api/users/forgot-password
  /// Luon tra ve void, backend da handle email enumeration
  static Future<void> forgotPassword(String email) async {
    final url = Uri.parse("$baseUrl/users/forgot-password?email=$email");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
    );

    log("FORGOT PASSWORD STATUS: ${response.statusCode}");

    if (response.statusCode != 200) {
      try {
        final body = jsonDecode(response.body);
        throw Exception(body["message"] ?? "Failed to send reset email");
      } catch (e) {
        if (e is Exception) rethrow;
        throw Exception("Failed to send reset email");
      }
    }
  }

  /// RESET PASSWORD - dat lai mat khau bang token
  /// POST /api/users/reset-password (backend: @RequestParam)
  static Future<void> resetPassword(String token, String newPassword) async {
    final uri = Uri.parse("$baseUrl/users/reset-password").replace(
      queryParameters: {
        'token': token,
        'newPassword': newPassword,
      },
    );

    final response = await http.post(
      uri,
      headers: {"Content-Type": "application/json"},
    );

    log("RESET PASSWORD STATUS: ${response.statusCode}");
    log("RESET PASSWORD BODY: ${response.body}");

    if (response.statusCode == 200) {
      return;
    } else {
      try {
        final body = jsonDecode(response.body);
        throw Exception(body["message"] ?? "Failed to reset password");
      } catch (e) {
        if (e is Exception) rethrow;
        throw Exception("Failed to reset password");
      }
    }
  }

  /// VERIFY EMAIL - xac thuc email bang token
  /// GET /api/users/verify-email
  static Future<void> verifyEmail(String token) async {
    final url = Uri.parse("$baseUrl/users/verify-email?token=$token");

    final response = await http.get(
      url,
      headers: {"Content-Type": "application/json"},
    );

    log("VERIFY EMAIL STATUS: ${response.statusCode}");
    log("VERIFY EMAIL BODY: ${response.body}");

    if (response.statusCode == 200) {
      return;
    } else {
      try {
        final body = jsonDecode(response.body);
        throw Exception(body["message"] ?? "Failed to verify email");
      } catch (e) {
        if (e is Exception) rethrow;
        throw Exception("Failed to verify email");
      }
    }
  }
}
