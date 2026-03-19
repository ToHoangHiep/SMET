import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:smet/service/common/base_url.dart';
import 'package:smet/service/common/auth_service.dart';
import 'dart:developer';

class TwoFactorService {
  /// Toggle 2FA - bật hoặc tắt xác thực hai yếu tố
  /// Nếu đang bật → sẽ tắt
  /// Nếu đang tắt → sẽ bắt đầu setup và trả về QR code
  static Future<TwoFactorToggleResponse> toggle2FA() async {
    final token = await AuthService.getToken();

    if (token == null) {
      throw Exception("Token not found");
    }

    final url = Uri.parse("$baseUrl/auth/toggle-2fa");

    final response = await http.post(
      url,
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    log("TOGGLE 2FA STATUS: ${response.statusCode}");
    log("TOGGLE 2FA BODY: ${response.body}");

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return TwoFactorToggleResponse.fromJson(data);
    } else {
      try {
        final body = jsonDecode(response.body);
        throw Exception(body["message"] ?? "Failed to toggle 2FA");
      } catch (e) {
        throw Exception("Failed to toggle 2FA");
      }
    }
  }

  /// Confirm 2FA - xác nhận mã để kích hoạt 2FA
  static Future<TwoFactorConfirmResponse> confirm2FA(String code) async {
    final token = await AuthService.getToken();

    if (token == null) {
      throw Exception("Token not found");
    }

    final url = Uri.parse("$baseUrl/auth/confirm-2fa");

    final response = await http.post(
      url,
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({"code": code}),
    );

    log("CONFIRM 2FA STATUS: ${response.statusCode}");
    log("CONFIRM 2FA BODY: ${response.body}");

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return TwoFactorConfirmResponse.fromJson(data);
    } else {
      try {
        final body = jsonDecode(response.body);
        throw Exception(body["message"] ?? "Invalid verification code");
      } catch (e) {
        throw Exception("Invalid verification code");
      }
    }
  }

  /// Login với 2FA code - xác thực mã khi đăng nhập
  static Future<Map<String, dynamic>> loginWith2FA({
    required String email,
    required String code,
    bool rememberMe = false,
  }) async {
    final url = Uri.parse("$baseUrl/auth/login-2fa");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "email": email,
        "code": code,
        "rememberMe": rememberMe,
      }),
    );

    log("LOGIN 2FA STATUS: ${response.statusCode}");
    log("LOGIN 2FA BODY: ${response.body}");

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final token = data['accessToken'];

      if (token != null) {
        await AuthService.saveToken(token);
      }

      return data;
    } else {
      try {
        final body = jsonDecode(response.body);
        throw Exception(body["message"] ?? "Invalid verification code");
      } catch (e) {
        throw Exception("Invalid verification code");
      }
    }
  }
}

/// Response model cho toggle-2fa endpoint
class TwoFactorToggleResponse {
  final bool twoFactorEnabled;
  final bool? setupRequired;
  final String? qrCode; // Base64 encoded QR code image
  final String? message;

  TwoFactorToggleResponse({
    required this.twoFactorEnabled,
    this.setupRequired,
    this.qrCode,
    this.message,
  });

  factory TwoFactorToggleResponse.fromJson(Map<String, dynamic> json) {
    return TwoFactorToggleResponse(
      twoFactorEnabled: json['twoFactorEnabled'] ?? false,
      setupRequired: json['setupRequired'],
      qrCode: json['qrCode']?.toString(),
      message: json['message']?.toString(),
    );
  }

  bool get needsSetup => setupRequired == true && qrCode != null;
}

/// Response model cho confirm-2fa endpoint
class TwoFactorConfirmResponse {
  final bool twoFactorEnabled;
  final String? message;

  TwoFactorConfirmResponse({
    required this.twoFactorEnabled,
    this.message,
  });

  factory TwoFactorConfirmResponse.fromJson(Map<String, dynamic> json) {
    return TwoFactorConfirmResponse(
      twoFactorEnabled: json['twoFactorEnabled'] ?? false,
      message: json['message']?.toString(),
    );
  }
}
