import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:smet/model/department_model.dart';
import 'package:smet/service/admin/department_management/department_rest_client.dart';
import 'package:smet/service/network/app_api_exception.dart';
import 'package:smet/service/network/app_dio.dart';

class DepartmentService {
  DepartmentService({Dio? dio}) : _dio = dio ?? createAppDio() {
    _rest = DepartmentRestClient(_dio);
  }

  final Dio _dio;
  late final DepartmentRestClient _rest;

  static bool _isBadResponse(DioException e) =>
      e.type == DioExceptionType.badResponse;

  /// ================= CREATE =================
  /// POST /api/departments/createDepartment
  Future<DepartmentModel> createDepartment({
    required String name,
    required String code,
    bool isActive = true,
    int? projectManagerId,
    List<int>? mentorIds,
    List<int>? userIds,
  }) async {
    try {
      final body = <String, dynamic>{
        'name': name,
        'code': code,
        'isActive': isActive,
        if (projectManagerId != null) 'projectManagerId': projectManagerId,
        if (mentorIds != null && mentorIds.isNotEmpty) 'mentorIds': mentorIds,
        if (userIds != null && userIds.isNotEmpty) 'userIds': userIds,
      };

      final raw = await _rest.createDepartment(body);
      if (raw is! Map<String, dynamic>) {
        throw AppApiException(
          message: 'Định dạng phản hồi tạo phòng ban không hợp lệ.',
        );
      }
      return DepartmentModel.fromJson(raw);
    } on DioException catch (e) {
      log('CREATE DEPARTMENT ERROR: $e');
      throw AppApiException.fromDio(e);
    }
  }

  /// ================= UPDATE =================
  /// PATCH /api/departments/{id}
  Future<DepartmentModel?> updateDepartment({
    required int id,
    required String name,
    required String code,
    required bool isActive,
    int? projectManagerId,
    List<int>? mentorIds,
    List<int>? userIds,
  }) async {
    try {
      final body = <String, dynamic>{
        'name': name,
        'code': code,
        'isActive': isActive,
        if (projectManagerId != null) 'projectManagerId': projectManagerId,
        if (mentorIds != null && mentorIds.isNotEmpty) 'mentorIds': mentorIds,
        if (userIds != null && userIds.isNotEmpty) 'userIds': userIds,
      };

      final raw = await _rest.patchDepartment(id, body);
      if (raw is! Map<String, dynamic>) {
        log('UPDATE DEPARTMENT FAILED - unexpected body type');
        return null;
      }
      return DepartmentModel.fromJson(raw);
    } on DioException catch (e) {
      if (_isBadResponse(e)) {
        log(
          'UPDATE DEPARTMENT FAILED - Status: ${e.response?.statusCode}, '
          'Body: ${e.response?.data}',
        );
        return null;
      }
      log('UPDATE DEPARTMENT ERROR: $e');
      throw AppApiException.fromDio(e);
    }
  }

  /// ================= DELETE =================
  /// DELETE /api/departments/{id}?force=true khi [force] == true
  Future<Map<String, dynamic>> deleteDepartment(int id, {bool force = false}) async {
    try {
      final raw = await _rest.deleteDepartment(
        id,
        force: force ? 'true' : null,
      );

      if (raw is Map) {
        final m = Map<String, dynamic>.from(raw);
        return {
          'success': true,
          'message': m['message'] ?? 'Xóa thành công',
        };
      }
      return {
        'success': true,
        'message': 'Xóa thành công',
      };
    } on DioException catch (e) {
      log('DELETE DEPARTMENT ERROR: $e');
      log('DEPARTMENT ID: $id, FORCE: $force');
      throw AppApiException.fromDio(e);
    }
  }

  /// ================= SEARCH / GET ALL =================
  /// GET /api/departments
  Future<Map<String, dynamic>> searchDepartments({
    String? keyword,
    bool? active,
    int page = 0,
    int size = 10,
  }) async {
    try {
      final raw = await _rest.searchDepartments(
        page: page,
        size: size,
        keyword: keyword,
        isActive: active,
      );

      if (raw is! Map) {
        throw AppApiException(message: 'Failed to load departments');
      }

      final data = Map<String, dynamic>.from(raw);
      final List<dynamic> content = data['data'] ?? [];

      log('TOTAL DEPARTMENTS: ${data['totalElements'] ?? content.length}');

      return {
        'departments': content
            .map((e) => DepartmentModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        'totalElements': data['totalElements'] ?? content.length,
        'totalPages': data['totalPages'] ?? 1,
      };
    } on DioException catch (e) {
      log('GET DEPARTMENTS ERROR: $e');
      throw AppApiException.fromDio(e);
    }
  }

  /// ================= GET BY ID =================
  /// GET /api/departments/findDepartment/{id}
  Future<DepartmentModel?> getDepartmentById(int id) async {
    try {
      final raw = await _rest.getDepartmentById(id);
      if (raw is! Map<String, dynamic>) {
        return null;
      }
      return DepartmentModel.fromJson(raw);
    } on DioException catch (e) {
      log('GET DEPARTMENT BY ID ERROR: $e');
      return null;
    } catch (e) {
      log('GET DEPARTMENT BY ID ERROR: $e');
      return null;
    }
  }

  /// ================= GET MEMBERS =================
  /// GET /api/departments/{id}/members
  Future<Map<String, dynamic>> getDepartmentMembers({
    required int departmentId,
  }) async {
    try {
      final data = await _rest.getDepartmentMembers(departmentId);

      if (data is List) {
        return {
          'members': data,
          'totalElements': data.length,
          'totalPages': 1,
        };
      }
      if (data is Map) {
        final m = Map<String, dynamic>.from(data);
        return {
          'members': m['content'] ?? m['data'] ?? m,
          'totalElements': m['totalElements'] ??
              ((m['content'] ?? m['data'] ?? []) as List).length,
          'totalPages': m['totalPages'] ?? 1,
        };
      }

      return {'members': [], 'totalElements': 0, 'totalPages': 0};
    } on DioException catch (e) {
      log('GET DEPARTMENT MEMBERS ERROR: $e');
      return {'members': [], 'totalElements': 0, 'totalPages': 0};
    } catch (e) {
      log('GET DEPARTMENT MEMBERS ERROR: $e');
      return {'members': [], 'totalElements': 0, 'totalPages': 0};
    }
  }

  /// ================= GET PROJECT MANAGERS FOR DEPARTMENT =================
  /// GET /api/users/department/managers
  Future<Map<String, dynamic>> getProjectManagersForDepartment({
    String? keyword,
    bool? assigned,
    int page = 0,
    int size = 10,
  }) async {
    try {
      final raw = await _rest.getProjectManagersForDepartment(
        page: page,
        size: size,
        keyword: keyword,
        assigned: assigned,
      );
      if (raw is! Map) {
        throw AppApiException(message: 'Failed to load project managers');
      }
      return Map<String, dynamic>.from(raw);
    } on DioException catch (e) {
      log('GET PROJECT MANAGERS ERROR: $e');
      throw AppApiException.fromDio(e);
    }
  }

  /// ================= GET PROJECT MEMBERS FOR DEPARTMENT =================
  /// GET /api/users/department/members
  Future<Map<String, dynamic>> getProjectMembersForDepartment({
    String? keyword,
    String? role,
    bool? assigned,
    int page = 0,
    int size = 10,
  }) async {
    try {
      final raw = await _rest.getProjectMembersForDepartment(
        page: page,
        size: size,
        keyword: keyword,
        role: role,
        assigned: assigned,
      );
      if (raw is! Map) {
        throw AppApiException(message: 'Failed to load project members');
      }
      return Map<String, dynamic>.from(raw);
    } on DioException catch (e) {
      log('GET PROJECT MEMBERS ERROR: $e');
      throw AppApiException.fromDio(e);
    }
  }

  /// ================= GET DEPARTMENT BY PROJECT MANAGER ID =================
  Future<DepartmentModel?> getDepartmentByProjectManagerId(
    int projectManagerId,
  ) async {
    try {
      final result = await searchDepartments(page: 0, size: 1000);
      final departments = result['departments'] as List<DepartmentModel>;

      final matched = departments.firstWhere(
        (d) => d.projectManagerId == projectManagerId,
        orElse: () => DepartmentModel(id: 0, name: '', code: '', isActive: false),
      );
      if (matched.id != 0) {
        log(
          'Found department for projectManagerId $projectManagerId: ${matched.id} - ${matched.name}',
        );
        return matched;
      }

      log('No department found for projectManagerId: $projectManagerId');
      return null;
    } catch (e) {
      log('GET DEPARTMENT BY PROJECT MANAGER ERROR: $e');
      return null;
    }
  }

  /// ================= GET ALL (Legacy - for compatibility) =================
  Future<Map<String, dynamic>> getDepartments({
    String? keyword,
    bool? active,
    int page = 0,
    int size = 10,
  }) async {
    return searchDepartments(
      keyword: keyword,
      active: active,
      page: page,
      size: size,
    );
  }

  /// ================= GET DEPARTMENT COURSES =================
  /// GET /api/lms/courses?departmentId={id}
  Future<Map<String, dynamic>> getDepartmentCourses({
    required int departmentId,
    String? keyword,
    String? level,
    int page = 0,
    int size = 10,
  }) async {
    try {
      final raw = await _rest.getDepartmentCourses(
        departmentId: departmentId,
        page: page,
        size: size,
        keyword: keyword,
        level: level,
      );

      List<dynamic> content;
      if (raw is List) {
        content = raw;
      } else if (raw is Map) {
        final data = Map<String, dynamic>.from(raw);
        content = data['content'] as List<dynamic>? ??
            data['data'] as List<dynamic>? ??
            [];
      } else {
        return {'courses': [], 'totalElements': 0, 'totalPages': 0};
      }

      final Map<String, dynamic>? dataMap =
          raw is Map ? Map<String, dynamic>.from(raw) : null;

      return {
        'courses': List<Map<String, dynamic>>.from(content),
        'totalElements':
            dataMap != null ? (dataMap['totalElements'] ?? content.length) : content.length,
        'totalPages': dataMap != null ? (dataMap['totalPages'] ?? 1) : 1,
      };
    } on DioException catch (e) {
      log('GET DEPARTMENT COURSES ERROR: $e');
      return {'courses': [], 'totalElements': 0, 'totalPages': 0};
    } catch (e) {
      log('GET DEPARTMENT COURSES ERROR: $e');
      return {'courses': [], 'totalElements': 0, 'totalPages': 0};
    }
  }

  /// ================= GET DEPARTMENT LEARNING PATHS =================
  /// GET /api/lms/learning-paths?departmentId={id}
  Future<List<Map<String, dynamic>>> getDepartmentLearningPaths(
    int departmentId,
  ) async {
    try {
      final raw = await _rest.getDepartmentLearningPaths(
        departmentId: departmentId,
        page: 0,
        size: 100,
      );

      if (raw is List) {
        return List<Map<String, dynamic>>.from(raw);
      }
      if (raw is Map) {
        final data = Map<String, dynamic>.from(raw);
        final content = data['content'] as List<dynamic>? ??
            data['data'] as List<dynamic>? ??
            <dynamic>[];
        return List<Map<String, dynamic>>.from(content);
      }

      return [];
    } on DioException catch (e) {
      log('GET DEPARTMENT LEARNING PATHS ERROR: $e');
      return [];
    } catch (e) {
      log('GET DEPARTMENT LEARNING PATHS ERROR: $e');
      return [];
    }
  }

  /// ================= TOGGLE ACTIVE =================
  /// PATCH /api/departments/{id}/toggle-active
  Future<void> toggleDepartmentActive(int id) async {
    if (id == 0) {
      log('ERROR: DEPARTMENT ID IS INVALID');
      throw AppApiException(message: 'Department id is invalid');
    }

    try {
      await _rest.toggleDepartmentActive(id);
    } on DioException catch (e) {
      log('TOGGLE DEPARTMENT ACTIVE ERROR: $e');
      log('DEPARTMENT ID: $id');
      throw AppApiException.fromDio(e);
    }
  }

  /// ================= REMOVE PROJECT MANAGER =================
  Future<DepartmentModel?> removeProjectManager(int departmentId) async {
    try {
      final raw = await _rest.patchDepartment(departmentId, {
        'projectManagerId': 0,
      });
      if (raw is! Map<String, dynamic>) {
        log('REMOVE PM FAILED - unexpected body type');
        return null;
      }
      return DepartmentModel.fromJson(raw);
    } on DioException catch (e) {
      if (_isBadResponse(e)) {
        log(
          'REMOVE PM FAILED - Status: ${e.response?.statusCode}, '
          'Body: ${e.response?.data}',
        );
        return null;
      }
      log('REMOVE PM ERROR: $e');
      throw AppApiException.fromDio(e);
    }
  }

  /// ================= ADD USERS TO DEPARTMENT (Legacy) =================
  Future<bool> addUsersToDepartment({
    required int departmentId,
    required String departmentName,
    required String departmentCode,
    required bool isActive,
    required List<int> userIds,
    int? projectManagerId,
  }) async {
    try {
      final body = <String, dynamic>{
        'name': departmentName,
        'code': departmentCode,
        'isActive': isActive,
        if (userIds.isNotEmpty) 'userIds': userIds,
        if (projectManagerId != null) 'projectManagerId': projectManagerId,
      };

      await _rest.patchDepartment(departmentId, body);
      return true;
    } on DioException catch (e) {
      if (_isBadResponse(e)) {
        return false;
      }
      log('ADD USERS TO DEPARTMENT ERROR: $e');
      throw AppApiException.fromDio(e);
    }
  }
}
