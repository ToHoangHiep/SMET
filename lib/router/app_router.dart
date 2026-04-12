import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smet/model/user_model.dart';
import 'package:smet/page/admin/department_management/screen/department_management.dart';
import 'package:smet/page/admin/department_management/screen/department_detail_base.dart';
import 'package:smet/page/admin/user_management/screen/user_management.dart';
import 'package:smet/page/admin/course_preview/admin_course_preview_base.dart';
import 'package:smet/page/admin/assignment/screen/assignment_management_page.dart';
import 'package:smet/page/admin/widgets/admin_shell.dart';
import 'package:smet/page/first_login_password/first_login_password_page.dart';
import 'package:smet/page/employee/course_catalog/screen/course_catalog_base.dart';
import 'package:smet/page/employee/course_detail/screen/course_detail_base.dart';
import 'package:smet/page/employee/dashboard/screen/employee_dashboard_base.dart';
import 'package:smet/page/employee/learning_workspace/screen/learning_workspace_base.dart';
import 'package:smet/page/employee/quiz/screen/quiz_page.dart';
import 'package:smet/page/employee/quiz/screen/quiz_history_page.dart';
import 'package:smet/page/employee/quiz/screen/quiz_detail_page.dart';
import 'package:smet/page/employee/learning_path/screen/learning_path_page.dart';
import 'package:smet/page/employee/my_courses/screen/my_courses_base.dart';
import 'package:smet/page/employee/certificate/screen/certificate_page.dart';
import 'package:smet/page/employee/live_session/screen/employee_live_session.dart';
import 'package:smet/page/employee/search/screen/search_page.dart';
import 'package:smet/page/employee/widgets/shell/employee_shell.dart';
import 'package:smet/page/home/home.dart';
import 'package:smet/page/login/login.dart';
import 'package:smet/page/auth/forgot_password/forgot_password_web.dart';
import 'package:smet/page/auth/forgot_password/forgot_password_mobile.dart';
import 'package:smet/page/auth/reset_password/reset_password_web.dart';
import 'package:smet/page/auth/reset_password/reset_password_mobile.dart';
import 'package:smet/page/auth/verify_email/verify_email_web.dart';
import 'package:smet/page/auth/verify_email/verify_email_mobile.dart';
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
import 'package:smet/page/notification/screen/notification_page.dart';
import 'package:smet/page/profile/screen/profile.dart';
import 'package:smet/page/project_manager/dashboard/screen/pm_dashboard_base.dart';
import 'package:smet/page/project_manager/learning_path/screen/learning_path_base.dart';
import 'package:smet/page/project_manager/project/screen/project_management_base.dart';
import 'package:smet/page/project_manager/project_review/screen/pm_project_reviews_page.dart';
import 'package:smet/page/project_manager/project_member/screen/project_member_base.dart';
import 'package:smet/page/project_manager/project_progress/screen/project_progress_base.dart';
import 'package:smet/page/project_manager/widgets/shell/pm_shell.dart';
import 'package:smet/page/mentor/mentor_quiz/mentor_create_quiz_web.dart';
import 'package:smet/page/mentor/mentor_course_report/mentor_course_report.dart';
import 'package:smet/page/mentor/mentor_course_report_detail/mentor_course_report_detail.dart';
import 'package:smet/page/mentor/mentor_live_session/screen/mentor_live_session.dart';
import 'package:smet/page/mentor/mentor_review_assignment/mentor_review_assignment.dart';
import 'package:smet/page/mentor/mentor_students/mentor_students.dart';
import 'package:smet/page/mentor/mentor_quiz_review/mentor_quiz_review.dart';
import 'package:smet/page/employee/projects/screen/employee_projects_base.dart';
import 'package:smet/page/mentor/projects/screen/mentor_projects_base.dart';
import 'package:smet/page/report/screens/report_list_screen.dart';
import 'package:smet/page/report/screens/report_detail_screen.dart';
import 'package:smet/page/report/screens/edit_report_screen.dart';
import 'package:smet/page/report/screens/version_history_screen.dart';
import 'package:smet/page/report/shared/report_shell.dart';
import 'package:smet/page/chat/screen/chat_list_page.dart';
import 'package:smet/page/chat/screen/chat_page.dart';
import 'package:smet/service/common/auth_guard_service.dart';
import 'package:smet/service/common/auth_service.dart';

final bool isWebPlatform = kIsWeb;

class AppPages {
  AppPages._();

  static const initial = '/login';

  static Future<String?> _authRedirect(
      BuildContext context, GoRouterState state) async {
    final token = await AuthService.getToken();
    if (token == null) return '/login';

    final path = state.uri.path;

    try {
      final user = await AuthService.getCurrentUser();

      // Phân quyền theo role — chặn mọi route không thuộc phạm vi role
      if (path.startsWith('/admin') && user.role != UserRole.ADMIN) {
        return AuthGuardService.getRedirectPath(user.role);
      }
      if (path.startsWith('/mentor') &&
          user.role != UserRole.MENTOR &&
          user.role != UserRole.ADMIN) {
        return AuthGuardService.getRedirectPath(user.role);
      }
      if (path.startsWith('/pm') &&
          user.role != UserRole.PROJECT_MANAGER &&
          user.role != UserRole.ADMIN) {
        return AuthGuardService.getRedirectPath(user.role);
      }
      if (path.startsWith('/user_management') ||
          path.startsWith('/department_management') ||
          path.startsWith('/assignment_management') ||
          path.startsWith('/admin')) {
        if (user.role != UserRole.ADMIN) {
          return AuthGuardService.getRedirectPath(user.role);
        }
      }
      if (path.startsWith('/employee')) {
        if (user.role != UserRole.USER &&
            user.role != UserRole.ADMIN &&
            user.role != UserRole.MENTOR &&
            user.role != UserRole.PROJECT_MANAGER) {
          return AuthGuardService.getRedirectPath(user.role);
        }
      }
    } catch (_) {
      return '/login';
    }

    return null;
  }

  static final GoRouter router = GoRouter(
    initialLocation: initial,
    redirect: (context, state) async {
      final path = state.uri.path;

      // Public routes — skip guard
      if (path == '/login' ||
          path == '/first-login-password' ||
          path == '/home' ||
          path == '/forgot-password' ||
          path == '/reset-password' ||
          path == '/verify-email') {
        return null;
      }

      // Authenticated routes — check auth + role
      return _authRedirect(context, state);
    },
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

          // Mentor Course Report
          GoRoute(
            path: '/mentor/course-report',
            pageBuilder:
                (context, state) =>
                    const NoTransitionPage(child: MentorCourseReport()),
          ),

          // Mentor Course Report Detail
          GoRoute(
            path: '/mentor/course-report-detail',
            pageBuilder: (context, state) {
              final courseId = state.uri.queryParameters['courseId'];
              return NoTransitionPage(
                child: MentorCourseReportDetail(courseId: courseId),
              );
            },
          ),

          // Mentor Live Session
          GoRoute(
            path: '/mentor/live-sessions',
            pageBuilder:
                (context, state) =>
                    const NoTransitionPage(child: MentorLiveSession()),
          ),

          // Mentor Review Assignment
          GoRoute(
            path: '/mentor/review-assignments',
            pageBuilder:
                (context, state) =>
                    const NoTransitionPage(child: MentorReviewAssignment()),
          ),

          // Mentor Quiz Review
          GoRoute(
            path: '/mentor/quiz-review',
            pageBuilder:
                (context, state) =>
                    const NoTransitionPage(child: MentorQuizReview()),
          ),

          // Mentor Students
          GoRoute(
            path: '/mentor/students',
            pageBuilder:
                (context, state) =>
                    const NoTransitionPage(child: MentorStudents()),
          ),

          // Mentor Projects (MENTOR role)
          GoRoute(
            path: '/mentor/projects',
            pageBuilder:
                (context, state) =>
                    const NoTransitionPage(child: MentorProjectsPage()),
          ),

          // Mentor Chat
          GoRoute(
            path: '/mentor/chat',
            pageBuilder:
                (context, state) =>
                    const NoTransitionPage(child: ChatListPage(primaryColor: Color(0xFF6366F1), rolePrefix: 'mentor')),
            routes: [
              GoRoute(
                path: ':roomId',
                builder: (context, state) {
                  final roomId = int.tryParse(state.pathParameters['roomId'] ?? '') ?? 0;
                  return ChatPage(
                    roomId: roomId,
                    primaryColor: const Color(0xFF6366F1),
                    rolePrefix: 'mentor',
                  );
                },
              ),
            ],
          ),

          // Mentor Create / Edit Quiz (mở từ chi tiết khóa học — module / final)
          GoRoute(
            path: '/mentor/quizzes/create',
            builder: (context, state) {
              final quizId = state.uri.queryParameters['quizId'];
              final moduleId = state.uri.queryParameters['moduleId'];
              final courseId = state.uri.queryParameters['courseId'];
              final isFinalQuiz = state.uri.queryParameters['final'] == 'true';

              // quizId != null → edit mode, quizId == null → create mode
              return MentorCreateQuizWeb(
                quizId: quizId,
                moduleId: moduleId,
                courseId: courseId,
                isFinalQuiz: isFinalQuiz,
              );
            },
          ),
        ],
      ),

      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) {
          if (kIsWeb || MediaQuery.of(context).size.width > 800) {
            return const ForgotPasswordWeb();
          }
          return const ForgotPasswordMobile();
        },
      ),
      GoRoute(
        path: '/reset-password',
        builder: (context, state) {
          final token = state.uri.queryParameters['token'];
          if (kIsWeb || MediaQuery.of(context).size.width > 800) {
            return ResetPasswordWeb(token: token);
          }
          return ResetPasswordMobile(token: token);
        },
      ),
      GoRoute(
        path: '/verify-email',
        builder: (context, state) {
          final token = state.uri.queryParameters['token'];
          if (kIsWeb || MediaQuery.of(context).size.width > 800) {
            return VerifyEmailWeb(token: token);
          }
          return VerifyEmailMobile(token: token);
        },
      ),
      GoRoute(
        path: '/first-login-password',
        builder: (context, state) => const FirstLoginPasswordPage(),
      ),
      GoRoute(path: '/home', builder: (context, state) => const HomePage()),
      // Admin routes — wrapped in ShellRoute with AdminShell (auth guard + sidebar)
      ShellRoute(
        builder: (context, state, child) => AdminShell(child: child),
        routes: [
          GoRoute(
            path: '/user_management',
            builder: (context, state) => const UserManagementPage(),
          ),
          GoRoute(
            path: '/department_management',
            builder: (context, state) => const DepartmentManagementPage(),
          ),
          GoRoute(
            path: '/department_management/:id',
            builder: (context, state) {
              final id = state.pathParameters['id'] ?? '';
              return DepartmentDetailPage(departmentId: int.tryParse(id) ?? 0);
            },
          ),
          GoRoute(
            path: '/admin/course-preview/:courseId',
            builder: (context, state) {
              final courseId = state.pathParameters['courseId'] ?? '';
              return AdminCoursePreviewPage(courseId: courseId);
            },
          ),
          GoRoute(
            path: '/admin/course/:id',
            pageBuilder: (context, state) {
              final courseId = state.pathParameters['id'] ?? '';
              return NoTransitionPage(child: AdminCoursePreviewPage(courseId: courseId));
            },
          ),
          GoRoute(
            path: '/assignment_management',
            builder: (context, state) => const AssignmentManagementPage(),
          ),
        ],
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfilePage(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationPage(),
      ),

      // Project Manager Routes — wrapped in ShellRoute with PmShell
      ShellRoute(
        builder: (context, state, child) => PmShell(child: child),
        routes: [
          GoRoute(
            path: '/pm/dashboard',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: ProjectManagerDashboardPage()),
          ),
          GoRoute(
            path: '/pm/projects',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: ProjectManagementPage()),
          ),
          GoRoute(
            path: '/pm/project-reviews',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: PmProjectReviewsPage()),
          ),
          GoRoute(
            path: '/pm/project_members',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: ProjectMemberPage()),
          ),
          GoRoute(
            path: '/pm/project_progress',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: ProjectProgressPage()),
          ),
          GoRoute(
            path: '/pm/learning_path',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: LearningPathPage()),
          ),
        ],
      ),

      // Report Routes — unified shell with dynamic role-based sidebar
      ShellRoute(
        builder: (context, state, child) => ReportShell(child: child),
        routes: [
          // Report List
          GoRoute(
            path: '/reports',
            pageBuilder: (context, state) {
              final cachedUser = AuthService.currentUserCached;
              final role = cachedUser?.role ?? UserRole.USER;
              return NoTransitionPage(
                child: ReportListScreen(
                  currentRole: role,
                  primaryColor: _reportColor(role),
                  rolePrefix: _rolePrefix(role),
                ),
              );
            },
          ),
          // Report Detail
          GoRoute(
            path: '/report/:reportId',
            pageBuilder: (context, state) {
              final id = int.tryParse(state.pathParameters['reportId'] ?? '0') ?? 0;
              final cachedUser = AuthService.currentUserCached;
              final role = cachedUser?.role ?? UserRole.USER;
              return NoTransitionPage(
                child: ReportDetailScreen(
                  reportId: id,
                  currentRole: role,
                  currentUserId: cachedUser?.id ?? 0,
                  primaryColor: _reportColor(role),
                  rolePrefix: _rolePrefix(role),
                ),
              );
            },
          ),
          // Edit Report
          GoRoute(
            path: '/report/edit/:reportId',
            pageBuilder: (context, state) {
              final id = int.tryParse(state.pathParameters['reportId'] ?? '0') ?? 0;
              final cachedUser = AuthService.currentUserCached;
              final role = cachedUser?.role ?? UserRole.USER;
              return NoTransitionPage(
                child: EditReportScreen(
                  reportId: id,
                  currentRole: role,
                  currentUserId: cachedUser?.id ?? 0,
                  primaryColor: _reportColor(role),
                  rolePrefix: _rolePrefix(role),
                ),
              );
            },
          ),
          // Version History
          GoRoute(
            path: '/report/history/:reportId',
            pageBuilder: (context, state) {
              final id = int.tryParse(state.pathParameters['reportId'] ?? '0') ?? 0;
              final cachedUser = AuthService.currentUserCached;
              final role = cachedUser?.role ?? UserRole.USER;
              return NoTransitionPage(
                child: VersionHistoryScreen(
                  reportId: id,
                  primaryColor: _reportColor(role),
                  rolePrefix: _rolePrefix(role),
                ),
              );
            },
          ),
        ],
      ),

      // Employee Routes with ShellRoute (shared sidebar)
      ShellRoute(
        builder: (context, state, child) => EmployeeShell(child: child),
        routes: [
          GoRoute(
            path: '/employee/dashboard',
            pageBuilder:
                (context, state) =>
                    const NoTransitionPage(child: EmployeeDashboardPage()),
          ),
          GoRoute(
            path: '/employee/my-courses',
            pageBuilder:
                (context, state) =>
                    const NoTransitionPage(child: MyCoursesPage()),
          ),
          GoRoute(
            path: '/employee/courses',
            pageBuilder:
                (context, state) =>
                    const NoTransitionPage(child: CourseCatalogPage()),
          ),
          GoRoute(
            path: '/employee/course/:id',
            pageBuilder:
                (context, state) {
                  final courseId = state.pathParameters['id'] ?? '';
                  final from = state.uri.queryParameters['from'];
                  return NoTransitionPage(
                    child: CourseDetailPage(courseId: courseId, from: from),
                  );
                },
          ),
          GoRoute(
            path: '/employee/learn/:courseId',
            pageBuilder:
                (context, state) {
                  final courseId = state.pathParameters['courseId'] ?? '';
                  final quizId = state.uri.queryParameters['quizId'];
                  final learningPathId = state.uri.queryParameters['learningPathId'];
                  final from = state.uri.queryParameters['from'];
                  return NoTransitionPage(
                    child: LearningWorkspacePage(
                      courseId: courseId,
                      quizId: quizId,
                      learningPathId: learningPathId,
                      from: from,
                    ),
                  );
                },
          ),
          GoRoute(
            path: '/employee/learn/:courseId/quiz/:quizId',
            pageBuilder:
                (context, state) {
                  final courseId = state.pathParameters['courseId'] ?? '';
                  final quizId = state.pathParameters['quizId'] ?? '';
                  final learningPathId = state.uri.queryParameters['learningPathId'];
                  final from = state.uri.queryParameters['from'];
                  return NoTransitionPage(
                    child: LearningWorkspacePage(
                      courseId: courseId,
                      quizId: quizId,
                      learningPathId: learningPathId,
                      from: from,
                    ),
                  );
                },
          ),
          GoRoute(
            path: '/employee/learn/:courseId/:lessonId',
            pageBuilder:
                (context, state) {
                  final courseId = state.pathParameters['courseId'] ?? '';
                  final lessonId = state.pathParameters['lessonId'] ?? '';
                  final learningPathId = state.uri.queryParameters['learningPathId'];
                  final from = state.uri.queryParameters['from'];
                  return NoTransitionPage(
                    child: LearningWorkspacePage(
                      courseId: courseId,
                      lessonId: lessonId,
                      learningPathId: learningPathId,
                      from: from,
                    ),
                  );
                },
          ),
          GoRoute(
            path: '/employee/quiz/:quizId',
            pageBuilder:
                (context, state) {
                  final quizId = state.pathParameters['quizId'] ?? '';
                  final courseId = state.uri.queryParameters['courseId'];
                  final attemptId = state.uri.queryParameters['attemptId'];
                  return NoTransitionPage(
                    child: QuizPage(
                      quizId: quizId,
                      courseId: courseId,
                      attemptId: attemptId,
                    ),
                  );
                },
          ),
          GoRoute(
            path: '/employee/quiz-detail/:quizId',
            pageBuilder:
                (context, state) {
                  final quizId = state.pathParameters['quizId'] ?? '';
                  final courseId = state.uri.queryParameters['courseId'];
                  return NoTransitionPage(
                    child: QuizDetailPage(quizId: quizId, courseId: courseId),
                  );
                },
          ),
          GoRoute(
            path: '/employee/quiz-history/:quizId',
            pageBuilder:
                (context, state) {
                  final quizId = state.pathParameters['quizId'] ?? '';
                  final quizTitle =
                      state.uri.queryParameters['title'] ?? 'Bài kiểm tra';
                  return NoTransitionPage(
                    child: QuizHistoryPage(
                      quizId: quizId,
                      quizTitle: quizTitle,
                    ),
                  );
                },
          ),
          GoRoute(
            path: '/employee/my-learning-paths',
            pageBuilder:
                (context, state) =>
                    const NoTransitionPage(child: EmployeeLearningPathPage()),
          ),
          GoRoute(
            path: '/employee/certificates',
            pageBuilder:
                (context, state) {
                  final courseId = state.uri.queryParameters['courseId'];
                  return NoTransitionPage(
                    child: CertificatePage(courseId: courseId),
                  );
                },
          ),
          GoRoute(
            path: '/employee/live-sessions',
            pageBuilder: (context, state) {
              final courseId = state.uri.queryParameters['courseId'];
              return NoTransitionPage(
                child: EmployeeLiveSession(courseId: courseId),
              );
            },
          ),
          GoRoute(
            path: '/employee/live-sessions-hub',
            pageBuilder: (context, state) {
              final courseId = state.uri.queryParameters['courseId'];
              return NoTransitionPage(
                child: EmployeeLiveSession(courseId: courseId),
              );
            },
          ),

          // Employee Projects (LEAD + MEMBER)
          GoRoute(
            path: '/employee/projects',
            pageBuilder:
                (context, state) =>
                    const NoTransitionPage(child: EmployeeProjectsPage()),
          ),

          GoRoute(
            path: '/search',
            pageBuilder:
                (context, state) =>
                    const NoTransitionPage(child: SearchPage()),
          ),

          // Employee Chat
          GoRoute(
            path: '/employee/chat',
            pageBuilder:
                (context, state) =>
                    const NoTransitionPage(child: ChatListPage(primaryColor: Color(0xFF137FEC), rolePrefix: 'employee')),
            routes: [
              GoRoute(
                path: ':roomId',
                builder: (context, state) {
                  final roomId = int.tryParse(state.pathParameters['roomId'] ?? '') ?? 0;
                  return ChatPage(
                    roomId: roomId,
                    primaryColor: const Color(0xFF137FEC),
                    rolePrefix: 'employee',
                  );
                },
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

// ================================================================
// REPORT ROUTER HELPERS
// Shared color + prefix helpers for report screens
// ================================================================

Color _reportColor(UserRole role) {
  switch (role) {
    case UserRole.ADMIN:
    case UserRole.MENTOR:
      return const Color(0xFF6366F1);
    case UserRole.PROJECT_MANAGER:
    case UserRole.USER:
      return const Color(0xFF137FEC);
  }
}

String _rolePrefix(UserRole role) {
  switch (role) {
    case UserRole.ADMIN:
      return 'admin';
    case UserRole.PROJECT_MANAGER:
      return 'pm';
    case UserRole.MENTOR:
      return 'mentor';
    case UserRole.USER:
      return 'employee';
  }
}