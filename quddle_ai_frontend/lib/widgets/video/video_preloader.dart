import 'package:flutter/material.dart';
import 'video_controller_pool.dart';
import 'video_loading_indicator.dart';

class VideoPreloader extends StatefulWidget {
  final String videoId;
  final String videoUrl;
  final Widget child;
  final bool autoPreload;
  final Function(VideoControllerInfo?)? onControllerReady;

  const VideoPreloader({
    super.key,
    required this.videoId,
    required this.videoUrl,
    required this.child,
    this.autoPreload = true,
    this.onControllerReady,
  });

  @override
  State<VideoPreloader> createState() => _VideoPreloaderState();
}

class _VideoPreloaderState extends State<VideoPreloader> {
  final VideoControllerPool _pool = VideoControllerPool();
  VideoControllerInfo? _controllerInfo;
  VideoLoadingState _loadingState = VideoLoadingState.unloaded;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.autoPreload) {
      _preloadVideo();
    }
  }

  Future<void> _preloadVideo() async {
    setState(() {
      _loadingState = VideoLoadingState.loading;
    });

    try {
      final controllerInfo = await _pool.createController(widget.videoId, widget.videoUrl);
      
      if (mounted) {
        setState(() {
          _controllerInfo = controllerInfo;
          _loadingState = controllerInfo != null 
              ? VideoLoadingState.ready 
              : VideoLoadingState.error;
          _errorMessage = controllerInfo == null ? 'Failed to create controller' : null;
        });
        
        widget.onControllerReady?.call(controllerInfo);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingState = VideoLoadingState.error;
          _errorMessage = e.toString();
        });
      }
    }
  }

  Future<void> retry() async {
    await _preloadVideo();
  }

  @override
  void dispose() {
    // Don't dispose controller here as it's managed by the pool
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_loadingState == VideoLoadingState.loading || _loadingState == VideoLoadingState.error)
          VideoLoadingIndicator(
            state: _loadingState,
            errorMessage: _errorMessage,
          ),
      ],
    );
  }
}
