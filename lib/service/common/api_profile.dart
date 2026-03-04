import 'package:smet/model/user_model.dart';

class ApiProfile {
  // Mock data: User đang đăng nhập
  UserModel _currentUser = UserModel(
    id: 'user_999',
    username: 'janedoe',
    firstName: 'Jane',
    lastName: 'Doe',
    email: 'jane.doe@smets.com',
    phone: '+1 (555) 000-0000',
    role: UserRole.mentor,
    isActive: true,
    lastUpdated: DateTime.now(),
    avatarUrl:
        'https://lh3.googleusercontent.com/aida-public/AB6AXuBdPL4o3GU8fchZxoinTPLp6uPNkOyfpR6Kk3z5f5X0ngmUKw9wh3MUzUBllTZ16jCRc3aLiw1b21iIvSYLl8tZrAqV1dY_gfMWbUqrV4F-VeNSaICoYOqsPFnqBrgwr7LY71w_YDf2_MMucyIlhrZi84nmzoxi_caBty7DiIdKbtzWNPRay4NKRS4WcQpTrtrPvpNAWlYyO02NMKnvpBcfXjSGfHO_PsfI1-VdzSztr0r_CfwzR_k3iziKfYA1911jIQojF9lu749G',
  );

  // 1. Lấy thông tin Profile
  Future<UserModel> getUserProfile() async {
    await Future.delayed(const Duration(milliseconds: 800)); // Giả lập loading
    return _currentUser;
  }

  // 2. Cập nhật thông tin Profile
  Future<UserModel> updateUserProfile(UserModel updatedUser) async {
    await Future.delayed(
      const Duration(milliseconds: 1000),
    ); // Giả lập xử lý server

    // Giả lập validate
    if (updatedUser.firstName.isEmpty || updatedUser.lastName.isEmpty) {
      throw Exception("Tên không được để trống");
    }

    _currentUser = updatedUser; // Lưu vào biến tạm
    return _currentUser;
  }

  // 3. Đổi mật khẩu
  Future<bool> changePassword(String oldPass, String newPass) async {
    await Future.delayed(const Duration(milliseconds: 1000));

    // Giả lập check password cũ (password đúng là "123456")
    if (oldPass != "123456") {
      throw Exception("Mật khẩu cũ không chính xác");
    }

    return true; // Thành công
  }
}
