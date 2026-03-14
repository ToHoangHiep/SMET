import 'package:flutter/material.dart';

class CourseEnrollCard extends StatelessWidget {
  final VoidCallback onEnroll;
  final VoidCallback? onStartLearning;
  final int videoHours;
  final int resources;
  final bool hasCertificate;
  final int enrolledCount;
  final bool isEnrolled;

  const CourseEnrollCard({
    super.key,
    required this.onEnroll,
    this.onStartLearning,
    this.videoHours = 0,
    this.resources = 0,
    this.hasCertificate = true,
    this.enrolledCount = 0,
    this.isEnrolled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Enroll Button Section
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Free badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF22C55E).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'MIỄN PHÍ',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF22C55E),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Enroll / Start Learning Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isEnrolled ? onStartLearning : onEnroll,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF137FEC),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      isEnrolled ? 'Bắt đầu học' : 'Đăng ký ngay',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Guarantee text
                Text(
                  isEnrolled ? 'Tiếp tục học tập ngay' : 'Tham gia miễn phí - Không phí ẩn',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          // Course includes
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Khóa học bao gồm:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 16),
                // Video hours
                _buildFeatureItem(
                  icon: Icons.videocam_outlined,
                  text: '$videoHours giờ video bài giảng',
                ),
                const SizedBox(height: 12),
                // Resources
                _buildFeatureItem(
                  icon: Icons.download_outlined,
                  text: '$resources tài liệu tải về',
                ),
                const SizedBox(height: 12),
                // Certificate
                _buildFeatureItem(
                  icon: Icons.workspace_premium_outlined,
                  text: hasCertificate ? 'Chứng chỉ hoàn thành' : 'Không có chứng chỉ',
                ),
                const SizedBox(height: 12),
                // Lifetime access
                _buildFeatureItem(
                  icon: Icons.all_inclusive,
                  text: 'Truy cập trọn đời',
                ),
              ],
            ),
          ),
          // Enrolled count
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: Color(0xFFE5E7EB)),
              ),
            ),
            child: Text(
              'Đã có $enrolledCount học viên đăng ký',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF64748B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String text,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: const Color(0xFF137FEC),
        ),
        const SizedBox(width: 12),
        Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF475569),
          ),
        ),
      ],
    );
  }
}
