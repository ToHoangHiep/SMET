import 'package:smet/model/user_model.dart';

class CurrentUserStore {
  CurrentUserStore._();

  static final CurrentUserStore instance = CurrentUserStore._();

  UserModel? _currentUser;

  UserModel? get currentUser => _currentUser;

  void setCurrentUser(UserModel user) {
    _currentUser = user;
  }

  void clear() {
    _currentUser = null;
  }
}
