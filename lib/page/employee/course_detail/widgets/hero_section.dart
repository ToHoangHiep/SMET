import 'package:flutter/material.dart';

/// Hero section — modern Coursera-style with:
/// - Blurred image overlay + gradient
/// - "What you'll learn" section (green checkmarks)
/// - Skills chips
/// - Rich instructor info card
class HeroSection extends StatelessWidget {
  final String title;
  final String description;
  final String? imageUrl;
  final String duration;
  final String level;
  final double rating;
  final String studentsCount;
  final bool isBestSeller;
  final String category;
  final String instructorName;
  final String? instructorAvatar;
  final String? instructorBio;
  final List<String>? skills;
  final List<String>? keyLearnings;

  const HeroSection({
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
    required this.instructorName,
    this.instructorAvatar,
    this.instructorBio,
    this.skills,
    this.keyLearnings,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ─── Hero Banner ────────────────────────────────────────
        Container(
          height: 440,
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            image: imageUrl != null
                ? DecorationImage(
                    image: NetworkImage(imageUrl!),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                      Colors.black.withValues(alpha: 0.45),
                      BlendMode.darken,
                    ),
                  )
                : null,
          ),
          child: Stack(
            children: [
              // Gradient overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.transparent,
                        const Color(0xFF0F172A).withValues(alpha: 0.7),
                        const Color(0xFF0F172A),
                      ],
                      stops: const [0.0, 0.3, 0.7, 1.0],
                    ),
                  ),
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.fromLTRB(32, 40, 32, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Badges row
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (isBestSeller)
                          _buildBadge('Bán chạy nhất', const Color(0xFF137FEC)),
                        _buildBadge(category.toUpperCase(),
                            Colors.white.withValues(alpha: 0.2)),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Title
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.2,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),

                    // Description
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.white.withValues(alpha: 0.82),
                        height: 1.5,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 16),

                    // Meta row (rating, level, duration)
                    _buildMetaRow(),
                  ],
                ),
              ),
            ],
          ),
        ),

        // ─── What You'll Learn + Skills section ────────────────
        if ((keyLearnings != null && keyLearnings!.isNotEmpty) ||
            (skills != null && skills!.isNotEmpty))
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 28, 32, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // What you'll learn (left)
                if (keyLearnings != null && keyLearnings!.isNotEmpty)
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Bạn sẽ học được',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 14),
                        ...keyLearnings!
                            .take(4)
                            .map((item) => _buildLearningItem(item)),
                      ],
                    ),
                  ),
                if (keyLearnings != null &&
                    keyLearnings!.isNotEmpty &&
                    skills != null &&
                    skills!.isNotEmpty)
                  const SizedBox(width: 32),

                // Skills (right)
                if (skills != null && skills!.isNotEmpty)
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Kỹ năng đạt được',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: skills!
                              .take(6)
                              .map((skill) => _buildSkillChip(skill))
                              .toList(),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

        // ─── Instructor Card ───────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(32, 20, 32, 0),
          child: _buildInstructorCard(),
        ),
      ],
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildMetaRow() {
    return Row(
      children: [
        _buildMetaItem(Icons.star, '${rating.toStringAsFixed(1)} ($studentsCount)'),
        const SizedBox(width: 20),
        _buildMetaItem(Icons.signal_cellular_alt, level),
        const SizedBox(width: 20),
        _buildMetaItem(Icons.schedule, duration),
      ],
    );
  }

  Widget _buildMetaItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.white70),
        const SizedBox(width: 5),
        Text(
          text,
          style: const TextStyle(fontSize: 13, color: Colors.white70),
        ),
      ],
    );
  }

  Widget _buildLearningItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 2),
            child: const Icon(
              Icons.check_circle,
              size: 18,
              color: Color(0xFF22C55E),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF475569),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillChip(String skill) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF137FEC).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF137FEC).withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        skill,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFF137FEC),
        ),
      ),
    );
  }

  Widget _buildInstructorCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF137FEC),
              image: instructorAvatar != null
                  ? DecorationImage(
                      image: NetworkImage(instructorAvatar!),
                      fit: BoxFit.cover,
                    )
                  : null,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF137FEC).withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: instructorAvatar == null
                ? const Icon(Icons.person, size: 28, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 16),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Giảng viên',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  instructorName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                if (instructorBio != null && instructorBio!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    instructorBio!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF64748B),
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
