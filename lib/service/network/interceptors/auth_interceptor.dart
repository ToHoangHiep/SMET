import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smet/service/network/app_api_exception.dart';

/// Gắn Bearer token; không ghi đè Content-Type của multipart (FormData).
class AuthInterceptor extends QueuedInterceptor {
  static const _tokenKey = 'token';

  Future<String?> _readToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _readToken();
    if (token == null || token.isEmpty) {
      handler.reject(
        DioException(
          requestOptions: options,
          type: DioExceptionType.cancel,
          error: AppApiException.noToken(),
        ),
      );
      return;
    }

    options.headers['Authorization'] = 'Bearer $token';

    final isFormData = options.data is FormData;
    if (!isFormData) {
      options.headers['Content-Type'] = 'application/json';
    } else {
      options.headers.remove('Content-Type');
    }

    handler.next(options);
  }
}
