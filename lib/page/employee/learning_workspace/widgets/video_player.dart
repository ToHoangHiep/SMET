import 'package:flutter/material.dart';
import 'package:smet/service/employee/lms_service.dart';

class VideoPlayer extends StatefulWidget {
  final String? thumbnailUrl;
  final int videoDurationSeconds;
  final int currentPositionSeconds;
  final VoidCallback? onPlay;

  const VideoPlayer({
    super.key,
    this.thumbnailUrl,
    required this.videoDurationSeconds,
    required this.currentPositionSeconds,
    this.onPlay,
  });

  @override
  State<VideoPlayer> createState() => _VideoPlayerState();
}

class _VideoPlayerState extends State<VideoPlayer> {
  bool _isPlaying = false;
  late double _progress;

  /// Tránh NaN/Infinity khi duration = 0 hoặc dữ liệu API chưa có.
  static double _safeProgressFromSeconds(int current, int total) {
    if (total <= 0) return 0.0;
    final p = current / total;
    if (p.isNaN || p.isInfinite) return 0.0;
    return p.clamp(0.0, 1.0);
  }

  static double _sanitizeProgress(double p) {
    if (p.isNaN || p.isInfinite) return 0.0;
    return p.clamp(0.0, 1.0);
  }

  @override
  void initState() {
    super.initState();
    _progress = _safeProgressFromSeconds(
      widget.currentPositionSeconds,
      widget.videoDurationSeconds,
    );
  }

  @override
  void didUpdateWidget(covariant VideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoDurationSeconds != widget.videoDurationSeconds ||
        oldWidget.currentPositionSeconds != widget.currentPositionSeconds) {
      _progress = _safeProgressFromSeconds(
        widget.currentPositionSeconds,
        widget.videoDurationSeconds,
      );
    }
  }

  void _togglePlay() {
    setState(() {
      _isPlaying = !_isPlaying;
    });
    widget.onPlay?.call();
  }

  @override
  Widget build(BuildContext context) {
    final safeP = _sanitizeProgress(_progress);
    final total = widget.videoDurationSeconds;
    final currentTime =
        total > 0 ? (safeP * total).round().clamp(0, total) : 0;
    final totalTime = total;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Video Area
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Thumbnail / Video
                if (widget.thumbnailUrl != null)
                  Image.network(
                    widget.thumbnailUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: const Color(0xFF1E293B),
                        child: const Center(
                          child: Icon(
                            Icons.play_circle_outline,
                            size: 64,
                            color: Colors.white54,
                          ),
                        ),
                      );
                    },
                  )
                else
                  Container(
                    color: const Color(0xFF1E293B),
                    child: const Center(
                      child: Icon(
                        Icons.play_circle_outline,
                        size: 64,
                        color: Colors.white54,
                      ),
                    ),
                  ),
                
                // Overlay gradient
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
                
                // Play button
                Center(
                  child: GestureDetector(
                    onTap: _togglePlay,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: _isPlaying ? 0 : 80,
                      height: _isPlaying ? 0 : 80,
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
                      child: const Icon(
                        Icons.play_arrow,
                        color: Colors.white,
                        size: 48,
                      ),
                    ),
                  ),
                ),
                
                // Video controls overlay (bottom)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Progress bar
                        _buildProgressBar(),
                        const SizedBox(height: 12),
                        // Controls
                        _buildControls(currentTime, totalTime),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return SliderTheme(
      data: SliderThemeData(
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
        activeTrackColor: const Color(0xFF137FEC),
        inactiveTrackColor: Colors.white.withValues(alpha: 0.2),
        thumbColor: Colors.white,
        overlayColor: const Color(0xFF137FEC).withValues(alpha: 0.2),
      ),
      child: Slider(
        value: _sanitizeProgress(_progress),
        onChanged: (value) {
          setState(() {
            _progress = _sanitizeProgress(value);
          });
        },
      ),
    );
  }

  Widget _buildControls(int currentTime, int totalTime) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Left controls
        Row(
          children: [
            _buildControlButton(
              icon: _isPlaying ? Icons.pause : Icons.play_arrow,
              onTap: _togglePlay,
            ),
            const SizedBox(width: 8),
            _buildControlButton(
              icon: Icons.volume_up,
              onTap: () {},
            ),
            const SizedBox(width: 16),
            Text(
              '${LmsService.formatDuration(currentTime)} / ${LmsService.formatDuration(totalTime)}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        // Right controls
        Row(
          children: [
            _buildControlButton(
              icon: Icons.settings,
              onTap: () {},
            ),
            const SizedBox(width: 8),
            _buildControlButton(
              icon: Icons.fullscreen,
              onTap: () {},
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(
          icon,
          color: Colors.white,
          size: 22,
        ),
      ),
    );
  }
}
