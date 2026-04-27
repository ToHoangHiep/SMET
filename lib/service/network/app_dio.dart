import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:smet/service/common/base_url.dart';
import 'package:smet/service/network/interceptors/auth_interceptor.dart';
import 'package:smet/service/network/interceptors/debug_log_interceptor.dart';
import 'package:smet/service/network/interceptors/error_interceptor.dart';

/// [Dio] dùng chung cho các client Retrofit (phase 1: user management).
///
/// Thứ tự: Auth → Debug log → Error (đăng ký sau cùng để [onError] chạy trước).
Dio createAppDio() {
  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 60),
      sendTimeout: const Duration(seconds: 60),
    ),
  );

  dio.interceptors.add(AuthInterceptor());
  dio.interceptors.add(ErrorInterceptor());
  if (kDebugMode) {
    // Đăng ký sau cùng → trên nhánh lỗi chạy trước, log status thô rồi chuyển tiếp.
    dio.interceptors.add(DebugLogInterceptor());
  }

  return dio;
}
