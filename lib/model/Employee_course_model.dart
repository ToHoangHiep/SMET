// ============================================
// COURSE MODELS — Dùng chung cho CourseDetail
// ============================================

class CourseDetail {
  final String id;
  final String title;
  final String description;
  final String? imageUrl;
  final String duration;
  final String level;
  final double rating;
  final String studentsCount;
  final bool isBestSeller;
  final String category;
  final int videoHours;
  final int resources;
  final bool hasCertificate;
  final int enrolledCount;
  final Instructor instructor;
  final List<Module> modules;
  final List<Review> reviews;

  // --- Fields bổ sung theo phong cách Coursera ---
  final String? departmentName;
  final String? deadlineType;
  final int? defaultDeadlineDays;
  final String? fixedDeadline;

  const CourseDetail({
    required this.id,
    required this.title,
    required this.description,
    this.imageUrl,
    required this.duration,
    required this.level,
    required this.rating,
    required this.studentsCount,
    required this.isBestSeller,
    required this.category,
    required this.videoHours,
    required this.resources,
    required this.hasCertificate,
    required this.enrolledCount,
    required this.instructor,
    required this.modules,
    required this.reviews,
    this.departmentName,
    this.deadlineType,
    this.defaultDeadlineDays,
    this.fixedDeadline,
  });
}

class Instructor {
  final String name;
  final String title;
  final String? avatarUrl;
  final String bio;
  final String? linkedInUrl;
  final String? websiteUrl;

  const Instructor({
    required this.name,
    required this.title,
    this.avatarUrl,
    required this.bio,
    this.linkedInUrl,
    this.websiteUrl,
  });
}

/// Dùng bởi lms_service để parse API response.
class Module {
  final String title;
  final int lessonCount;
  final List<String> lessons;
  final bool isExpanded;

  const Module({
    required this.title,
    required this.lessonCount,
    required this.lessons,
    this.isExpanded = false,
  });
}

/// Dùng bởi lms_service để parse API response.
class Review {
  final double rating;
  final String comment;
  final String userName;
  final String? avatarUrl;

  const Review({
    required this.rating,
    required this.comment,
    required this.userName,
    this.avatarUrl,
  });
}
