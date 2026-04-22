// ─────────────────────────────────────────────────────────────
// Stub implementation for non-web platforms (mobile)
// video_player_web.dart is used on web via conditional import
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

// YouTubePlayerView is used by VideoPlayerWidget (defined in video_player.dart)
// DO NOT define VideoPlayerWidget here — it is defined in video_player.dart

class YouTubePlayerView extends StatefulWidget {
  final String videoId;
  final String? thumbnailUrl;
  final int videoDurationSeconds;
  final VoidCallback? onPlay;
  final VoidCallback? onVideoComplete;

  const YouTubePlayerView({
    super.key,
    required this.videoId,
    this.thumbnailUrl,
    this.videoDurationSeconds = 0,
    this.onPlay,
    this.onVideoComplete,
  });

  @override
  State<YouTubePlayerView> createState() => _YouTubePlayerViewState();
}

class _YouTubePlayerViewState extends State<YouTubePlayerView> {
  YoutubePlayerController? _controller;
  bool _playbackStarted = false;

  @override
  void initState() {
    super.initState();
    if (widget.videoId.isNotEmpty) {
      _initController();
    }
  }

  void _initController() {
    _controller = YoutubePlayerController.fromVideoId(
      videoId: widget.videoId,
      autoPlay: false,
      params: const YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: true,
        enableCaption: true,
      ),
    );

    _controller!.stream.listen((value) {
      final state = value.playerState;
      switch (state) {
        case PlayerState.playing:
          if (!_playbackStarted) {
            _playbackStarted = true;
            widget.onPlay?.call();
          }
          break;
        case PlayerState.ended:
          widget.onVideoComplete?.call();
          break;
        default:
          break;
      }
    });
  }

  @override
  void didUpdateWidget(covariant YouTubePlayerView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoId != widget.videoId) {
      _controller?.close();
      _playbackStarted = false;
      if (widget.videoId.isNotEmpty) {
        _initController();
      }
    }
  }

  @override
  void dispose() {
    _controller?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.videoId.isEmpty) {
      return _buildNoVideo();
    }

    if (_controller == null) {
      return Container(
        color: const Color(0xFF1E293B),
        child: const Center(
          child: CircularProgressIndicator(color: Color(0xFF137FEC)),
        ),
      );
    }

    return YoutubePlayer(controller: _controller!, aspectRatio: 16 / 9);
  }

  Widget _buildNoVideo() {
    String? imageUrl = widget.thumbnailUrl;
    if ((imageUrl == null || imageUrl.isEmpty) && widget.videoId.isNotEmpty) {
      imageUrl = 'https://img.youtube.com/vi/${widget.videoId}/hqdefault.jpg';
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
