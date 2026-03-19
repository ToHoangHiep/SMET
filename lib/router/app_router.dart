import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smet/page/home/home.dart';
import 'package:smet/page/login/login.dart';
import 'package:smet/page/admin_dashboard/user_management/user_management.dart';
import 'package:smet/page/mentor_dashboard/mentor_dashboard.dart';
import 'package:smet/page/mentor_dashboard/mentor_shell.dart';
import 'package:smet/page/mentor_course/mentor_course.dart';
import 'package:smet/page/mentor_course/mentor_course_detail_web.dart';
import 'package:smet/page/mentor_course/mentor_course_detail_mobile.dart';
import 'package:smet/page/mentor_course/mentor_create_course_web.dart';
import 'package:smet/page/mentor_course/mentor_create_course_mobile.dart';
import 'package:smet/page/mentor_course/mentor_update_course_web.dart';
import 'package:smet/page/mentor_course/mentor_update_course_mobile.dart';
import 'package:smet/page/mentor_learning_path/mentor_learning_path.dart';
import 'package:smet/page/mentor_learning_path/mentor_create_learning_path_web.dart';
import 'package:smet/page/mentor_learning_path/mentor_create_learning_path_mobile.dart';

/// Check if running on web platform
final bool isWebPlatform = kIsWeb;

class AppPages {
  AppPages._();

  static const initial = '/';

  static final GoRouter router = GoRouter(
    initialLocation: initial,
    routes: [
      // Auth routes
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),

      // Admin routes
      GoRoute(path: '/', builder: (context, state) => const UserManagementPage()),
      GoRoute(path: '/home', builder: (context, state) => const HomePage()),

      // Mentor routes with ShellRoute (sidebar + content)
      ShellRoute(
        builder: (context, state, child) {
          return MentorShell(child: child);
        },
        routes: [
          // Mentor Dashboard
          GoRoute(
            path: '/mentor/dashboard',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: MentorDashboard(),
            ),
          ),

          // Mentor Courses list
          GoRoute(
            path: '/mentor/courses',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: MentorCourse(),
            ),
            routes: [
              // Course detail
              GoRoute(
                path: ':id',
                builder: (context, state) {
                  final id = state.pathParameters['id'] ?? '';
                  final title = state.uri.queryParameters['title'] ?? 'Chi tiết khóa học';
                  final mentorName = state.uri.queryParameters['mentor'] ?? 'Mentor';

                  if (isWebPlatform) {
                    return MentorCourseDetailWeb(
                      title: title,
                      mentorName: mentorName,
                    );
                  }
                  return MentorCourseDetailMobile(
                    title: title,
                    mentorName: mentorName,
                  );
                },
                routes: [
                  // Edit course
                  GoRoute(
                    path: 'edit',
                    builder: (context, state) {
                      final title = state.uri.queryParameters['title'] ?? '';

                      if (isWebPlatform) {
                        return MentorUpdateCourseWeb(
                          title: title,
                          lessons: "10 Chương • 45 Bài học",
                          status: "Published",
                        );
                      }
                      return const MentorUpdateCourseMobile();
                    },
                  ),
                ],
              ),
            ],
          ),

          // Create course - independent sibling route
          GoRoute(
            path: '/mentor/courses/create',
            builder: (context, state) {
              if (isWebPlatform) {
                return const MentorCreateCourseWeb();
              }
              return const MentorCreateCourseMobile();
            },
          ),

          // Mentor Learning Paths
          GoRoute(
            path: '/mentor/learning-paths',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: MentorLearningPath(),
            ),
            routes: [
              // Create learning path
              GoRoute(
                path: 'create',
                builder: (context, state) {
                  if (isWebPlatform) {
                    return const MentorCreateLearningPathWeb();
                  }
                  return const MentorCreateLearningPathMobile();
                },
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
