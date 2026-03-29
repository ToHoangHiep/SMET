import 'package:flutter/material.dart';

/// Refactor từ course_instructor.dart
/// - Thêm "Top Instructor" badge
/// - Social links có thể click được
class InstructorSection extends StatelessWidget {
  final String name;
  final String title;
  final String? avatarUrl;
  final String bio;
  final String? linkedInUrl;
  final String? websiteUrl;
  final bool isTopInstructor;

  const InstructorSection({
    super.key,
    required this.name,
    required this.title,
    this.avatarUrl,
    required this.bio,
    this.linkedInUrl,
    this.websiteUrl,
    this.isTopInstructor = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF137FEC).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF137FEC).withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Title ───
          const Text(
            'Giảng viên',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 20),

          // ─── Content row ───
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: const Color(0xFFE2E8F0),
                  image: avatarUrl != null
                      ? DecorationImage(
                          image: NetworkImage(avatarUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: avatarUrl == null
                    ? const Icon(
                        Icons.person,
                        size: 44,
                        color: Color(0xFF94A3B8),
                      )
                    : null,
              ),
              const SizedBox(width: 20),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name + Top Instructor badge
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        if (isTopInstructor) ...[
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFBBF24).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFFBBF24).withValues(alpha: 0.4),
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.star,
                                  size: 12,
                                  color: Color(0xFFB45309),
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Top Instructor',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFB45309),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Title
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF137FEC),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Bio
                    Text(
                      bio,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF475569),
                        height: 1.6,
                      ),
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 16),

                    // Social links
                    Row(
                      children: [
                        if (linkedInUrl != null)
                          _SocialLinkButton(
                            icon: Icons.business,
                            label: 'LinkedIn',
                            url: linkedInUrl!,
                          ),
                        if (websiteUrl != null) ...[
                          const SizedBox(width: 12),
                          _SocialLinkButton(
                            icon: Icons.language,
                            label: 'Website',
                            url: websiteUrl!,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SocialLinkButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String url;

  const _SocialLinkButton({
    required this.icon,
    required this.label,
    required this.url,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        // TODO: Mở URL bằng url_launcher
        // import 'package:url_launcher/url_launcher.dart';
        // if (await canLaunchUrl(Uri.parse(url))) {
        //   await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
        // }
        debugPrint('Open URL: $url');
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: const Color(0xFF64748B)),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.open_in_new,
              size: 12,
              color: Color(0xFF94A3B8),
            ),
          ],
        ),
      ),
    );
  }
}
