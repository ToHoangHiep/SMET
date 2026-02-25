import 'package:go_router/go_router.dart';
import 'package:smet/page/home/home.dart';
import 'package:smet/page/login/login.dart';

class AppPages {
  AppPages._();

  static const initial = '/';
  static final GoRouter router = GoRouter(
    initialLocation: initial,
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => LoginPage(),
      ),
      GoRoute(  
        path: '/home',
        builder: (context, state) => HomePage(),
      ),
    ],
  );
}