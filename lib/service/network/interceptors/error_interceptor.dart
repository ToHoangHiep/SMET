import 'package:dio/dio.dart';
import 'package:smet/service/network/app_api_exception.dart';

/// Chuẩn hóa [DioException] thành [AppApiException] trong trường [DioException.error].
class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.error is AppApiException) {
      handler.reject(err);
      return;
    }

    final app = AppApiException.fromDio(err);
    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        response: err.response,
        type: err.type,
        message: app.message,
        error: app,
      ),
    );
  }
}
