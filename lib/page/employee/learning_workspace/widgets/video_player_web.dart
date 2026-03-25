// ─────────────────────────────────────────────────────────────
// Web implementation: YouTube IFrame via HtmlElementView
// Uses registerViewFactory + JS interop — NO webview_flutter
// ─────────────────────────────────────────────────────────────

import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:web/web.dart' as web;
import 'dart:js_interop';

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
  bool _isPlaying = false;
  bool _hasEnded = false;
  bool _isReady = false;
  bool _factoryRegistered = false;

  /// Mỗi lần mount cần viewType khác nhau. Nếu dùng chung theo videoId,
  /// callback factory vẫn giữ State cũ (đã dispose) → load / setState sai → spinner vô hạn.
  static int _viewSeq = 0;
  late final String _viewType =
      'youtube-iframe-${widget.videoId}-${_viewSeq++}';

  void _parsePlayerState(String data) {
    // State: 0=ended, 1=playing, 2=paused, 3=buffering, -1=unstarted
    if (data.contains('"playerState":1')) {
      if (!_isPlaying) {
        _isPlaying = true;
        widget.onPlay?.call();
      }
    } else if (data.contains('"playerState":0')) {
      if (!_hasEnded) {
        _hasEnded = true;
        widget.onVideoComplete?.call();
      }
    }
  }

  void _setupPostMessageListener() {
    web.window.addEventListener(
      'message',
      ((web.Event event) {
        final msg = (event as web.MessageEvent);
        if (msg.data == null) return;
        try {
          final data = msg.data.toString();
          if (data.contains('"event":"infoDelivery"') ||
              data.contains('"playerState"')) {
            _parsePlayerState(data);
          }
        } catch (_) {}
      }).toJS,
    );
  }

  void _markReady() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() => _isReady = true);
      }
    });
  }

  void _registerFactoryOnce(int width, int height) {
    if (_factoryRegistered) return;
    _factoryRegistered = true;

    final videoId = widget.videoId;
    final embedUrl = Uri.parse(
      'https://www.youtube.com/embed/$videoId'
      '?enablejsapi=1'
      '&playsinline=1'
      '&controls=1'
      '&rel=0'
      '&modestbranding=1'
      '&widget_referrer=${Uri.encodeComponent('smet-app')}',
    ).toString();

    // ignore: undefined_prefixed_name
    ui_web.platformViewRegistry.registerViewFactory(
      _viewType,
      (int viewId) {
        final iframe =
            web.document.createElement('iframe') as web.HTMLIFrameElement;

        iframe.width = '$width';
        iframe.height = '$height';
        iframe.style.width = '${width}px';
        iframe.style.height = '${height}px';
        iframe.style.border = 'none';
        iframe.style.position = 'absolute';
        iframe.style.top = '0';
        iframe.style.left = '0';
        iframe.allow =
            'accelerometer; autoplay; clipboard-write; '
            'encrypted-media; gyroscope; picture-in-picture; web-share';
        iframe.setAttribute('allowfullscreen', 'true');

        // Gắn listener TRƯỚC khi gán src — tránh iframe cache load xong trước khi listen.
        iframe.addEventListener(
          'load',
          ((web.Event e) {
            _setupPostMessageListener();
            _markReady();
          }).toJS,
        );

        iframe.src = embedUrl;

        return iframe;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.videoId.isEmpty) {
      return _buildNoVideo();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.toInt();
        final height = constraints.maxHeight.toInt();

        if (width > 0 && height > 0) {
          _registerFactoryOnce(width, height);

          return SizedBox(
            width: width.toDouble(),
            height: height.toDouble(),
            child: Stack(
              children: [
                HtmlElementView(viewType: _viewType),
                if (!_isReady)
                  Container(
                    color: const Color(0xFF1E293B),
                    child: const Center(
                      child:
                          CircularProgressIndicator(color: Color(0xFF137FEC)),
                    ),
                  ),
              ],
            ),
          );
        }

        return AspectRatio(
          aspectRatio: 16 / 9,
          child: _buildNoVideo(),
        );
      },
    );
  }

  Widget _buildNoVideo() {
    String? imageUrl = widget.thumbnailUrl;
    if (imageUrl == null || imageUrl.isEmpty) {
      if (widget.videoId.isNotEmpty) {
        imageUrl = 'https://img.youtube.com/vi/${widget.videoId}/hqdefault.jpg';
      }
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        if (imageUrl != null)
          Image.network(imageUrl, fit: BoxFit.cover)
        else
          Container(
            color: const Color(0xFF1E293B),
            child: const Center(
              child: Icon(Icons.play_circle_outline,
                  size: 80, color: Colors.white54),
            ),
          ),
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
}
