import 'package:smet/model/user_model.dart';

/// AuthGuardService — kiểm tra quyền truy cập theo route path
///
/// Dùng cho:
/// - Router redirect guard (Lớp 1)
/// - Shell guard safety net (Lớp 2)
class AuthGuardService {
  static const _allowedRoles = {
    '/mentor': [UserRole.ADMIN, UserRole.MENTOR],
    '/pm': [UserRole.ADMIN, UserRole.PROJECT_MANAGER],
    '/employee': [UserRole.USER, UserRole.ADMIN, UserRole.MENTOR, UserRole.PROJECT_MANAGER],
    '/user_management': [UserRole.ADMIN],
    '/department_management': [UserRole.ADMIN],
    '/admin': [UserRole.ADMIN],
    '/reports': [UserRole.ADMIN, UserRole.MENTOR, UserRole.PROJECT_MANAGER],
    '/report': [UserRole.ADMIN, UserRole.MENTOR, UserRole.PROJECT_MANAGER],
    // Mọi role đã login đều có thể vào
    '/profile': [UserRole.ADMIN, UserRole.MENTOR, UserRole.PROJECT_MANAGER, UserRole.USER],
    '/notifications': [UserRole.ADMIN, UserRole.MENTOR, UserRole.PROJECT_MANAGER, UserRole.USER],
    '/home': [UserRole.ADMIN, UserRole.MENTOR, UserRole.PROJECT_MANAGER, UserRole.USER],
  };

  /// Kiểm tra xem role hiện tại có được phép truy cập path không
  static bool canAccess(String path, UserRole role) {
    for (final entry in _allowedRoles.entries) {
      if (path.startsWith(entry.key)) {
        return entry.value.contains(role);
      }
    }
    // Default: CHẶN truy cập nếu route không có trong danh sách cho phép
    return false;
  }

  /// Lấy redirect path cho role hiện tại
  static String getRedirectPath(UserRole role) {
    switch (role) {
      case UserRole.ADMIN:
        return '/user_management';
      case UserRole.PROJECT_MANAGER:
        return '/pm/dashboard';
      case UserRole.MENTOR:
        return '/mentor/dashboard';
      case UserRole.USER:
        return '/employee/dashboard';
    }
  }

  /// Kiểm tra nhanh user có phải employee không
  static bool isEmployee(UserRole role) => role == UserRole.USER;

  /// Kiểm tra nhanh user có phải mentor/admin không
  static bool isMentorOrAdmin(UserRole role) =>
      role == UserRole.MENTOR || role == UserRole.ADMIN;
}
