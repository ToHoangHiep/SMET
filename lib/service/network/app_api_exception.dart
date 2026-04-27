import 'dart:convert';

import 'package:dio/dio.dart';

/// Lỗi API thống nhất (từ Dio / interceptor / parse server).
class AppApiException implements Exception {
  AppApiException({
    required this.message,
    this.statusCode,
    this.dioType,
    this.serverMessage,
  });

  final String message;
  final int? statusCode;
  final DioExceptionType? dioType;
  final String? serverMessage;

  factory AppApiException.noToken() => AppApiException(
        message:
            'Phiên đăng nhập không hợp lệ. Vui lòng đăng nhập lại.',
        statusCode: null,
        dioType: null,
      );

  /// Bóc từ [DioException] sau interceptor (hoặc khi chưa bọc).
  factory AppApiException.fromDio(DioException e) {
    final inner = e.error;
    if (inner is AppApiException) {
      return inner;
    }

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return AppApiException(
          message: 'Hết thời gian chờ kết nối. Vui lòng thử lại.',
          statusCode: e.response?.statusCode,
          dioType: e.type,
        );
      case DioExceptionType.connectionError:
        return AppApiException(
          message:
              'Không thể kết nối tới máy chủ. Kiểm tra mạng và thử lại.',
          statusCode: e.response?.statusCode,
          dioType: e.type,
        );
      case DioExceptionType.badResponse:
        final code = e.response?.statusCode;
        final serverMsg = _parseServerMessage(e.response?.data);
        final friendly = _friendlyHttpStatus(code, serverMsg);
        return AppApiException(
          message: friendly,
          statusCode: code,
          dioType: e.type,
          serverMessage: serverMsg,
        );
      case DioExceptionType.cancel:
        return AppApiException(
          message: e.message ?? 'Yêu cầu đã bị hủy.',
          statusCode: e.response?.statusCode,
          dioType: e.type,
        );
      case DioExceptionType.badCertificate:
        return AppApiException(
          message: 'Lỗi chứng chỉ bảo mật (SSL).',
          statusCode: e.response?.statusCode,
          dioType: e.type,
        );
      case DioExceptionType.unknown:
        return AppApiException(
          message: e.message ?? 'Đã xảy ra lỗi không xác định.',
          statusCode: e.response?.statusCode,
          dioType: e.type,
        );
    }
  }

  static String? _parseServerMessage(dynamic data) {
    if (data == null) return null;
    if (data is Map) {
      final m = data['message'] ?? data['error'] ?? data['detail'];
      if (m != null) return m.toString();
    }
    if (data is String) {
      final trimmed = data.trim();
      if (trimmed.isEmpty) return null;
      try {
        final decoded = jsonDecode(trimmed);
        if (decoded is Map) {
          return _parseServerMessage(decoded);
        }
      } catch (_) {
        if (trimmed.length <= 500) return trimmed;
        return '${trimmed.substring(0, 500)}…';
      }
    }
    return null;
  }

  static String _friendlyHttpStatus(int? code, String? server) {
    if (server != null && server.isNotEmpty) {
      return server;
    }
    switch (code) {
      case 400:
        return 'Yêu cầu không hợp lệ (400).';
      case 401:
        return 'Không được phép truy cập. Vui lòng đăng nhập lại (401).';
      case 403:
        return 'Bạn không có quyền thực hiện thao tác này (403).';
      case 404:
        return 'Không tìm thấy tài nguyên (404).';
      case 409:
        return 'Xung đột dữ liệu (409).';
      case 422:
        return 'Dữ liệu không hợp lệ (422).';
      case 500:
      case 502:
      case 503:
        return 'Máy chủ đang gặp sự cố ($code). Vui lòng thử lại sau.';
      default:
        return 'Yêu cầu thất bại${code != null ? ' ($code)' : ''}.';
    }
  }

  @override
  String toString() => message;
}
