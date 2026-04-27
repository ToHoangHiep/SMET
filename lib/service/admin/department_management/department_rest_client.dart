import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'department_rest_client.g.dart';

@RestApi()
abstract class DepartmentRestClient {
  factory DepartmentRestClient(Dio dio, {String baseUrl}) =
      _DepartmentRestClient;

  @POST('/departments/createDepartment')
  Future<dynamic> createDepartment(@Body() Map<String, dynamic> body);

  @PATCH('/departments/{id}')
  Future<dynamic> patchDepartment(
    @Path('id') int id,
    @Body() Map<String, dynamic> body,
  );

  @DELETE('/departments/{id}')
  Future<dynamic> deleteDepartment(
    @Path('id') int id, {
    @Query('force') String? force,
  });

  @GET('/departments')
  Future<dynamic> searchDepartments({
    @Query('page') required int page,
    @Query('size') required int size,
    @Query('keyword') String? keyword,
    @Query('isActive') bool? isActive,
  });

  @GET('/departments/findDepartment/{id}')
  Future<dynamic> getDepartmentById(@Path('id') int id);

  @GET('/departments/{id}/members')
  Future<dynamic> getDepartmentMembers(@Path('id') int departmentId);

  @GET('/users/department/managers')
  Future<dynamic> getProjectManagersForDepartment({
    @Query('page') required int page,
    @Query('size') required int size,
    @Query('keyword') String? keyword,
    @Query('assigned') bool? assigned,
  });

  @GET('/users/department/members')
  Future<dynamic> getProjectMembersForDepartment({
    @Query('page') required int page,
    @Query('size') required int size,
    @Query('keyword') String? keyword,
    @Query('role') String? role,
    @Query('assigned') bool? assigned,
  });

  @GET('/lms/courses')
  Future<dynamic> getDepartmentCourses({
    @Query('departmentId') required int departmentId,
    @Query('page') required int page,
    @Query('size') required int size,
    @Query('keyword') String? keyword,
    @Query('level') String? level,
  });

  @GET('/lms/learning-paths')
  Future<dynamic> getDepartmentLearningPaths({
    @Query('departmentId') required int departmentId,
    @Query('page') required int page,
    @Query('size') required int size,
  });

  @PATCH('/departments/{id}/toggle-active')
  Future<void> toggleDepartmentActive(@Path('id') int id);
}
