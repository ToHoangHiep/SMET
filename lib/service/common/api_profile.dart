import 'dart:typed_data';

import 'package:smet/model/user_model.dart';
import 'package:smet/service/common/current_user_store.dart';

class ApiProfile {
  /// Ảnh đại diện đã lưu (mock: lưu trong memory)
  Uint8List? _customAvatarBytes;

  // 1. Lấy thông tin Profile — đồng bộ với [CurrentUserStore] (cùng user hiện trên sidebar)
  Future<UserModel> getUserProfile() async {
    await Future.delayed(const Duration(milliseconds: 800)); // Giả lập loading
    return CurrentUserStore.currentUser;
  }

  /// Cập nhật ảnh đại diện (mock: lưu bytes trong memory)
  Future<void> updateAvatar(Uint8List bytes) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _customAvatarBytes = bytes;
    CurrentUserStore.setCurrentUser(
      CurrentUserStore.currentUser.copyWith(avatarUrl: '__local__'),
    );
  }

  /// Lấy ảnh đại diện đã lưu (khi avatarUrl == '__local__')
  Uint8List? getAvatarBytes() => _customAvatarBytes;

  // 2. Cập nhật thông tin Profile — cập nhật luôn [CurrentUserStore] để sidebar và các màn khác đồng bộ
  Future<UserModel> updateUserProfile(UserModel updatedUser) async {
    await Future.delayed(
      const Duration(milliseconds: 1000),
    ); // Giả lập xử lý server

    // Giả lập validate
    if (updatedUser.firstName.isEmpty || updatedUser.lastName.isEmpty) {
      throw Exception("Tên không được để trống");
    }

    CurrentUserStore.setCurrentUser(updatedUser);
    return updatedUser;
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
