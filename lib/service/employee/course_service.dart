import 'package:smet/page/employee/course_detail/widgets/course_reviews.dart';
import 'package:smet/page/employee/course_detail/widgets/course_syllabus.dart';

class CourseService {
  // API giả lập - sẽ thay thế bằng API thật sau
  static Future<CourseDetail> getCourseDetail(String courseId) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    // Return mock data - TODO: Thay bằng API thật
    return CourseDetail(
      id: courseId,
      title: 'Advanced Management & Technology Systems',
      description: 'Master the intersection of operational management and cutting-edge engineering technologies in our comprehensive 12-week certification program.',
      imageUrl: 'https://images.unsplash.com/photo-1581092918056-0c4c3acd3789?w=800',
      duration: '12 tuần',
      level: 'Nâng cao',
      rating: 4.9,
      studentsCount: '8.4k+',
      isBestSeller: true,
      category: 'Kỹ thuật',
      videoHours: 45,
      resources: 12,
      hasCertificate: true,
      enrolledCount: 152,
      instructor: Instructor(
        name: 'Dr. Michael Chen',
        title: 'PhD in Systems Engineering, MIT',
        avatarUrl: 'https://images.unsplash.com/photo-1560250097-0b93528c311a?w=200',
        bio: 'With over 20 years of experience in leading engineering teams at Fortune 500 companies, Dr. Chen brings a wealth of practical knowledge to the SMETS program.',
        linkedInUrl: 'https://linkedin.com',
        websiteUrl: 'https://example.com',
      ),
      modules: [
        Module(
          title: 'Foundations of Modern Engineering',
          lessonCount: 4,
          lessons: const [
            'Evolution of Systems Thinking',
            'Agile Methodologies in Engineering',
          ],
          isExpanded: true,
          onToggle: () {},
        ),
        Module(
          title: 'Technological Project Management',
          lessonCount: 6,
          lessons: const [],
          isExpanded: false,
          onToggle: () {},
        ),
        Module(
          title: 'Data-Driven Decision Making',
          lessonCount: 5,
          lessons: const [],
          isExpanded: false,
          onToggle: () {},
        ),
      ],
      reviews: const [
        Review(
          rating: 5,
          comment: 'The curriculum is perfectly balanced between management theory and practical tech application. Highly recommended for senior leads.',
          userName: 'Sarah Jenkins',
        ),
        Review(
          rating: 5,
          comment: 'Changed the way I look at project lifecycles. The insights on modern tech stacks were invaluable.',
          userName: 'Marcus Thorne',
        ),
      ],
    );
  }
}

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
