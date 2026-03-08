import 'package:flutter/material.dart';
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
      // Role-based routes
      GoRoute(
        path: '/user_management',
        builder: (context, state) => const _PlaceholderPage(title: 'User Management'),
      ),
      GoRoute(
        path: '/pm/dashboard',
        builder: (context, state) => const _PlaceholderPage(title: 'PM Dashboard'),
      ),
      GoRoute(
        path: '/mentor/dashboard',
        builder: (context, state) => const _PlaceholderPage(title: 'Mentor Dashboard'),
      ),
      GoRoute(
        path: '/employee/dashboard',
        builder: (context, state) => const _PlaceholderPage(title: 'Employee Dashboard'),
      ),
    ],
  );
}

class _PlaceholderPage extends StatelessWidget {
  final String title;

  const _PlaceholderPage({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text(title)),
    );
  }
}