import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../core/utils/media_url.dart';

/// Full-bleed slide media: renders the dashboard slide's image OR video.
/// Videos auto-play muted + looped (the website hero behavior); any load
/// failure falls back to the provided [fallback] (or a dark gradient), so a
/// bad upload can never blank the screen.
final class SlideMedia extends StatefulWidget {
  const SlideMedia({
    super.key,
    required this.mediaType,
    required this.mediaUrl,
    this.fallback,
    this.fit = BoxFit.cover,
  });

  final String mediaType; // 'image' | 'video'
  final String? mediaUrl;
  final Widget? fallback;
  final BoxFit fit;

  @override
  State<SlideMedia> createState() => _SlideMediaState();
}

final class _SlideMediaState extends State<SlideMedia> {
  VideoPlayerController? _video;
  bool _videoReady = false;

  bool get _isVideo =>
      widget.mediaType.toLowerCase() == 'video' &&
      (widget.mediaUrl ?? '').isNotEmpty;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  @override
  void didUpdateWidget(SlideMedia old) {
    super.didUpdateWidget(old);
    if (old.mediaUrl != widget.mediaUrl ||
        old.mediaType != widget.mediaType) {
      _video?.dispose();
      _video = null;
      _videoReady = false;
      _initVideo();
    }
  }

  Future<void> _initVideo() async {
    if (!_isVideo) return;
    final url = cleanMediaUrl(widget.mediaUrl);
    if (url == null) return;
    try {
      final c = VideoPlayerController.networkUrl(Uri.parse(url));
      _video = c;
      await c.initialize();
      if (!mounted || _video != c) {
        c.dispose();
        return;
      }
      await c.setLooping(true);
      await c.setVolume(0);
      await c.play();
      setState(() => _videoReady = true);
    } catch (_) {
      // Fall through to the image/fallback path.
    }
  }

  @override
  void dispose() {
    _video?.dispose();
    super.dispose();
  }

  Widget get _defaultFallback => const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF23252B), Color(0xFF101116)],
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    if (_videoReady && _video != null) {
      return FittedBox(
        fit: widget.fit,
        clipBehavior: Clip.hardEdge,
        child: SizedBox(
          width: _video!.value.size.width,
          height: _video!.value.size.height,
          child: VideoPlayer(_video!),
        ),
      );
    }
    if (!_isVideo) {
      final url = optimizedImageUrl(
        widget.mediaUrl,
        width: (MediaQuery.sizeOf(context).width *
                MediaQuery.devicePixelRatioOf(context))
            .round(),
      );
      if (url != null) {
        return Image.network(
          url,
          fit: widget.fit,
          gaplessPlayback: true,
          errorBuilder: (_, _, _) =>
              widget.fallback ?? _defaultFallback,
        );
      }
    }
    // Video still loading / failed, or no media at all.
    return widget.fallback ?? _defaultFallback;
  }
}
