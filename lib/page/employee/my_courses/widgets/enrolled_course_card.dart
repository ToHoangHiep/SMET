import 'package:flutter/material.dart';
import 'package:smet/service/employee/lms_service.dart';

class EnrolledCourseCard extends StatelessWidget {
  final EnrolledCourse course;
  final VoidCallback? onTap;

  const EnrolledCourseCard({
    super.key,
    required this.course,
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
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            Container(
              height: 140,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                image: course.imageUrl != null
                    ? DecorationImage(
                        image: NetworkImage(course.imageUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: course.imageUrl == null
                  ? const Center(
                      child: Icon(
                        Icons.school,
                        size: 48,
                        color: Color(0xFFCBD5E1),
                      ),
                    )
                  : null,
            ),

            // Progress bar overlay at bottom of image
            Container(
              height: 4,
              margin: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: course.progressPercent / 100,
                child: Container(
                  decoration: BoxDecoration(
                    color: course.progressPercent >= 100
                        ? const Color(0xFF22C55E)
                        : const Color(0xFF137FEC),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),

                  // Progress
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Tiến độ',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                                Text(
                                  '${course.progressPercent.toInt()}%',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: course.progressPercent >= 100
                                        ? const Color(0xFF22C55E)
                                        : const Color(0xFF137FEC),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: course.progressPercent / 100,
                                backgroundColor: const Color(0xFFE2E8F0),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  course.progressPercent >= 100
                                      ? const Color(0xFF22C55E)
                                      : const Color(0xFF137FEC),
                                ),
                                minHeight: 6,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Continue button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onTap,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: course.progressPercent >= 100
                            ? const Color(0xFF22C55E)
                            : const Color(0xFF137FEC),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        course.progressPercent >= 100
                            ? 'Hoàn thành'
                            : course.progressPercent > 0
                                ? 'Tiếp tục học'
                                : 'Bắt đầu học',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
