import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

// Global registry to pause all playing reels when navigating away
class ReelPlaybackRegistry {
  static final Set<VoidCallback> _pauseCallbacks = <VoidCallback>{};

  static void register(VoidCallback cb) => _pauseCallbacks.add(cb);
  static void unregister(VoidCallback cb) => _pauseCallbacks.remove(cb);
  static void pauseAll() {
    for (final cb in List<VoidCallback>.from(_pauseCallbacks)) {
      try { cb(); } catch (_) {}
    }
  }
}

class VideoPlayerWidget extends StatefulWidget {
  final String url;
  final Function(VideoPlayerController)? onControllerReady;
  final bool autoPlay;
  final bool looping;

  const VideoPlayerWidget({
    super.key,
    required this.url,
    this.onControllerReady,
    this.autoPlay = true,
    this.looping = true,
  });

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _controller;
  bool _initialized = false;
  bool _disposed = false;
  late final VoidCallback _pauseSelf;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.url),
      httpHeaders: {
        'User-Agent': 'Flutter Video Player',
        'Accept': 'video/mp4,video/*,*/*',
        'Connection': 'keep-alive',
      },
    );
    _initializeVideo();
    _pauseSelf = () {
      if (mounted && !_disposed && _initialized) {
        _controller.pause();
      }
    };
    ReelPlaybackRegistry.register(_pauseSelf);
  }

  Future<void> _initializeVideo() async {
    try {
      // Add timeout to prevent hanging
      await _controller.initialize().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Video initialization timeout after 30 seconds');
        },
      );
      if (mounted && !_disposed) {
        setState(() {
          _initialized = true;
        });
        if (widget.autoPlay) {
          _controller.play();
        }
        if (widget.looping) {
          _controller.setLooping(true);
        }
        print('Video initialized - Duration: ${_controller.value.duration.inSeconds}s');
        widget.onControllerReady?.call(_controller);
      }
    } catch (e) {
      print('Error initializing video: $e');
    }
  }

  @override
  void dispose() {
    _disposed = true;
    ReelPlaybackRegistry.unregister(_pauseSelf);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    return GestureDetector(
      onTap: () {
        if (_controller.value.isPlaying) {
          _controller.pause();
        } else {
          _controller.play();
        }
      },
      child: VideoPlayer(_controller),
    );
  }
}
