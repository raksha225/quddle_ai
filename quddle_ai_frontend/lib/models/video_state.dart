enum VideoLoadingState {
  unloaded,
  loading,
  ready,
  playing,
  paused,
  error,
  disposed,
}

enum VideoPlaybackState {
  stopped,
  playing,
  paused,
  buffering,
  error,
}

class VideoState {
  final String videoId;
  final VideoLoadingState loadingState;
  final VideoPlaybackState playbackState;
  final double progress;
  final Duration position;
  final Duration duration;
  final bool isMuted;
  final double volume;
  final String? errorMessage;
  final DateTime lastUpdated;

  VideoState({
    required this.videoId,
    this.loadingState = VideoLoadingState.unloaded,
    this.playbackState = VideoPlaybackState.stopped,
    this.progress = 0.0,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.isMuted = false,
    this.volume = 1.0,
    this.errorMessage,
    DateTime? lastUpdated,
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  VideoState copyWith({
    String? videoId,
    VideoLoadingState? loadingState,
    VideoPlaybackState? playbackState,
    double? progress,
    Duration? position,
    Duration? duration,
    bool? isMuted,
    double? volume,
    String? errorMessage,
    DateTime? lastUpdated,
  }) {
    return VideoState(
      videoId: videoId ?? this.videoId,
      loadingState: loadingState ?? this.loadingState,
      playbackState: playbackState ?? this.playbackState,
      progress: progress ?? this.progress,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      isMuted: isMuted ?? this.isMuted,
      volume: volume ?? this.volume,
      errorMessage: errorMessage ?? this.errorMessage,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  bool get isLoaded => loadingState == VideoLoadingState.ready;
  bool get isPlaying => playbackState == VideoPlaybackState.playing;
  bool get isPaused => playbackState == VideoPlaybackState.paused;
  bool get isBuffering => playbackState == VideoPlaybackState.buffering;
  bool get hasError => loadingState == VideoLoadingState.error || playbackState == VideoPlaybackState.error;

  double get progressPercentage {
    if (duration.inMilliseconds == 0) return 0.0;
    return position.inMilliseconds / duration.inMilliseconds;
  }

  Duration get remainingTime {
    return duration - position;
  }

  @override
  String toString() {
    return 'VideoState(videoId: $videoId, loading: $loadingState, playback: $playbackState, progress: ${(progressPercentage * 100).toStringAsFixed(1)}%)';
  }
}
