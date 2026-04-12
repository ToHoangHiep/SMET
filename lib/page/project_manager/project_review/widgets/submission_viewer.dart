import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// Widget hiển thị nội dung bài nộp dự án (link/video)
class SubmissionViewer extends StatelessWidget {
  final String? submissionLink;

  const SubmissionViewer({
    super.key,
    this.submissionLink,
  });

  @override
  Widget build(BuildContext context) {
    if (submissionLink == null || submissionLink!.isEmpty) {
      return _buildEmptyState();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.link, size: 18, color: Color(0xFF137FEC)),
              const SizedBox(width: 8),
              const Text(
                'Link bài nộp',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.copy, size: 18),
                tooltip: 'Sao chép link',
                onPressed: () => _copyToClipboard(context),
              ),
              IconButton(
                icon: const Icon(Icons.open_in_new, size: 18),
                tooltip: 'Mở trong tab mới',
                onPressed: () => _openLink(context),
              ),
            ],
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: () => _openLink(context),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF137FEC).withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF137FEC).withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.article_outlined,
                    size: 20,
                    color: Color(0xFF137FEC),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      submissionLink!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF137FEC),
                        decoration: TextDecoration.underline,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(
                    Icons.open_in_new,
                    size: 16,
                    color: Color(0xFF137FEC),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildLinkPreview(context),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.link_off, size: 40, color: Colors.grey[400]),
            const SizedBox(height: 8),
            Text(
              'Chưa có link bài nộp',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLinkPreview(BuildContext context) {
    final link = submissionLink!.toLowerCase();

    bool isYoutube = link.contains('youtube.com') || link.contains('youtu.be');
    bool isDrive = link.contains('drive.google.com') ||
        link.contains('docs.google.com');
    bool isGithub = link.contains('github.com');

    if (isYoutube || isDrive || isGithub) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isYoutube)
              const Icon(Icons.play_circle_outline, size: 16, color: Colors.red),
            if (isDrive)
              const Icon(Icons.folder_outlined, size: 16, color: Color(0xFF4285F4)),
            if (isGithub)
              const Icon(Icons.code, size: 16, color: Colors.black87),
            const SizedBox(width: 6),
            Text(
              isYoutube ? 'YouTube Video' :
              isDrive ? 'Google Drive' :
              isGithub ? 'GitHub' : 'Web Link',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: submissionLink!));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Da sao chép link'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _openLink(BuildContext context) async {
    final uri = Uri.tryParse(submissionLink!);
    if (uri == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Link không hợp lệ')),
      );
      return;
    }

    try {
      bool launched = false;
      if (uri.scheme == 'http' || uri.scheme == 'https') {
        launched = await canLaunchUrl(uri);
        if (launched) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      }

      if (!launched) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Không thể mở link: $submissionLink')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi mở link: $e')),
        );
      }
    }
  }
}
