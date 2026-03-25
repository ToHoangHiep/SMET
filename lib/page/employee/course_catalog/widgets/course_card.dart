import 'package:flutter/material.dart';

enum CourseCategory {
  all,
  technical,
  softSkills,
  leadership,
}

extension CourseCategoryExtension on CourseCategory {
  String get label {
    switch (this) {
      case CourseCategory.all:
        return 'Tất cả';
      case CourseCategory.technical:
        return 'Kỹ thuật';
      case CourseCategory.softSkills:
        return 'Kỹ năng mềm';
      case CourseCategory.leadership:
        return 'Lãnh đạo';
    }
  }

  String get icon {
    switch (this) {
      case CourseCategory.all:
        return '';
      case CourseCategory.technical:
        return 'code';
      case CourseCategory.softSkills:
        return 'forum';
      case CourseCategory.leadership:
        return 'leaderboard';
    }
  }

  Color get color {
    switch (this) {
      case CourseCategory.all:
        return const Color(0xFF137FEC);
      case CourseCategory.technical:
        return const Color(0xFF137FEC);
      case CourseCategory.softSkills:
        return const Color(0xFF22C55E);
      case CourseCategory.leadership:
        return const Color(0xFF8B5CF6);
    }
  }
}

class CourseCard extends StatelessWidget {
  final String title;
  final String? imageUrl;
  final CourseCategory category;
  final double rating;
  final String duration;
  final String? mentorName;
  final VoidCallback? onJoin;
  final VoidCallback? onTap;

  const CourseCard({
    super.key,
    required this.title,
    this.imageUrl,
    required this.category,
    required this.rating,
    required this.duration,
    this.mentorName,
    this.onJoin,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with Stack for badge
            Stack(
              children: [
                Container(
                  height: 140,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                    image: imageUrl != null
                        ? DecorationImage(
                            image: NetworkImage(imageUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: imageUrl == null
                      ? const Center(
                          child: Icon(
                            Icons.school,
                            size: 48,
                            color: Color(0xFFCBD5E1),
                          ),
                        )
                      : null,
                ),
                // Category badge
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: category.color.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      category.label,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    // Mentor name
                    if (mentorName != null && mentorName!.isNotEmpty) ...[
                      Text(
                        mentorName!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                    ],
                    // Spacer
                    const Spacer(),
                    // Footer
                    Row(
                      children: [
                        const Icon(
                          Icons.schedule,
                          size: 14,
                          color: Color(0xFF64748B),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            duration,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (onJoin != null)
                          SizedBox(
                            height: 28,
                            child: ElevatedButton(
                              onPressed: onJoin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF137FEC),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              child: const Text('Tham gia'),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

}
