import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Chỉ log method + path + status (không log body) khi [kDebugMode].
class DebugLogInterceptor extends Interceptor {
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      // ignore: avoid_print
      print(
        '[Dio] ${response.requestOptions.method} '
        '${response.requestOptions.uri} → ${response.statusCode}',
      );
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      // ignore: avoid_print
      print(
        '[Dio] ERROR ${err.requestOptions.method} '
        '${err.requestOptions.uri} '
        'type=${err.type} code=${err.response?.statusCode}',
      );
    }
    handler.next(err);
  }
}
