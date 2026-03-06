import 'package:go_router/go_router.dart';
import 'package:smet/page/home/home.dart';
import 'package:smet/page/login/login.dart';
import 'package:smet/page/admin_dashboard/user_management/screen/user_management.dart';
import 'package:smet/page/admin_dashboard/department_management/department_management.dart';

class AppPages {
  AppPages._();

  static const initial = '/';
  static final GoRouter router = GoRouter(
    initialLocation: initial,
    routes: [
      GoRoute(path: '/login', builder: (context, state) => LoginPage()),
      GoRoute(path: '/home', builder: (context, state) => HomePage()),
      GoRoute(path: '/', builder: (context, state) => UserManagementPage()),
      GoRoute(
        path: '/department_management',
        builder: (context, state) => DepartmentManagementPage(),
      ),
    ],
  );
}
