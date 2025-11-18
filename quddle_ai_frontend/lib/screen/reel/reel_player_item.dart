import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:quddle_ai_frontend/services/hls_cache_manager.dart';
import 'reel_overlay.dart';

class ReelPlayerItem extends StatefulWidget {
  final dynamic video;
  final String videoUrl;
  final bool isPlaying;
  final Function(String reelId, bool isLiked, int newCount)? onLikeChanged;

  const ReelPlayerItem({
    super.key,
    required this.video,
    required this.videoUrl,
    required this.isPlaying,
    this.onLikeChanged,
  });

  @override
  State<ReelPlayerItem> createState() => _ReelPlayerItemState();
}

class _ReelPlayerItemState extends State<ReelPlayerItem> {
  final HlsCacheManager _cacheManager = HlsCacheManager();
  VideoPlayerController? _controller;
  Future<void>? _initializeVideoPlayerFuture;
  bool _initialized = false;
  bool _isPaused = false;
  bool _isMuted = false;

  @override
  void initState() {
    super.initState();
    print('🎯 ReelPlayerItem initialized with data: ${widget.video}');
    _isMuted = false; // Each video starts unmuted
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    final cacheStatus = await _cacheManager.getCacheStatus(widget.videoUrl);

    try {
      if (cacheStatus == CacheStatus.cached) {
        // --- PLAY FROM CACHE ---
        debugPrint("🎬 Attempting to play from CACHE: ${widget.videoUrl}");
        
        try {
          final localPath = await _cacheManager.getLocalHlsUrl(widget.videoUrl);
          final localFile = File(localPath);
          
          // Verify file exists and is readable
          if (await localFile.exists()) {
            debugPrint("✅ CACHE file exists: $localPath");
            _controller = VideoPlayerController.file(localFile);
          } else {
            debugPrint("⚠️ CACHE file not found, falling back to NETWORK");
            _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
            _cacheManager.cacheVideoInBackground(widget.videoUrl);
          }
        } catch (cacheError) {
          debugPrint("❌ Error loading from CACHE: $cacheError, falling back to NETWORK");
          _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
          _cacheManager.cacheVideoInBackground(widget.videoUrl);
        }
      } else {
        // --- PLAY FROM NETWORK & START CACHING ---
        debugPrint("🌐 Playing from NETWORK: ${widget.videoUrl}");
        _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
        if (cacheStatus == CacheStatus.notCached) {
          _cacheManager.cacheVideoInBackground(widget.videoUrl);
        }
      }

      _initializeVideoPlayerFuture = _controller?.initialize().then((_) {
        if (mounted) {
          setState(() {
            _initialized = true;
            if (widget.isPlaying) {
              _controller?.play();
              _controller?.setLooping(true);
            }
            // Set initial volume based on mute state
            _controller?.setVolume(_isMuted ? 0.0 : 1.0);
          });
        }
      }).catchError((error) {
        debugPrint("❌ Video initialization failed: $error");
        // Fallback to network if cache initialization fails
        if (cacheStatus == CacheStatus.cached && _controller != null) {
          debugPrint("🔄 Retrying from NETWORK due to cache failure");
          _controller?.dispose();
          _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
          _controller?.initialize().then((_) {
            if (mounted) {
              setState(() {
                _initialized = true;
                if (widget.isPlaying) {
                  _controller?.play();
                  _controller?.setLooping(true);
                }
                _controller?.setVolume(_isMuted ? 0.0 : 1.0);
              });
            }
          });
        }
      });
    } catch (e) {
      debugPrint("❌ Error initializing video player for ${widget.videoUrl}: $e");
    }
  }

  @override
  void didUpdateWidget(ReelPlayerItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Handle play/pause changes
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _controller?.play();
        setState(() {
          _isPaused = false;
        });
      } else {
        _controller?.pause();
        setState(() {
          _isPaused = true;
        });
      }
    }
  }

  void _handleMuteChanged(bool isMuted) {
    setState(() {
      _isMuted = isMuted;
    });
    
    // Update video volume
    _controller?.setVolume(isMuted ? 0.0 : 1.0);
    
    print('Volume changed to: ${isMuted ? 0.0 : 1.0}');
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // ✅ Show thumbnail until video initialized
        if (!_initialized && widget.video['thumbnail_url'] != null)
          Image.network(
            widget.video['thumbnail_url']!,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return const Center(child: CircularProgressIndicator(color: Colors.white));
            },
            errorBuilder: (context, error, stackTrace) => const Center(
              child: Icon(Icons.image_not_supported, color: Colors.white54, size: 40),
            ),
          ),

        // ✅ Show video once initialized
        FutureBuilder(
          future: _initializeVideoPlayerFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done &&
                _controller != null &&
                _controller!.value.isInitialized) {
              return GestureDetector(
                onTap: () => setState(() {
                  if (_controller!.value.isPlaying) {
                    _controller!.pause();
                    _isPaused = true;
                  } else {
                    _controller!.play();
                    _isPaused = false;
                  }
                }),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: _controller!.value.size.width,
                        height: _controller!.value.size.height,
                        child: VideoPlayer(_controller!),
                      ),
                    ),
                    ReelOverlay(
                      reelData: widget.video,
                      onLikeChanged: widget.onLikeChanged,
                      onMuteChanged: _handleMuteChanged,
                    ),
                    // Pause button overlay
                    if (_isPaused)
                      Center(
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.play_arrow,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }

            // ✅ While initializing (if no thumbnail)
            return widget.video['thumbnail_url'] == null
                ? const Center(child: CircularProgressIndicator(color: Colors.white))
                : const SizedBox.shrink();
          },
        ),
      ],
    );
  }
}
