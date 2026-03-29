import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'video_player_web_stub.dart'
    if (dart.library.html) 'video_player_web.dart'
    as platform;

export 'package:youtube_player_iframe/youtube_player_iframe.dart';

/// Video Player — modern Coursera-style:
/// - Rounded container with subtle shadow
/// - Gradient overlay below video for lesson title
/// - Focus dark container
class VideoPlayerWidget extends StatefulWidget {
  final String? youtubeVideoId;
  final String? thumbnailUrl;
  final int videoDurationSeconds;
  final int currentPositionSeconds;
  final VoidCallback? onPlay;
  final VoidCallback? onVideoComplete;
  final String? lessonTitle;
  final String? lessonDuration;

  const VideoPlayerWidget({
    super.key,
    this.youtubeVideoId,
    this.thumbnailUrl,
    this.videoDurationSeconds = 0,
    this.currentPositionSeconds = 0,
    this.onPlay,
    this.onVideoComplete,
    this.lessonTitle,
    this.lessonDuration,
  });

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  String _resolveVideoId(String? input) {
    if (input == null || input.isEmpty) return '';
    if (RegExp(r'^[a-zA-Z0-9_-]{11}$').hasMatch(input)) return input;
    final extracted = YoutubePlayerController.convertUrlToId(input);
    return extracted ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final videoId = _resolveVideoId(widget.youtubeVideoId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Video container — rounded with shadow
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _buildContent(videoId),

                // Gradient overlay at bottom for title area
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: 80,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.7),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Lesson title bar below video
        if (widget.lessonTitle != null || widget.lessonDuration != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
            child: Row(
              children: [
                if (widget.lessonTitle != null)
                  Expanded(
                    child: Text(
                      widget.lessonTitle!,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                if (widget.lessonDuration != null) ...[
                  const SizedBox(width: 12),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.schedule,
                          size: 14,
                          color: Color(0xFF64748B),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          widget.lessonDuration!,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildContent(String videoId) {
    if (videoId.isEmpty) {
      return _buildNoVideo();
    }

    return platform.YouTubePlayerView(
      key: ValueKey(videoId),
      videoId: videoId,
      thumbnailUrl: widget.thumbnailUrl,
      videoDurationSeconds: widget.videoDurationSeconds,
      onPlay: widget.onPlay,
      onVideoComplete: widget.onVideoComplete,
    );
  }

  Widget _buildNoVideo() {
    String? imageUrl = widget.thumbnailUrl;
    if ((imageUrl == null || imageUrl.isEmpty)) {
      imageUrl = null;
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        if (imageUrl != null)
          Image.network(
            imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildPlaceholder(),
          )
        else
          _buildPlaceholder(),

        // Play button with glow
        Center(
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF137FEC),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF137FEC).withValues(alpha: 0.5),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(Icons.play_arrow, color: Colors.white, size: 48),
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: const Color(0xFF1E293B),
      child: const Center(
        child: Icon(Icons.play_circle_outline, size: 80,
            color: Colors.white54),
      ),
    );
  }
}
