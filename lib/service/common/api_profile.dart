import 'package:smet/model/user_model.dart';
import 'package:smet/service/common/current_user_store.dart';

class ApiProfile {
  final CurrentUserStore _currentUserStore = CurrentUserStore.instance;

  UserModel get _fallbackUser => UserModel(
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

  Future<UserModel> getUserProfile() async {
    await Future.delayed(const Duration(milliseconds: 800));
    return _currentUserStore.currentUser ?? _fallbackUser;
  }

  Future<UserModel> updateUserProfile(UserModel updatedUser) async {
    await Future.delayed(const Duration(milliseconds: 1000));

    if (updatedUser.firstName.isEmpty || updatedUser.lastName.isEmpty) {
      throw Exception('Tên không được để trống');
    }

    _currentUserStore.setCurrentUser(updatedUser);
    return updatedUser;
  }

  Future<bool> changePassword(String oldPass, String newPass) async {
    await Future.delayed(const Duration(milliseconds: 1000));

    if (oldPass != '123456') {
      throw Exception('Mật khẩu cũ không chính xác');
    }

    return true;
  }
}
