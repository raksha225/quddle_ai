import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../video/video_player_widget.dart';
import '../video/video_timeline_bar.dart';
import 'reel_action_buttons.dart';
import 'reel_user_info.dart';
import 'reel_description.dart';

class ReelItemWidget extends StatefulWidget {
  final Map<String, dynamic> reel;
  final Set<String> likedReels;
  final Function(String) onLike;
  final VoidCallback? onShare;
  final VoidCallback? onMore;
  final VoidCallback? onUserTap;
  final VideoPlayerController? videoController;

  const ReelItemWidget({
    super.key,
    required this.reel,
    required this.likedReels,
    required this.onLike,
    this.onShare,
    this.onMore,
    this.onUserTap,
    this.videoController,
  });

  @override
  State<ReelItemWidget> createState() => _ReelItemWidgetState();
}

class _ReelItemWidgetState extends State<ReelItemWidget> {
  VideoPlayerController? _currentController;
  bool _isPlaying = false;
  bool _showPlayPauseIcon = false;

  @override
  void initState() {
    super.initState();
    _currentController = widget.videoController;
    print('🎬 ReelItemWidget initState - Controller: ${_currentController != null}');
    if (_currentController != null) {
      print('🎬 Controller initialized: ${_currentController!.value.isInitialized}');
    }
    // Don't auto-play here - let ReelScreen handle it centrally
    if (_currentController != null) {
      _addVideoListener();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    print('🎬 ReelItemWidget didChangeDependencies - Controller: ${_currentController != null}');
    // Auto-play when this reel comes into view (fallback for ReelScreen)
    if (_currentController != null && _currentController!.value.isInitialized) {
      print('🎬 Auto-playing video in didChangeDependencies (fallback)');
      _currentController!.play();
      _currentController!.setLooping(true);
      _addVideoListener();
    } else if (_currentController != null) {
      _addVideoListener();
    }
  }

  @override
  void didUpdateWidget(ReelItemWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.videoController != oldWidget.videoController) {
      print('🎬 ReelItemWidget didUpdateWidget - New controller: ${widget.videoController != null}');
      print('🎬 Old controller: ${oldWidget.videoController != null}, New controller: ${widget.videoController != null}');
      _currentController = widget.videoController;
      // Don't auto-play here - let ReelScreen handle it centrally
      if (_currentController != null) {
        _addVideoListener();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final videoUrl = widget.reel['s3_url'] as String?;
    final reelId = widget.reel['id']?.toString() ?? '';
    final userId = widget.reel['user_id']?.toString() ?? '';
    final userName = widget.reel['user_name'] as String?;
    final description = widget.reel['description'] as String?;

    if (videoUrl == null || videoUrl.isEmpty) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.white, size: 48),
              SizedBox(height: 16),
              Text(
                'Video not available',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    // Use presigned URL if available, otherwise fall back to original S3 URL
    final effectiveVideoUrl = widget.reel['presigned_url'] as String? ?? videoUrl;
    print('🎬 Using video URL: ${effectiveVideoUrl.contains('X-Amz-') ? 'PRESIGNED' : 'ORIGINAL'}');

    return GestureDetector(
      onTap: _togglePlayPause,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.black,
        child: Stack(
          children: [
            // Video Player
            Center(
              child: AspectRatio(
                aspectRatio: 9 / 16,
                child: _buildVideoPlayer(effectiveVideoUrl),
              ),
            ),
            
            // Play/Pause Icon Overlay (transparent)
            if (_showPlayPauseIcon)
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3), // More transparent
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white.withOpacity(0.8), // Semi-transparent white
                    size: 40,
                  ),
                ),
              ),
              
            // Right side action buttons
            Positioned(
              right: 16,
              bottom: 100,
            child: ReelActionButtons(
              reelId: reelId,
              likedReels: widget.likedReels,
              onLike: widget.onLike,
              onShare: widget.onShare,
              onMore: widget.onMore,
            ),
          ),
          
          // Timeline bar above bottom navigation
          Positioned(
            left: 0,
            right: 0,
            bottom: 80, // Above the bottom navigation bar (height: 80)
            child: Container(
              height: 4,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: VideoTimelineBar(
                controller: _currentController,
                height: 4,
                progressColor: const Color(0xFF800080),
                backgroundColor: Colors.white.withOpacity(0.3),
                allowScrubbing: true,
              ),
            ),
          ),
          
          // Bottom info overlay
          Positioned(
            left: 16,
            bottom: 100, // Above the timeline bar
            right: 80,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User info
                ReelUserInfo(
                  userId: userId,
                  userName: userName,
                  onUserTap: widget.onUserTap,
                ),
                
                const SizedBox(height: 8),
                
                // Reel description
                ReelDescription(
                  description: description,
                  hashtags: _extractHashtags(description),
                ),
              ],
            ),
          ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoPlayer(String videoUrl) {
    print('🎬 Building video player - Controller: ${_currentController != null}, Initialized: ${_currentController?.value.isInitialized ?? false}');
    
    if (_currentController != null && _currentController!.value.isInitialized) {
      print('🎬 Using preloaded controller');
      return VideoPlayer(_currentController!);
    } else {
      print('🎬 Using VideoPlayerWidget fallback');
      return _buildVideoLoadingState(videoUrl);
    }
  }

  Widget _buildVideoLoadingState(String videoUrl) {
    print('🎬 Building video loading state for: $videoUrl');
    return Container(
      color: Colors.black,
      child: VideoPlayerWidget(
        url: videoUrl,
        autoPlay: true, // Ensure auto-play is enabled
        onControllerReady: (controller) {
          print('🎬 VideoPlayerWidget controller ready');
          setState(() {
            _currentController = controller;
          });
          // Auto-play when controller becomes ready (fallback for ReelScreen)
          if (controller.value.isInitialized) {
            print('🎬 Auto-playing video from VideoPlayerWidget (fallback)');
            controller.play();
            controller.setLooping(true);
            _addVideoListener();
          }
        },
      ),
    );
  }

  List<String> _extractHashtags(String? text) {
    if (text == null || text.isEmpty) return [];
    
    final hashtagRegex = RegExp(r'#(\w+)');
    final matches = hashtagRegex.allMatches(text);
    return matches.map((match) => match.group(1)!).toList();
  }

  void _togglePlayPause() {
    if (_currentController != null && _currentController!.value.isInitialized) {
      setState(() {
        _showPlayPauseIcon = true;
      });
      
      if (_currentController!.value.isPlaying) {
        _currentController!.pause();
        print('⏸️ Video paused by user tap');
      } else {
        _currentController!.play();
        print('▶️ Video played by user tap');
      }
      
      // Hide the icon after 2 seconds
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _showPlayPauseIcon = false;
          });
        }
      });
    }
  }

  void _addVideoListener() {
    if (_currentController != null) {
      _currentController!.addListener(() {
        if (mounted) {
          final isPlaying = _currentController!.value.isPlaying;
          final position = _currentController!.value.position;
          final duration = _currentController!.value.duration;
          
          if (isPlaying != _isPlaying) {
            setState(() {
              _isPlaying = isPlaying;
            });
            print('🎬 Video playback state changed: ${isPlaying ? 'PLAYING' : 'PAUSED'} (${position.inSeconds}s/${duration.inSeconds}s)');
            
            // If video stopped playing unexpectedly, restart it
            if (!isPlaying && position < duration) {
              print('🎬 Video stopped unexpectedly at ${position.inSeconds}s/${duration.inSeconds}s, restarting...');
              Future.delayed(const Duration(milliseconds: 100), () {
                if (mounted && _currentController != null) {
                  _currentController!.play();
                }
              });
            }
          }
        }
      });
    }
  }
}
