import 'dart:async';
import 'package:smet/model/user_model.dart';

class ApiService {
  // Singleton pattern (tùy chọn)
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // Dữ liệu giả (Mock Data)
  final List<UserModel> _mockDatabase = [
    UserModel(
      id: '1',
      username: 'jdoe',
      firstName: 'John',
      lastName: 'Doe',
      email: 'john.doe@smets.com',
      phone: '0901234567',
      role: UserRole.admin,
      lastUpdated: DateTime.now(),
    ),
    UserModel(
      id: '2',
      username: 'sarahm',
      firstName: 'Sarah',
      lastName: 'Miller',
      email: 'sarah.miller@smets.com',
      phone: '0909876543',
      role: UserRole.projectManager,
      lastUpdated: DateTime.now().subtract(const Duration(days: 2)),
    ),
    UserModel(
      id: '3',
      username: 'davidk',
      firstName: 'David',
      lastName: 'Kim',
      email: 'david.kim@smets.com',
      phone: '0912345678',
      role: UserRole.mentor,
      lastUpdated: DateTime.now().subtract(const Duration(days: 5)),
    ),
  ];

  // Lấy danh sách users
  Future<List<UserModel>> getUsers() async {
    await Future.delayed(
      const Duration(milliseconds: 800),
    ); // Giả lập delay mạng
    return List.from(_mockDatabase);
  }

  // Tạo user mới
  Future<UserModel> createUser(UserModel user) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _mockDatabase.insert(0, user); // Thêm vào đầu danh sách giả
    return user;
  }

  // Giả lập Import Excel
  // Lưu ý: Trong thực tế cần package 'file_picker' và 'excel'
  Future<List<UserModel>> importExcelFile() async {
    await Future.delayed(const Duration(seconds: 1));

    // Giả lập đọc file và trả về 2 user mới
    final newUsers = [
      UserModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        username: 'imported_user_1',
        firstName: 'Excel',
        lastName: 'One',
        email: 'excel.one@smets.com',
        phone: '0000000001',
        role: UserRole.employee,
        lastUpdated: DateTime.now(),
      ),
      UserModel(
        id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
        username: 'imported_user_2',
        firstName: 'Excel',
        lastName: 'Two',
        email: 'excel.two@smets.com',
        phone: '0000000002',
        role: UserRole.employee,
        lastUpdated: DateTime.now(),
      ),
    ];

    _mockDatabase.addAll(newUsers);
    return newUsers;
  }
}
