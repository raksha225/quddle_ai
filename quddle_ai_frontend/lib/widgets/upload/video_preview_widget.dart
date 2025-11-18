import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dart:io';

class VideoPreviewWidget extends StatefulWidget {
  final File videoFile;
  final Function(File)? onConfirm;
  final VoidCallback? onDiscard;
  final bool showControls;

  const VideoPreviewWidget({
    super.key,
    required this.videoFile,
    this.onConfirm,
    this.onDiscard,
    this.showControls = true,
  });

  @override
  State<VideoPreviewWidget> createState() => _VideoPreviewWidgetState();
}

class _VideoPreviewWidgetState extends State<VideoPreviewWidget> {
  VideoPlayerController? _controller;
  bool _initialized = false;
  bool _muted = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    _controller = VideoPlayerController.file(widget.videoFile);
    try {
      await _controller!.initialize();
      if (mounted) {
        setState(() {
          _initialized = true;
        });
        _controller!.play();
        _controller!.setLooping(true);
      }
    } catch (e) {
      print('Error initializing preview video: $e');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // Video Player
            if (_initialized && _controller != null)
              GestureDetector(
                onTap: () {
                  if (_controller!.value.isPlaying) {
                    _controller!.pause();
                  } else {
                    _controller!.play();
                  }
                },
                child: VideoPlayer(_controller!),
              )
            else
              const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),

            // Controls Overlay
            if (widget.showControls) ...[
              // Top bar with close button
              Positioned(
                top: 12,
                left: 12,
                right: 12,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.videocam, color: Colors.white, size: 16),
                          SizedBox(width: 8),
                          Text(
                            'Video Selected',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: widget.onDiscard,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Bottom controls
              if (_initialized && _controller != null)
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 60,
                  child: Column(
                    children: [
                      VideoProgressIndicator(
                        _controller!,
                        allowScrubbing: true,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        colors: VideoProgressColors(
                          playedColor: const Color(0xFF800080),
                          bufferedColor: Colors.white30,
                          backgroundColor: Colors.white24,
                        ),
                      ),
                    ],
                  ),
                ),

              // Action buttons
              Positioned(
                left: 0,
                right: 0,
                bottom: 10,
                child: SafeArea(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton(
                        onPressed: widget.onDiscard,
                        child: const Text('Discard', style: TextStyle(color: Colors.white)),
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _muted = !_muted;
                            _controller?.setVolume(_muted ? 0 : 1);
                          });
                        },
                        icon: Icon(
                          _muted ? Icons.volume_off : Icons.volume_up,
                          color: Colors.white,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => widget.onConfirm?.call(widget.videoFile),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
