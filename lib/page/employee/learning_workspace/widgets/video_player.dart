import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'video_player_web_stub.dart'
    if (dart.library.html) 'video_player_web.dart'
    as platform;

export 'package:youtube_player_iframe/youtube_player_iframe.dart';

/// Holds the current video progress as a list: [currentSeconds, totalSeconds].
/// Wrapped in a [ValueNotifier] so widgets can listen without triggering parent rebuilds.
final ValueNotifier<List<int>> videoProgressNotifier =
    ValueNotifier<List<int>>([0, 0]);

/// Wrapper that holds YouTube player state independently.
/// Uses ValueNotifier instead of setState to avoid the rebuild loop.
class _YouTubePlayerWrapper extends StatefulWidget {
  final String videoId;
  final String? thumbnailUrl;
  final int videoDurationSeconds;
  final int currentPositionSeconds;
  final VoidCallback? onPlay;
  final VoidCallback? onVideoComplete;
  final void Function(int currentSeconds, int totalSeconds)? onProgress;

  const _YouTubePlayerWrapper({
    super.key,
    required this.videoId,
    this.thumbnailUrl,
    this.videoDurationSeconds = 0,
    this.currentPositionSeconds = 0,
    this.onPlay,
    this.onVideoComplete,
    this.onProgress,
  });

  @override
  State<_YouTubePlayerWrapper> createState() => _YouTubePlayerWrapperState();
}

class _YouTubePlayerWrapperState extends State<_YouTubePlayerWrapper> {
  static int _debugWrapperBuild = 0;
  int _localBuild = ++_debugWrapperBuild;
  static int _debugOnTimeUpdateTotal = 0;

  @override
  Widget build(BuildContext context) {
    debugPrint('[DEBUG _YouTubePlayerWrapper build #$_localBuild] videoId=${widget.videoId} key=${ValueKey(widget.videoId)}');
    return platform.YouTubePlayerView(
      key: ValueKey(widget.videoId),
      videoId: widget.videoId,
      thumbnailUrl: widget.thumbnailUrl,
      videoDurationSeconds: widget.videoDurationSeconds,
      currentPositionSeconds: widget.currentPositionSeconds,
      onPlay: widget.onPlay,
      onVideoComplete: widget.onVideoComplete,
      onProgress: widget.onProgress,
      onTimeUpdate: (current, total) {
        _debugOnTimeUpdateTotal++;
        if (_debugOnTimeUpdateTotal <= 20) {
          debugPrint('[DEBUG _YouTubePlayerWrapper onTimeUpdate #$_debugOnTimeUpdateTotal] current=$current total=$total');
        }
        videoProgressNotifier.value = [current, total];
      },
    );
  }
}

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
  /// Callback: (currentSeconds, totalSeconds). Fires every ~10s while playing, on pause, and on end.
  final void Function(int currentSeconds, int totalSeconds)? onProgress;
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
    this.onProgress,
    this.lessonTitle,
    this.lessonDuration,
  });

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  static int _debugVpBuild = 0;
  int _localVpBuild = ++_debugVpBuild;

  String _resolveVideoId(String? input) {
    if (input == null || input.isEmpty) return '';
    if (RegExp(r'^[a-zA-Z0-9_-]{11}$').hasMatch(input)) return input;
    final extracted = YoutubePlayerController.convertUrlToId(input);
    return extracted ?? '';
  }

  final ValueNotifier<String> _videoIdNotifier = ValueNotifier<String>('');

  @override
  void initState() {
    super.initState();
    _videoIdNotifier.value = _resolveVideoId(widget.youtubeVideoId);
  }

  @override
  void didUpdateWidget(VideoPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    debugPrint('[DEBUG _VideoPlayerWidget didUpdateWidget] oldId=${oldWidget.youtubeVideoId} newId=${widget.youtubeVideoId}');
    final newId = _resolveVideoId(widget.youtubeVideoId);
    if (newId != _videoIdNotifier.value) {
      debugPrint('[DEBUG _VideoPlayerWidget didUpdateWidget] videoId CHANGED, updating notifier');
      _videoIdNotifier.value = newId;
    }
  }

  @override
  void dispose() {
    _videoIdNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('[DEBUG _VideoPlayerWidget build #$_localVpBuild] youtubeVideoId=${widget.youtubeVideoId}');
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
                ValueListenableBuilder<String>(
                  valueListenable: _videoIdNotifier,
                  builder: (context, videoId, _) => _buildContent(videoId),
                ),

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
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Video progress bar
                        ValueListenableBuilder<List<int>>(
                          valueListenable: videoProgressNotifier,
                          builder: (context, progress, _) {
                            final total = progress[1];
                            if (total <= 0) return const SizedBox(height: 3);
                            final current = progress[0];
                            return SizedBox(
                              height: 3,
                              child: Stack(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.3),
                                    ),
                                  ),
                                  FractionallySizedBox(
                                    widthFactor: (current / total).clamp(0.0, 1.0),
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [Color(0xFF137FEC), Color(0xFF22C55E)],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 4),
                      ],
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
                ValueListenableBuilder<List<int>>(
                  valueListenable: videoProgressNotifier,
                  builder: (context, progress, _) {
                    final total = progress[1];
                    final current = progress[0];
                    if (total <= 0) {
                      return const SizedBox(width: 8);
                    }
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(width: 8),
                        Container(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF22C55E).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.visibility,
                                size: 14,
                                color: Color(0xFF22C55E),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${((current / total) * 100).round()}%',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF22C55E),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
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

    return _YouTubePlayerWrapper(
      key: ValueKey('yt_$videoId'),
      videoId: videoId,
      thumbnailUrl: widget.thumbnailUrl,
      videoDurationSeconds: widget.videoDurationSeconds,
      currentPositionSeconds: widget.currentPositionSeconds,
      onPlay: widget.onPlay,
      onVideoComplete: widget.onVideoComplete,
      onProgress: widget.onProgress,
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
