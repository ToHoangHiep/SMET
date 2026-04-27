import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'user_management_rest_client.g.dart';

@RestApi()
abstract class UserManagementRestClient {
  factory UserManagementRestClient(Dio dio, {String baseUrl}) =
      _UserManagementRestClient;

  @GET('/admin/listUser')
  Future<dynamic> listUsers({
    @Query('page') required int page,
    @Query('size') required int size,
    @Query('keyword') String? keyword,
    @Query('role') String? role,
    @Query('isActive') bool? isActive,
    @Query('departmentId') int? departmentId,
  });

  @PATCH('/admin/users/{id}')
  Future<void> updateUser(
    @Path('id') int id,
    @Body() Map<String, dynamic> body,
  );

  @PUT('/admin/toggleUserActive/{id}')
  Future<void> toggleUserActive(@Path('id') int id);

  /// Upload Excel: dùng [Dio.post] + [FormData] trong facade (Retrofit generator
  /// 9.1.9 không hỗ trợ [MultipartFile] đủ tốt cho mọi target).

  @GET('/admin/import/template')
  @DioResponseType(ResponseType.bytes)
  Future<List<int>> downloadImportTemplate();

  @POST('/auth/register')
  Future<void> register(@Body() Map<String, dynamic> body);
}
