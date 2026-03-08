import 'package:smet/model/user_model.dart';

/// Store người dùng đang đăng nhập — dùng chung cho sidebar (tên hiển thị) và trang Profile.
/// Khi đăng nhập thật sau này, gọi [setCurrentUser] với user từ API.
class CurrentUserStore {
  CurrentUserStore._();

  static UserModel? _currentUser;

  /// User mặc định khi chưa có đăng nhập (đồng bộ với "John Doe" ở sidebar).
  static UserModel _defaultUser() {
    return UserModel(
      id: 'admin_1',
      username: 'johndoe',
      firstName: 'John',
      lastName: 'Doe',
      email: 'john.doe@smets.com',
      phone: '+84 (555) 000-0000',
      role: UserRole.admin,
      isActive: true,
      lastUpdated: DateTime.now(),
      avatarUrl: null,
    );
  }

  /// Người dùng hiện tại. Trả về user mặc định (John Doe - admin) nếu chưa set.
  static UserModel get currentUser => _currentUser ?? _defaultUser();

  /// Đặt người dùng hiện tại (gọi sau khi đăng nhập hoặc khi cập nhật profile).
  static void setCurrentUser(UserModel? user) {
    _currentUser = user;
  }

  /// Kiểm tra đã có user thật (đã đăng nhập) chưa, hay đang dùng default.
  static bool get hasLoggedInUser => _currentUser != null;
}
