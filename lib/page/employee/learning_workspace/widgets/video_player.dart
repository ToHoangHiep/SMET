// ─────────────────────────────────────────────────────────────
// Main entry point — uses conditional import to select the
// right implementation based on platform (web vs mobile)
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'video_player_web_stub.dart'
    if (dart.library.html) 'video_player_web.dart'
    as platform;

// Re-export so callers can use YoutubePlayerController.convertUrlToId
export 'package:youtube_player_iframe/youtube_player_iframe.dart';

class VideoPlayerWidget extends StatefulWidget {
  final String? youtubeVideoId;
  final String? thumbnailUrl;
  final int videoDurationSeconds;
  final int currentPositionSeconds;
  final VoidCallback? onPlay;
  final VoidCallback? onVideoComplete;

  const VideoPlayerWidget({
    super.key,
    this.youtubeVideoId,
    this.thumbnailUrl,
    this.videoDurationSeconds = 0,
    this.currentPositionSeconds = 0,
    this.onPlay,
    this.onVideoComplete,
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

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: _buildContent(videoId),
      ),
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
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withValues(alpha: 0.3),
                Colors.black.withValues(alpha: 0.7),
              ],
            ),
          ),
        ),
        Center(
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF137FEC),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF137FEC).withValues(alpha: 0.4),
                  blurRadius: 20,
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
        child: Icon(Icons.play_circle_outline, size: 80, color: Colors.white54),
      ),
    );
  }
}
