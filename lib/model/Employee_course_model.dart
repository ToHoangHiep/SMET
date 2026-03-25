// ============================================
// COURSE MODELS — Dùng chung cho CourseDetail
// ============================================

import 'package:smet/page/employee/course_detail/widgets/course_syllabus.dart';
import 'package:smet/page/employee/course_detail/widgets/course_reviews.dart';

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
