import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smet/page/admin/department_management/screen/department_management.dart';
import 'package:smet/page/admin/user_management/screen/user_management.dart';
import 'package:smet/page/employee/course_catalog/screen/course_catalog_base.dart';
import 'package:smet/page/employee/course_detail/screen/course_detail_base.dart';
import 'package:smet/page/employee/dashboard/screen/employee_dashboard_base.dart';
import 'package:smet/page/employee/learning_workspace/screen/learning_workspace_base.dart';
import 'package:smet/page/login/login.dart';
import 'package:smet/page/mentor/mentor_dashboard/mentor_dashboard.dart';
import 'package:smet/page/mentor/mentor_dashboard/mentor_shell.dart';
import 'package:smet/page/mentor/mentor_course/mentor_course.dart';
import 'package:smet/page/mentor/mentor_course/mentor_course_detail_web.dart';
import 'package:smet/page/mentor/mentor_course/mentor_course_detail_mobile.dart';
import 'package:smet/page/mentor/mentor_course/mentor_create_course_web.dart';
import 'package:smet/page/mentor/mentor_course/mentor_create_course_mobile.dart';
import 'package:smet/page/mentor/mentor_learning_path/mentor_learning_path.dart';
import 'package:smet/page/mentor/mentor_learning_path/mentor_create_learning_path_web.dart';
import 'package:smet/page/mentor/mentor_learning_path/mentor_create_learning_path_mobile.dart';

import 'package:smet/page/profile/screen/profile.dart';
import 'package:smet/page/project_manager/dashboard/screen/pm_dashboard_base.dart';
import 'package:smet/page/project_manager/project/screen/project_management_base.dart';
import 'package:smet/page/project_manager/project_member/screen/project_member_base.dart';
import 'package:smet/page/project_manager/project_progress/screen/project_progress_base.dart';

final bool isWebPlatform = kIsWeb;

class AppPages {
  AppPages._();

  static const initial = '/login';

  static final GoRouter router = GoRouter(
    initialLocation: initial,
    routes: [
      // Mentor routes with ShellRoute (sidebar + content)
      ShellRoute(
        builder: (context, state, child) {
          return MentorShell(child: child);
        },
        routes: [
          // Mentor Dashboard
          GoRoute(
            path: '/mentor/dashboard',
            pageBuilder:
                (context, state) =>
                    const NoTransitionPage(child: MentorDashboard()),
          ),

          // Mentor Courses list
          GoRoute(
            path: '/mentor/courses',
            pageBuilder:
                (context, state) =>
                    const NoTransitionPage(child: MentorCourse()),
            routes: [
              // Create course — MUST come before :id to avoid "create" being parsed as course ID
              GoRoute(
                path: 'create',
                builder: (context, state) {
                  if (isWebPlatform) {
                    return const MentorCreateCourseWeb();
                  }
                  return const MentorCreateCourseMobile();
                },
              ),
              // Course detail
              GoRoute(
                path: ':id',
                builder: (context, state) {
                  final id = state.pathParameters['id'] ?? '';

                  if (isWebPlatform) {
                    return MentorCourseDetailWeb(courseId: id);
                  }
                  return MentorCourseDetailMobile(courseId: id);
                },
                routes: [
                  // Edit course
                  GoRoute(
                    path: 'edit',
                    builder: (context, state) {
                      final parentId = state.pathParameters['id'] ?? '';
                      if (isWebPlatform) {
                        return MentorCourseDetailWeb(courseId: parentId);
                      }
                      return MentorCourseDetailMobile(courseId: parentId);
                    },
                  ),
                ],
              ),
            ],
          ),

          // Mentor Learning Paths
          GoRoute(
            path: '/mentor/learning-paths',
            pageBuilder:
                (context, state) =>
                    const NoTransitionPage(child: MentorLearningPath()),
            routes: [
              // Create / Edit learning path
              GoRoute(
                path: 'create',
                builder: (context, state) {
                  final editId = state.uri.queryParameters['edit'];
                  if (isWebPlatform) {
                    return MentorCreateLearningPathWeb(editId: editId);
                  }
                  return MentorCreateLearningPathMobile(editId: editId);
                },
              ),
            ],
          ),
        ],
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      
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
