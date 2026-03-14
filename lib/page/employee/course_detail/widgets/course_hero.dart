import 'package:flutter/material.dart';

class CourseHero extends StatelessWidget {
  final String title;
  final String description;
  final String? imageUrl;
  final String duration;
  final String level;
  final double rating;
  final String studentsCount;
  final bool isBestSeller;
  final String category;

  const CourseHero({
    super.key,
    required this.title,
    required this.description,
    this.imageUrl,
    required this.duration,
    required this.level,
    required this.rating,
    required this.studentsCount,
    this.isBestSeller = false,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Hero Banner
        Container(
          height: 320,
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            image: imageUrl != null
                ? DecorationImage(
                    image: NetworkImage(imageUrl!),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  const Color(0xFF0F172A).withValues(alpha: 0.7),
                  const Color(0xFF0F172A),
                ],
              ),
            ),
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Badges
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (isBestSeller)
                      _buildBadge('Bán chạy nhất', const Color(0xFF137FEC)),
                    _buildBadge(category.toUpperCase(), Colors.white.withValues(alpha: 0.2)),
                  ],
                ),
                const SizedBox(height: 16),
                // Title
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                // Description
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withValues(alpha: 0.8),
                    height: 1.5,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
        // Stats Grid
        Container(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              _buildStatItem(Icons.schedule, 'Thời lượng', duration),
              const SizedBox(width: 32),
              _buildStatItem(Icons.signal_cellular_alt, 'Cấp độ', level),
              const SizedBox(width: 32),
              _buildStatItem(Icons.star, 'Đánh giá', '$rating'),
              const SizedBox(width: 32),
              _buildStatItem(Icons.people, 'Học viên', studentsCount),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color == Colors.white.withValues(alpha: 0.2) ? Colors.white : Colors.white,
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF137FEC)),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
