import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smet/page/admin/department_management/screen/department_management.dart';
import 'package:smet/page/admin/user_management/screen/user_management.dart';
import 'package:smet/page/first_login_password/first_login_password_page.dart';
import 'package:smet/page/employee/course_catalog/screen/course_catalog_base.dart';
import 'package:smet/page/employee/course_detail/screen/course_detail_base.dart';
import 'package:smet/page/employee/dashboard/screen/employee_dashboard_base.dart';
import 'package:smet/page/employee/learning_workspace/screen/learning_workspace_base.dart';
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

  static const initial = '/login';
  static final GoRouter router = GoRouter(
    initialLocation: initial,
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(
        path: '/first-login-password',
        builder: (context, state) => const FirstLoginPasswordPage(),
      ),
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
      // GoRoute(
      //   path: '/notifications',
      //   builder: (context, state) => const NotificationPage(),
      // ),
      // Project Manager Routes
      GoRoute(
        path: '/pm/dashboard',
        builder: (context, state) => const ProjectManagerDashboardPage(),
      ),
      GoRoute(
        path: '/pm/projects',
        builder: (context, state) => const ProjectManagementPage(),
      ),
      // GoRoute(
      //   path: '/pm/project_members',
      //   builder: (context, state) => const ProjectMemberPage(),
      // ),
      // GoRoute(
      //   path: '/pm/project_progress',
      //   builder: (context, state) => const ProjectProgressPage(),
      // ),
      // GoRoute(
      //   path: '/pm/learning_path',
      //   builder: (context, state) => const LearningPathPage(),
      // ),

      // GoRoute(
      //   path: '/employee/dashboard',
      //   builder: (context, state) => const EmployeeDashboardPage(),
      // ),
      // GoRoute(
      //   path: '/employee/courses',
      //   builder: (context, state) => const CourseCatalogPage(),
      // ),
      // GoRoute(
      //   path: '/employee/course/:id',
      //   builder: (context, state) {
      //     final courseId = state.pathParameters['id'] ?? '';
      //     return CourseDetailPage(courseId: courseId);
      //   },
      // ),
      // // Learning Workspace Route
      // GoRoute(
      //   path: '/employee/learn/:courseId',
      //   builder: (context, state) {
      //     final courseId = state.pathParameters['courseId'] ?? '';
      //     return LearningWorkspacePage(courseId: courseId);
      //   },
      // ),
      // GoRoute(
      //   path: '/employee/learn/:courseId/:lessonId',
      //   builder: (context, state) {
      //     final courseId = state.pathParameters['courseId'] ?? '';
      //     final lessonId = state.pathParameters['lessonId'] ?? '';
      //     return LearningWorkspacePage(courseId: courseId, lessonId: lessonId);
      //   },
      // ),
      // Employee Routes
      GoRoute(
        path: '/employee/dashboard',
        builder: (context, state) => const EmployeeDashboardPage(),
      ),
      GoRoute(
        path: '/employee/courses',
        builder: (context, state) => const CourseCatalogPage(),
      ),
      GoRoute(
        path: '/employee/course/:id',
        builder: (context, state) {
          final courseId = state.pathParameters['id'] ?? '';
          return CourseDetailPage(courseId: courseId);
        },
      ),
      // Learning Workspace Route
      GoRoute(
        path: '/employee/learn/:courseId',
        builder: (context, state) {
          final courseId = state.pathParameters['courseId'] ?? '';
          return LearningWorkspacePage(courseId: courseId);
        },
      ),
      GoRoute(
        path: '/employee/learn/:courseId/:lessonId',
        builder: (context, state) {
          final courseId = state.pathParameters['courseId'] ?? '';
          final lessonId = state.pathParameters['lessonId'] ?? '';
          return LearningWorkspacePage(courseId: courseId, lessonId: lessonId);
        },
      ),
    ],
  );
}
