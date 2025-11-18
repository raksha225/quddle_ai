
class VideoAnalyticsService {
  static final VideoAnalyticsService _instance = VideoAnalyticsService._internal();
  factory VideoAnalyticsService() => _instance;
  VideoAnalyticsService._internal();

  final Map<String, VideoMetrics> _videoMetrics = {};
  final Map<String, DateTime> _videoStartTimes = {};
  final Map<String, int> _videoViewCounts = {};

  void trackVideoStart(String videoId) {
    _videoStartTimes[videoId] = DateTime.now();
    _videoViewCounts[videoId] = (_videoViewCounts[videoId] ?? 0) + 1;
    print('Video started: $videoId');
  }

  void trackVideoEnd(String videoId) {
    final startTime = _videoStartTimes[videoId];
    if (startTime != null) {
      final duration = DateTime.now().difference(startTime);
      _updateVideoMetrics(videoId, duration.inSeconds, null);
      _videoStartTimes.remove(videoId);
      print('Video ended: $videoId, watched for ${duration.inSeconds}s');
    }
  }

  void trackVideoPause(String videoId) {
    _updateVideoMetrics(videoId, null, null, pauseCount: 1);
    print('Video paused: $videoId');
  }

  void trackVideoResume(String videoId) {
    _updateVideoMetrics(videoId, null, null, resumeCount: 1);
    print('Video resumed: $videoId');
  }

  void trackVideoSeek(String videoId, int fromPosition, int toPosition) {
    _updateVideoMetrics(videoId, null, null, seekCount: 1);
    print('Video seeked: $videoId from ${fromPosition}s to ${toPosition}s');
  }

  void trackVideoError(String videoId, String error) {
    print('Video error: $videoId - $error');
  }

  void trackVideoLoadTime(String videoId, int loadTimeMs) {
    _updateVideoMetrics(videoId, null, loadTimeMs);
    print('Video load time: $videoId - ${loadTimeMs}ms');
  }

  void trackVideoBufferUnderrun(String videoId) {
    _updateVideoMetrics(videoId, null, null, bufferUnderruns: 1);
    print('Video buffer underrun: $videoId');
  }

  void _updateVideoMetrics(
    String videoId, 
    int? watchTime, 
    int? loadTime, {
    int pauseCount = 0,
    int resumeCount = 0,
    int seekCount = 0,
    int bufferUnderruns = 0,
  }) {
    final metrics = _videoMetrics[videoId] ?? VideoMetrics();
    
    if (watchTime != null) {
      metrics.totalWatchTime += watchTime;
      metrics.viewCount = _videoViewCounts[videoId] ?? 0;
    }
    
    if (loadTime != null) {
      metrics.loadTimes.add(loadTime);
      metrics.averageLoadTime = metrics.loadTimes.reduce((a, b) => a + b) / metrics.loadTimes.length;
    }
    
    if (pauseCount > 0) {
      metrics.pauseCount += pauseCount;
    }
    
    if (resumeCount > 0) {
      metrics.resumeCount += resumeCount;
    }
    
    if (seekCount > 0) {
      metrics.seekCount += seekCount;
    }
    
    if (bufferUnderruns > 0) {
      metrics.bufferUnderruns += bufferUnderruns;
    }
    
    _videoMetrics[videoId] = metrics;
  }

  VideoMetrics? getVideoMetrics(String videoId) {
    return _videoMetrics[videoId];
  }

  Map<String, VideoMetrics> getAllMetrics() {
    return Map.from(_videoMetrics);
  }

  void clearMetrics() {
    _videoMetrics.clear();
    _videoStartTimes.clear();
    _videoViewCounts.clear();
  }

  void printAnalytics() {
    print('Video Analytics:');
    for (final entry in _videoMetrics.entries) {
      final metrics = entry.value;
      print('Video ${entry.key}:');
      print('  Views: ${metrics.viewCount}');
      print('  Total watch time: ${metrics.totalWatchTime}s');
      print('  Average load time: ${metrics.averageLoadTime.toStringAsFixed(1)}ms');
      print('  Pauses: ${metrics.pauseCount}');
      print('  Resumes: ${metrics.resumeCount}');
      print('  Seeks: ${metrics.seekCount}');
      print('  Buffer underruns: ${metrics.bufferUnderruns}');
    }
  }
}

class VideoMetrics {
  int totalWatchTime = 0;
  int viewCount = 0;
  List<int> loadTimes = [];
  double averageLoadTime = 0.0;
  int bufferUnderruns = 0;
  int seekCount = 0;
  int pauseCount = 0;
  int resumeCount = 0;
}
