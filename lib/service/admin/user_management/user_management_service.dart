import 'dart:developer';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:smet/model/user_model.dart';
import 'package:smet/service/admin/user_management/user_management_rest_client.dart';
import 'package:smet/service/network/app_api_exception.dart';
import 'package:smet/service/network/app_dio.dart';

/// Facade quản lý user (admin): gọi [UserManagementRestClient] + [Dio] dùng chung,
/// xử lý multipart import ngoài Retrofit (generator 9.1.9).
class UserManagementApi {
  UserManagementApi({Dio? dio}) : _dio = dio ?? createAppDio() {
    _rest = UserManagementRestClient(_dio);
  }

  final Dio _dio;
  late final UserManagementRestClient _rest;

  /// Parse int từ response (backend có thể trả int, double, hoặc string).
  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  Map<String, dynamic> _mapListUserJson(Map<String, dynamic> responseData) {
    final List<dynamic> data = responseData['data'] ?? [];
    final totalElements = _parseInt(responseData['totalElements']) ?? 0;
    final totalPages = _parseInt(responseData['totalPages']) ?? 0;
    final page = _parseInt(responseData['page']) ?? 0;
    final size = _parseInt(responseData['size']) ?? 10;

    return {
      'users': data.map((e) => UserModel.fromJson(e as Map<String, dynamic>)).toList(),
      'page': page,
      'size': size,
      'totalElements': totalElements,
      'totalPages': totalPages,
    };
  }

  Map<String, dynamic> _mapListUserJsonContentFirst(
    Map<String, dynamic> data, {
    required int fallbackPage,
    required int fallbackSize,
  }) {
    final List<dynamic> content = data['content'] ?? data['data'] ?? [];

    return {
      'users': content.map((e) => UserModel.fromJson(e as Map<String, dynamic>)).toList(),
      'page': data['page'] ?? fallbackPage,
      'size': data['size'] ?? fallbackSize,
      'totalElements': data['totalElements'] ?? 0,
      'totalPages': data['totalPages'] ?? 0,
    };
  }

  /// ================= GET USERS =================
  Future<Map<String, dynamic>> getUsers({
    int page = 0,
    int size = 10,
    String? keyword,
    String? role,
    bool? isActive,
    int? departmentId,
  }) async {
    try {
      final raw = await _rest.listUsers(
        page: page,
        size: size,
        keyword: keyword,
        role: role,
        isActive: isActive,
        departmentId: departmentId,
      );
      if (raw is! Map) {
        throw AppApiException(message: 'Định dạng phản hồi danh sách user không hợp lệ.');
      }
      final responseData = Map<String, dynamic>.from(raw);
      return _mapListUserJson(responseData);
    } on DioException catch (e) {
      log('GET USERS ERROR: $e');
      throw AppApiException.fromDio(e);
    } catch (e, st) {
      log('GET USERS ERROR: $e', stackTrace: st);
      rethrow;
    }
  }

  /// ================= UPDATE USER =================
  Future<void> updateUser(UserModel user, {int? departmentId}) async {
    try {
      final body = <String, dynamic>{
        'firstName': user.firstName,
        'lastName': user.lastName,
        'email': user.email,
        'phone': user.phone,
        'role': user.role.name.toUpperCase(),
        'isActive': user.isActive,
      };

      if (departmentId != null) {
        body['departmentId'] = departmentId;
      }

      await _rest.updateUser(user.id, body);
    } on DioException catch (e) {
      log('UPDATE USER ERROR: $e');
      throw AppApiException.fromDio(e);
    }
  }

  /// ================= TOGGLE ACTIVE =================
  Future<void> toggleUserActive(int id) async {
    if (id == 0) {
      log('ERROR: USER ID IS INVALID');
      throw AppApiException(message: 'User id is invalid');
    }

    try {
      await _rest.toggleUserActive(id);
    } on DioException catch (e) {
      log('TOGGLE ACTIVE ERROR: $e');
      log('USER ID: $id');
      throw AppApiException.fromDio(e);
    }
  }

  /// ================= IMPORT EXCEL =================
  Future<void> importExcelFile(PlatformFile file) async {
    try {
      if (file.bytes == null) {
        throw AppApiException(message: 'File không có dữ liệu (bytes rỗng).');
      }

      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(file.bytes!, filename: file.name),
      });

      await _dio.post<dynamic>('/admin/import', data: formData);
    } on DioException catch (e) {
      log('IMPORT EXCEL ERROR: $e');
      throw AppApiException.fromDio(e);
    }
  }

  /// ================= DOWNLOAD TEMPLATE =================
  Future<Uint8List> downloadTemplate() async {
    try {
      final bytes = await _rest.downloadImportTemplate();
      return Uint8List.fromList(bytes);
    } on DioException catch (e) {
      throw AppApiException.fromDio(e);
    }
  }

  /// ================= CREATE USER =================
  Future<void> createUser(Map<String, dynamic> body) async {
    try {
      await _rest.register(body);
    } on DioException catch (e) {
      log('CREATE USER ERROR: $e');
      throw AppApiException.fromDio(e);
    }
  }

  /// ================= FIND USERS FOR DEPARTMENT =================
  Future<Map<String, dynamic>> findUsersForDepartment({
    String? keyword,
    String? role,
    int page = 0,
    int size = 10,
  }) async {
    try {
      final raw = await _rest.listUsers(
        page: page,
        size: size,
        keyword: keyword,
        role: role,
      );
      if (raw is! Map) {
        throw AppApiException(message: 'Định dạng phản hồi danh sách user không hợp lệ.');
      }
      final data = Map<String, dynamic>.from(raw);
      return _mapListUserJsonContentFirst(data, fallbackPage: page, fallbackSize: size);
    } on DioException catch (e) {
      log('FIND USERS FOR DEPARTMENT ERROR: $e');
      throw AppApiException.fromDio(e);
    }
  }

  /// Cùng endpoint với [findUsersForDepartment] — giữ API public cho tương thích.
  Future<Map<String, dynamic>> findUsersForDepartmentAssign({
    String? keyword,
    String? role,
    int page = 0,
    int size = 10,
  }) =>
      findUsersForDepartment(keyword: keyword, role: role, page: page, size: size);
}
