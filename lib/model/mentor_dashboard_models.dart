// ============================================
// MENTOR DASHBOARD - Data Models
// Tổng hợp dữ liệu từ nhiều nguồn cho dashboard
// ============================================

import 'package:smet/model/course_model.dart';
import 'package:smet/model/mentor_enrollment_model.dart';
import 'package:smet/model/mentor_live_session_model.dart';
import 'package:smet/model/project_model.dart';

// ============================================
// MAIN DASHBOARD DATA
// ============================================

class MentorDashboardData {
  final String userName;
  final String userRole;
  final List<CourseResponse> courses;
  final List<MentorEnrollmentInfo> allEnrollments;
  final List<LiveSessionInfo> upcomingSessions;
  final List<ProjectModel> projects;

  MentorDashboardData({
    required this.userName,
    required this.userRole,
    required this.courses,
    required this.allEnrollments,
    required this.upcomingSessions,
    required this.projects,
  });
}

// ============================================
// STATS CARD
// ============================================

class MentorDashboardStats {
  final int totalCourses;
  final int publishedCourses;
  final int draftCourses;
  final int totalStudents;
  final int activeStudents;
  final int completedStudents;
  final int overdueStudents;
  final int upcomingSessions;
  final int totalProjects;
  final int pendingReviewProjects;

  MentorDashboardStats({
    required this.totalCourses,
    required this.publishedCourses,
    required this.draftCourses,
    required this.totalStudents,
    required this.activeStudents,
    required this.completedStudents,
    required this.overdueStudents,
    required this.upcomingSessions,
    required this.totalProjects,
    required this.pendingReviewProjects,
  });

  factory MentorDashboardStats.empty() => MentorDashboardStats(
        totalCourses: 0,
        publishedCourses: 0,
        draftCourses: 0,
        totalStudents: 0,
        activeStudents: 0,
        completedStudents: 0,
        overdueStudents: 0,
        upcomingSessions: 0,
        totalProjects: 0,
        pendingReviewProjects: 0,
      );

  factory MentorDashboardStats.fromData({
    required List<CourseResponse> courses,
    required List<MentorEnrollmentInfo> enrollments,
    required List<LiveSessionInfo> sessions,
    required List<ProjectModel> projects,
  }) {
    final now = DateTime.now();

    final published = courses.where((c) => c.published).length;
    final draft = courses.where((c) => !c.published).length;

    final active = enrollments
        .where((e) => e.status == EnrollmentStatus.IN_PROGRESS)
        .length;
    final completed = enrollments
        .where((e) => e.status == EnrollmentStatus.COMPLETED)
        .length;
    final overdue = enrollments.where((e) => e.isOverdue).length;

    final upcoming = sessions.where((s) {
      if (s.startTime == null) return false;
      return s.startTime!.isAfter(now);
    }).length;

    final pendingProjects = projects.where((p) {
      return p.status == ProjectStatus.ACTIVE;
    }).length;

    return MentorDashboardStats(
      totalCourses: courses.length,
      publishedCourses: published,
      draftCourses: draft,
      totalStudents: enrollments
          .map((e) => e.userId.value)
          .toSet()
          .length,
      activeStudents: active,
      completedStudents: completed,
      overdueStudents: overdue,
      upcomingSessions: upcoming,
      totalProjects: projects.length,
      pendingReviewProjects: pendingProjects,
    );
  }
}

// ============================================
// COURSE OVERVIEW ITEM
// ============================================

class CourseOverviewItem {
  final CourseResponse course;
  final int studentCount;
  final int avgProgress;
  final int overdueCount;

  CourseOverviewItem({
    required this.course,
    required this.studentCount,
    required this.avgProgress,
    required this.overdueCount,
  });

  factory CourseOverviewItem.from(
    CourseResponse course,
    List<MentorEnrollmentInfo> enrollments,
  ) {
    final courseEnrollments = enrollments
        .where((e) => e.courseId.value == course.id.value)
        .toList();

    final studentCount = courseEnrollments.length;
    final avgProgress = studentCount > 0
        ? (courseEnrollments.fold<int>(
                    0, (sum, e) => sum + e.progress) ~/
                studentCount)
            .toInt()
        : 0;
    final overdueCount =
        courseEnrollments.where((e) => e.isOverdue).length;

    return CourseOverviewItem(
      course: course,
      studentCount: studentCount,
      avgProgress: avgProgress,
      overdueCount: overdueCount,
    );
  }
}

// ============================================
// OVERDUE STUDENT ITEM
// ============================================

class OverdueStudentItem {
  final MentorEnrollmentInfo enrollment;
  final String courseTitle;

  OverdueStudentItem({
    required this.enrollment,
    required this.courseTitle,
  });
}

// ============================================
// UPCOMING SESSION ITEM
// ============================================

class UpcomingSessionItem {
  final LiveSessionInfo session;
  final String courseTitle;
  final bool isToday;
  final bool isSoon;

  UpcomingSessionItem({
    required this.session,
    required this.courseTitle,
    required this.isToday,
    required this.isSoon,
  });

  factory UpcomingSessionItem.from(
    LiveSessionInfo session,
    List<CourseResponse> courses,
  ) {
    final course = courses.cast<CourseResponse?>().firstWhere(
          (c) => c?.id.value == session.courseId.value,
          orElse: () => null,
        );

    final now = DateTime.now();
    final start = session.startTime;
    final diff = start?.difference(now);

    final isToday = start != null &&
        start.year == now.year &&
        start.month == now.month &&
        start.day == now.day;
    final isSoon = diff != null && diff.inMinutes <= 60 && diff.inMinutes > 0;

    return UpcomingSessionItem(
      session: session,
      courseTitle: course?.title ?? '',
      isToday: isToday,
      isSoon: isSoon,
    );
  }
}

// ============================================
// PROJECT OVERVIEW ITEM
// ============================================

class ProjectOverviewItem {
  final ProjectModel project;
  final int memberCount;
  final String stageLabel;

  ProjectOverviewItem({
    required this.project,
    required this.memberCount,
    required this.stageLabel,
  });
}
