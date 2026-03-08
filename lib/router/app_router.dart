import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smet/page/admin/department_management/screen/department_management.dart';
import 'package:smet/page/admin/user_management/screen/user_management.dart';
import 'package:smet/page/home/home.dart';
import 'package:smet/page/login/login.dart';
import 'package:smet/page/notification/screen/notification_page.dart';
import 'package:smet/page/profile/screen/profile.dart';
import 'package:smet/page/project_manager/dashboard/screen/pm_dashboard_base.dart';
import 'package:smet/page/project_manager/project/screen/project_management_base.dart';
import 'package:smet/page/project_manager/project_member/screen/project_member_base.dart';
import 'package:smet/page/project_manager/project_progress/screen/project_progress_base.dart';
import 'package:smet/page/project_manager/learning_path/screen/learning_path_base.dart';

class AppPages {
  AppPages._();

  static const initial = '/pm/dashboard';
  static final GoRouter router = GoRouter(
    initialLocation: initial,
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(path: '/home', builder: (context, state) => const HomePage()),
      GoRoute(
        path: '/user_management',
        builder: (context, state) => const UserManagementPage(),
      ),
      GoRoute(
        path: '/department_management',
        builder: (context, state) => const DepartmentManagementPage(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfilePage(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationPage(),
      ),
      // Project Manager Routes
      GoRoute(
        path: '/pm/dashboard',
        builder: (context, state) => const ProjectManagerDashboardPage(),
      ),
      GoRoute(
        path: '/pm/projects',
        builder: (context, state) => const ProjectManagementPage(),
      ),
      GoRoute(
        path: '/pm/project_members',
        builder: (context, state) => const ProjectMemberPage(),
      ),
      GoRoute(
        path: '/pm/project_progress',
        builder: (context, state) => const ProjectProgressPage(),
      ),
      GoRoute(
        path: '/pm/learning_path',
        builder: (context, state) => const LearningPathPage(),
      ),
      // Role-based routes
      // GoRoute(
      //   path: '/user_management',
      //   builder: (context, state) => const _PlaceholderPage(title: 'Quản lý người dùng'),
      // ),
      // GoRoute(
      //   path: '/pm/dashboard',
      //   builder: (context, state) => const _PlaceholderPage(title: 'Bảng điều khiển PM'),
      // ),
      // GoRoute(
      //   path: '/mentor/dashboard',
      //   builder: (context, state) => const _PlaceholderPage(title: 'Bảng điều khiển Mentor'),
      // ),
      // GoRoute(
      //   path: '/employee/dashboard',
      //   builder: (context, state) => const _PlaceholderPage(title: 'Bảng điều khiển nhân viên'),
      // ),
    ],
  );
}
