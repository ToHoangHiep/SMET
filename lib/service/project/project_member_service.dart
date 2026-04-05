import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:smet/model/project_member_model.dart';
import 'package:smet/service/common/base_url.dart';
import 'package:smet/service/common/auth_service.dart';
import 'package:smet/service/project/project_service.dart';
import 'dart:developer';

class ProjectMemberService {

  // ================================================================
  // LAY THANH VIEN TU PROJECT
  // Backend: Chi co ProjectService.getById() tra ve thong tin project
  // ProjectModel da co memberIds + memberNames
  // Refactor: goi ProjectService.getById() roi convert sang ProjectMemberModel
  // ================================================================

  /// GET MEMBERS BY PROJECT
  /// Backend: Dung ProjectService.getById() (backend khong co endpoint rieng cho project-members)
  /// Endpoint: GET /api/projects/get/{projectId}
  /// Response: ProjectModel voi memberIds + memberNames
  static Future<List<ProjectMemberModel>> getByProject(int projectId) async {
    log("[ProjectMemberService] getByProject() called - projectId=$projectId");

    try {
      final project = await ProjectService.getById(projectId);

      final members = <ProjectMemberModel>[];

      // Leader
      if (project.leaderId != 0) {
        members.add(ProjectMemberModel(
          id: 0, // Khong co ID rieng trong backend
          projectId: projectId,
          userId: project.leaderId,
          role: ProjectMemberRole.PROJECT_LEAD,
          userName: project.leaderName,
          userEmail: null,
        ));
      }

      // Mentor
      if (project.mentorId != null) {
        members.add(ProjectMemberModel(
          id: 0,
          projectId: projectId,
          userId: project.mentorId!,
          role: ProjectMemberRole.PROJECT_MENTOR,
          userName: project.mentorName,
          userEmail: null,
        ));
      }

      // Members
      if (project.memberIds != null && project.memberNames != null) {
        for (int i = 0; i < project.memberIds!.length; i++) {
          members.add(ProjectMemberModel(
            id: 0,
            projectId: projectId,
            userId: project.memberIds![i],
            role: ProjectMemberRole.PROJECT_MEMBER,
            userName: i < project.memberNames!.length
                ? project.memberNames![i]
                : null,
            userEmail: null,
          ));
        }
      }

      log("[ProjectMemberService] getByProject() success - ${members.length} members found");
      return members;
    } catch (e) {
      log("[ProjectMemberService] getByProject() FAILED: $e");
      rethrow;
    }
  }

  // ================================================================
  // CAC PHUONG THUC CON LAI: KHONG CO ENDPOINT TRONG BACKEND
  // Backend xu ly member thong qua ProjectService.create/update
  // memberIds duoc truyen trong request body cua ProjectRequest
  // ================================================================

  /// ADD MEMBER TO PROJECT
  /// Backend KHONG co endpoint rieng.
  /// De them member: goi ProjectService.update() voi danh sach memberIds da cap nhat.
  /// Phuong thuc nay chi ghi log canh bao.
  static Future<ProjectMemberModel> addMember({
    required int projectId,
    required int userId,
    required String role,
  }) async {
    log("[ProjectMemberService] addMember() called but backend has no dedicated endpoint.");
    log("  To add member, call ProjectService.update() with updated memberIds list.");
    log("  projectId=$projectId, userId=$userId, role=$role");
    throw UnimplementedError(
      "Backend khong co endpoint rieng cho addMember. "
      "Vui long goi ProjectService.update() de cap nhat danh sach thanh vien.",
    );
  }

  /// UPDATE MEMBER ROLE
  /// Backend KHONG co endpoint rieng.
  /// De doi vai tro: goi ProjectService.update() voi leaderId moi.
  static Future<ProjectMemberModel> updateMember({
    required int id,
    required int userId,
    required String role,
  }) async {
    log("[ProjectMemberService] updateMember() called but backend has no dedicated endpoint.");
    log("  To change role, call ProjectService.update() with updated leaderId.");
    log("  id=$id, userId=$userId, role=$role");
    throw UnimplementedError(
      "Backend khong co endpoint rieng cho updateMember. "
      "Vui long goi ProjectService.update() de cap nhat vai tro.",
    );
  }

  /// DELETE MEMBER
  /// Backend KHONG co endpoint rieng.
  /// De xoa member: goi ProjectService.update() voi danh sach memberIds da loai bo.
  static Future<void> deleteMember(int id) async {
    log("[ProjectMemberService] deleteMember() called but backend has no dedicated endpoint.");
    log("  To delete member, call ProjectService.update() with updated memberIds list.");
    log("  memberId=$id");
    throw UnimplementedError(
      "Backend khong co endpoint rieng cho deleteMember. "
      "Vui long goi ProjectService.update() de loai bo thanh vien.",
    );
  }

  /// REMOVE MEMBER FROM PROJECT by userId
  /// Backend KHONG co endpoint rieng.
  static Future<void> removeMember({
    required int projectId,
    required int userId,
  }) async {
    log("[ProjectMemberService] removeMember() called but backend has no dedicated endpoint.");
    log("  To remove member, call ProjectService.update() with updated memberIds list.");
    log("  projectId=$projectId, userId=$userId");
    throw UnimplementedError(
      "Backend khong co endpoint rieng cho removeMember. "
      "Vui long goi ProjectService.update() de loai bo thanh vien.",
    );
  }

  /// GET PROJECT WITH MEMBERS
  /// Backend: Dung ProjectService.getById()
  static Future<Map<String, dynamic>> getProjectWithMembers(int projectId) async {
    log("[ProjectMemberService] getProjectWithMembers() called - projectId=$projectId");

    try {
      final project = await ProjectService.getById(projectId);

      // Chuyen ProjectModel thanh Map
      final members = await getByProject(projectId);

      return {
        'project': {
          'id': project.id,
          'title': project.title,
          'departmentId': project.departmentId,
          'status': project.status.name,
          'leaderId': project.leaderId,
          'leaderName': project.leaderName,
          'mentorId': project.mentorId,
          'mentorName': project.mentorName,
          'memberIds': project.memberIds,
          'memberNames': project.memberNames,
        },
        'members': members.map((m) => {
          'id': m.id,
          'userId': m.userId,
          'userName': m.userName,
          'userEmail': m.userEmail,
          'role': m.role.name,
        }).toList(),
      };
    } catch (e) {
      log("[ProjectMemberService] getProjectWithMembers() FAILED: $e");
      rethrow;
    }
  }

  /// GET MEMBERS BY PROJECT (returns List<Map>) - Legacy
  /// Backend: Dung ProjectService.getById()
  static Future<List<Map<String, dynamic>>> getMembers(int projectId) async {
    log("[ProjectMemberService] getMembers() called - projectId=$projectId");

    try {
      final project = await ProjectService.getById(projectId);

      final List<Map<String, dynamic>> members = [];

      // Leader
      if (project.leaderId != 0) {
        members.add({
          'id': 0,
          'userId': project.leaderId,
          'userName': project.leaderName,
          'userEmail': null,
          'role': 'PROJECT_LEAD',
        });
      }

      // Mentor
      if (project.mentorId != null) {
        members.add({
          'id': 0,
          'userId': project.mentorId,
          'userName': project.mentorName,
          'userEmail': null,
          'role': 'PROJECT_MENTOR',
        });
      }

      // Members
      if (project.memberIds != null && project.memberNames != null) {
        for (int i = 0; i < project.memberIds!.length; i++) {
          members.add({
            'id': 0,
            'userId': project.memberIds![i],
            'userName': i < project.memberNames!.length
                ? project.memberNames![i]
                : null,
            'userEmail': null,
            'role': 'PROJECT_MEMBER',
          });
        }
      }

      return members;
    } catch (e) {
      log("[ProjectMemberService] getMembers() FAILED: $e");
      rethrow;
    }
  }

  /// ADD MULTIPLE MEMBERS
  /// Backend KHONG co endpoint rieng.
  static Future<List<ProjectMemberModel>> addMultipleMembers({
    required int projectId,
    required List<Map<String, dynamic>> members,
  }) async {
    log("[ProjectMemberService] addMultipleMembers() called but backend has no dedicated endpoint.");
    log("  To add multiple members, call ProjectService.update() with full updated memberIds list.");
    throw UnimplementedError(
      "Backend khong co endpoint rieng cho addMultipleMembers. "
      "Vui long goi ProjectService.update() de cap nhat danh sach thanh vien.",
    );
  }

  /// ================================================================
  /// GET USERS FOR PROJECT
  /// Endpoint: GET /api/users/for-project?departmentId=xxx&keyword=xxx&excludeUserIds=xxx&page=0&size=100
  /// Backend: Co endpoint nay trong UserController
  /// ================================================================

  static Future<List<Map<String, dynamic>>> getUsersForProject({
    required int departmentId,
    String? keyword,
    List<int>? excludeUserIds,
    int page = 0,
    int size = 100,
  }) async {
    final result = await getUsersForProjectPaginated(
      departmentId: departmentId,
      keyword: keyword,
      excludeUserIds: excludeUserIds,
      page: page,
      size: size,
    );
    return result['users'] as List<Map<String, dynamic>>;
  }

  /// GET USERS FOR PROJECT voi phan trang
  /// Endpoint: GET /api/users/for-project?departmentId=xxx&keyword=xxx&excludeUserIds=xxx&page=0&size=10
  /// Backend: Co endpoint nay trong UserController (co @PreAuthorize)
  static Future<Map<String, dynamic>> getUsersForProjectPaginated({
    required int departmentId,
    String? keyword,
    List<int>? excludeUserIds,
    String? role,
    int page = 0,
    int size = 10,
  }) async {
    try {
      final token = await AuthService.getToken();
      final queryParams = <String, String>{
        'departmentId': departmentId.toString(),
        'page': page.toString(),
        'size': size.toString(),
      };
      if (keyword != null && keyword.isNotEmpty) {
        queryParams['keyword'] = keyword;
      }
      if (excludeUserIds != null && excludeUserIds.isNotEmpty) {
        queryParams['excludeUserIds'] = excludeUserIds.join(',');
      }
      if (role != null && role.isNotEmpty) {
        queryParams['role'] = role;
      }
      final uri = Uri.parse("$baseUrl/users/for-project").replace(
        queryParameters: queryParams,
      );

      log("[ProjectMemberService] GET USERS FOR PROJECT - URL: $uri");

      final response = await http.get(
        uri,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      log("[ProjectMemberService] GET USERS FOR PROJECT STATUS: ${response.statusCode}");

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is! Map) {
          return {
            'users': <Map<String, dynamic>>[],
            'page': 0,
            'size': size,
            'totalElements': 0,
            'totalPages': 0,
          };
        }
        final usersList = decoded['content'] ?? decoded['data'];
        final list = usersList != null
            ? List<Map<String, dynamic>>.from(usersList)
            : <Map<String, dynamic>>[];
        return {
          'users': list,
          'page': decoded['page'] ?? page,
          'size': decoded['size'] ?? size,
          'totalElements': decoded['totalElements'] ?? 0,
          'totalPages': decoded['totalPages'] ?? 0,
        };
      }
      return {
        'users': <Map<String, dynamic>>[],
        'page': 0,
        'size': size,
        'totalElements': 0,
        'totalPages': 0,
      };
    } catch (e) {
      log("[ProjectMemberService] GET USERS FOR PROJECT ERROR: $e");
      return {
        'users': <Map<String, dynamic>>[],
        'page': 0,
        'size': 10,
        'totalElements': 0,
        'totalPages': 0,
      };
    }
  }

  /// Legacy: GET SELECTABLE USERS
  @Deprecated('Use getUsersForProject instead')
  static Future<List<Map<String, dynamic>>> getSelectableUsers({
    required String context,
  }) async {
    return getUsersForProject(
      departmentId: 1,
      keyword: null,
    );
  }
}
