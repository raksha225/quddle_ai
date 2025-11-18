import '../widgets/video/video_controller_pool.dart';
import 'video_cache_service.dart';
import 'reels_service.dart';

class VideoPreloadService {
  static final VideoPreloadService _instance = VideoPreloadService._internal();
  factory VideoPreloadService() => _instance;
  VideoPreloadService._internal();

  final VideoControllerPool _controllerPool = VideoControllerPool();
  
  VideoControllerPool get controllerPool => _controllerPool;
  final VideoCacheService _cacheService = VideoCacheService();
  
  List<Map<String, dynamic>> _reels = [];
  int _currentIndex = 0;
  bool _isPreloading = false;

  void setReels(List<Map<String, dynamic>> reels) {
    _reels = reels;
    _currentIndex = 0;
    // Clear cache to remove problematic cached videos
    _cacheService.clearCache();
  }

  void setCurrentIndex(int index) {
    _currentIndex = index;
    _preloadAdjacentVideos();
  }

  Future<void> _preloadAdjacentVideos() async {
    if (_isPreloading) return;
    _isPreloading = true;

    try {
      // Preload next video
      if (_currentIndex + 1 < _reels.length) {
        final nextReel = _reels[_currentIndex + 1];
        await preloadVideo(nextReel);
      }

      // Preload previous video
      if (_currentIndex - 1 >= 0) {
        final prevReel = _reels[_currentIndex - 1];
        await preloadVideo(prevReel);
      }

      // Dispose videos that are too far away
      await _disposeDistantVideos();
    } finally {
      _isPreloading = false;
    }
  }

  Future<void> preloadVideo(Map<String, dynamic> reel) async {
    final videoId = reel['id']?.toString() ?? '';
    final videoUrl = reel['s3_url'] as String?;

    print('🎬 VideoPreloadService.preloadVideo called for video: $videoId');
    print('🎬 VideoPreloadService: videoId=$videoId, videoUrl=$videoUrl');
    
    if (videoId.isEmpty || videoUrl == null) {
      print('❌ VideoPreloadService: Invalid video data - ID: $videoId, URL: $videoUrl');
      return;
    }
    
    print('🎬 VideoPreloadService: Video data is valid, proceeding...');

    // Check if already loaded
    if (_controllerPool.getController(videoId) != null) {
      print('🎬 VideoPreloadService: Controller already exists for video: $videoId');
      return;
    }

    // TEMPORARY: Skip cache to force presigned URL requests for all videos
    print('🎬 VideoPreloadService: Skipping cache to force presigned URL requests');
    
    print('🎬 VideoPreloadService: No cached video found, requesting presigned URL for: $videoId');
    // Get presigned URL for playback
    print('🔗 Requesting presigned URL for video: $videoId');
      final playbackUrl = await ReelsService.getPlaybackUrl(videoId);
      if (playbackUrl != null) {
        print('✅ Got presigned URL for video: $videoId');
        // Store presigned URL in reel data for ReelItemWidget to use
        reel['presigned_url'] = playbackUrl;
        // Load from presigned URL and cache
        await _controllerPool.preloadVideo(videoId, playbackUrl);
        // Cache for future use
        _cacheService.cacheVideo(videoId, playbackUrl);
      } else {
      print('❌ Failed to get presigned URL for video: $videoId');
      // Fallback to original URL (this might be the issue)
      print('🔄 Falling back to original S3 URL for video: $videoId');
      await _controllerPool.preloadVideo(videoId, videoUrl);
    }
  }

  Future<void> _disposeDistantVideos() async {
    final currentVideoId = _reels[_currentIndex]['id']?.toString() ?? '';
    final loadedVideoIds = _controllerPool.getLoadedVideoIds();

    for (final videoId in loadedVideoIds) {
      if (videoId == currentVideoId) continue;

      final videoIndex = _reels.indexWhere((reel) => reel['id']?.toString() == videoId);
      if (videoIndex == -1) continue;

      final distance = (videoIndex - _currentIndex).abs();
      // Only dispose videos that are more than 3 positions away (was 1)
      if (distance > 3) {
        print('🗑️ Disposing distant video: $videoId (distance: $distance)');
        await _controllerPool.disposeController(videoId);
      }
    }
  }

  VideoControllerInfo? getCurrentVideoController() {
    if (_currentIndex >= _reels.length) return null;
    final currentReel = _reels[_currentIndex];
    final videoId = currentReel['id']?.toString() ?? '';
    return _controllerPool.getController(videoId);
  }

  VideoControllerInfo? getNextVideoController() {
    if (_currentIndex + 1 >= _reels.length) return null;
    final nextReel = _reels[_currentIndex + 1];
    final videoId = nextReel['id']?.toString() ?? '';
    return _controllerPool.getController(videoId);
  }

  VideoControllerInfo? getPreviousVideoController() {
    if (_currentIndex - 1 < 0) return null;
    final prevReel = _reels[_currentIndex - 1];
    final videoId = prevReel['id']?.toString() ?? '';
    return _controllerPool.getController(videoId);
  }

  Future<void> preloadAllVideos() async {
    for (final reel in _reels) {
      await preloadVideo(reel);
    }
  }

  Future<void> clearAllControllers() async {
    await _controllerPool.disposeAll();
  }

  void printPreloadStatus() {
    print('Video Preload Service Status:');
    print('Current index: $_currentIndex');
    print('Total reels: ${_reels.length}');
    _controllerPool.printPoolStatus();
  }
}
