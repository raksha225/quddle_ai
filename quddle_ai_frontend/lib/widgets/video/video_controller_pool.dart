import 'package:video_player/video_player.dart';

enum VideoControllerState {
  unloaded,
  loading,
  ready,
  playing,
  paused,
  disposed,
}

class VideoControllerInfo {
  final String videoId;
  final String videoUrl;
  final VideoPlayerController? controller;
  final VideoControllerState state;
  final DateTime lastUsed;

  VideoControllerInfo({
    required this.videoId,
    required this.videoUrl,
    this.controller,
    this.state = VideoControllerState.unloaded,
    DateTime? lastUsed,
  }) : lastUsed = lastUsed ?? DateTime.now();

  VideoControllerInfo copyWith({
    String? videoId,
    String? videoUrl,
    VideoPlayerController? controller,
    VideoControllerState? state,
    DateTime? lastUsed,
  }) {
    return VideoControllerInfo(
      videoId: videoId ?? this.videoId,
      videoUrl: videoUrl ?? this.videoUrl,
      controller: controller ?? this.controller,
      state: state ?? this.state,
      lastUsed: lastUsed ?? this.lastUsed,
    );
  }
}

class VideoControllerPool {
  static const int maxControllers = 8; // Increased from 3 to 8 for better scrolling
  final Map<String, VideoControllerInfo> _controllers = {};
  final List<String> _accessOrder = [];
  final Set<String> _blacklistedVideos = {};

  VideoControllerInfo? getController(String videoId) {
    return _controllers[videoId];
  }

  bool isControllerReady(String videoId) {
    final controllerInfo = _controllers[videoId];
    return controllerInfo?.state == VideoControllerState.ready;
  }

  Future<VideoControllerInfo?> createController(String videoId, String videoUrl) async {
    // Skip blacklisted videos
    if (_blacklistedVideos.contains(videoId)) {
      print('🚫 Skipping blacklisted video: $videoId');
      return null;
    }
    
    // If controller already exists, update access time
    if (_controllers.containsKey(videoId)) {
      _updateAccessTime(videoId);
      return _controllers[videoId];
    }

    // If we have too many controllers, dispose the oldest one
    if (_controllers.length >= maxControllers) {
      await _disposeOldestController();
    }

    try {
      final controller = VideoPlayerController.networkUrl(
        Uri.parse(videoUrl),
        httpHeaders: {
          'User-Agent': 'Flutter Video Player',
          'Accept': 'video/mp4,video/*,*/*',
          'Connection': 'keep-alive',
        },
      );
      
      // Set initial state to loading
      final controllerInfo = VideoControllerInfo(
        videoId: videoId,
        videoUrl: videoUrl,
        controller: controller,
        state: VideoControllerState.loading,
      );
      _controllers[videoId] = controllerInfo;
      _updateAccessTime(videoId);
      
      // Initialize in background with retry logic
      _initializeWithRetry(controller, videoId, controllerInfo, 0);
      
      print('Created controller for video: $videoId (initializing...)');
      return controllerInfo;
    } catch (e) {
      print('Error creating controller for $videoId: $e');
      return null;
    }
  }

  Future<void> preloadVideo(String videoId, String videoUrl) async {
    if (_controllers.containsKey(videoId)) {
      return; // Already loaded
    }

    // Skip blacklisted videos
    if (_blacklistedVideos.contains(videoId)) {
      print('🚫 Skipping blacklisted video: $videoId');
      return;
    }

    await createController(videoId, videoUrl);
  }

  Future<void> disposeController(String videoId) async {
    final controllerInfo = _controllers[videoId];
    if (controllerInfo?.controller != null) {
      await controllerInfo!.controller!.dispose();
    }
    _controllers.remove(videoId);
    _accessOrder.remove(videoId);
    print('Disposed controller for video: $videoId');
  }

  Future<void> disposeAll() async {
    for (final controllerInfo in _controllers.values) {
      if (controllerInfo.controller != null) {
        await controllerInfo.controller!.dispose();
      }
    }
    _controllers.clear();
    _accessOrder.clear();
    print('Disposed all controllers');
  }

  void _updateAccessTime(String videoId) {
    _accessOrder.remove(videoId);
    _accessOrder.add(videoId);
  }

  Future<void> _disposeOldestController() async {
    if (_accessOrder.isNotEmpty) {
      final oldestVideoId = _accessOrder.first;
      print('🗑️ Disposing oldest controller: $oldestVideoId');
      // Add a small delay to prevent immediate disposal during rapid scrolling
      await Future.delayed(const Duration(milliseconds: 500));
      await disposeController(oldestVideoId);
    }
  }

  List<String> getLoadedVideoIds() {
    return _controllers.keys.toList();
  }

  int getControllerCount() {
    return _controllers.length;
  }

  void printPoolStatus() {
    print('Video Controller Pool Status:');
    print('Total controllers: ${_controllers.length}');
    print('Blacklisted videos: ${_blacklistedVideos.length}');
    for (final entry in _controllers.entries) {
      print('  ${entry.key}: ${entry.value.state}');
    }
    if (_blacklistedVideos.isNotEmpty) {
      print('Blacklisted: ${_blacklistedVideos.join(', ')}');
    }
  }

  Future<void> _initializeWithRetry(
    VideoPlayerController controller, 
    String videoId, 
    VideoControllerInfo controllerInfo, 
    int retryCount
  ) async {
    try {
      print('⏱️ Starting video initialization for: $videoId');
      final stopwatch = Stopwatch()..start();
      
      // Add timeout to prevent hanging
      await controller.initialize().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Video initialization timeout after 30 seconds');
        },
      );
      
      stopwatch.stop();
      print('⏱️ Video initialization completed in ${stopwatch.elapsedMilliseconds}ms for: $videoId');
      
      if (_controllers.containsKey(videoId)) {
        _controllers[videoId] = controllerInfo.copyWith(state: VideoControllerState.ready);
        print('✅ Controller ready for video: $videoId');
      }
    } catch (e) {
      print('❌ Error initializing controller for $videoId (attempt ${retryCount + 1}): $e');
      
      // Check if it's a server configuration error
      if (e.toString().contains('server is not correctly configured') || 
          e.toString().contains('OSStatus error -12939')) {
        print('🚫 Blacklisting problematic video (server config error): $videoId');
        _blacklistedVideos.add(videoId);
        if (_controllers.containsKey(videoId)) {
          _controllers[videoId] = controllerInfo.copyWith(state: VideoControllerState.disposed);
        }
        return;
      }
      
      if (retryCount < 2 && _controllers.containsKey(videoId)) {
        // Retry after a delay
        await Future.delayed(Duration(seconds: (retryCount + 1) * 2));
        if (_controllers.containsKey(videoId)) {
          await _initializeWithRetry(controller, videoId, controllerInfo, retryCount + 1);
        }
      } else {
        // Give up after 3 attempts
        if (_controllers.containsKey(videoId)) {
          _controllers[videoId] = controllerInfo.copyWith(state: VideoControllerState.disposed);
          print('💀 Failed to initialize video after ${retryCount + 1} attempts: $videoId');
        }
      }
    }
  }
}
