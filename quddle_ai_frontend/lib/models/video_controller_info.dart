import 'package:video_player/video_player.dart';

class VideoControllerInfo {
  final String videoId;
  final String videoUrl;
  final VideoPlayerController? controller;
  final VideoControllerState state;
  final DateTime createdAt;
  final DateTime lastUsed;
  final int accessCount;
  final bool isPreloaded;
  final String? cachedPath;

  VideoControllerInfo({
    required this.videoId,
    required this.videoUrl,
    this.controller,
    this.state = VideoControllerState.unloaded,
    DateTime? createdAt,
    DateTime? lastUsed,
    this.accessCount = 0,
    this.isPreloaded = false,
    this.cachedPath,
  }) : createdAt = createdAt ?? DateTime.now(),
       lastUsed = lastUsed ?? DateTime.now();

  VideoControllerInfo copyWith({
    String? videoId,
    String? videoUrl,
    VideoPlayerController? controller,
    VideoControllerState? state,
    DateTime? createdAt,
    DateTime? lastUsed,
    int? accessCount,
    bool? isPreloaded,
    String? cachedPath,
  }) {
    return VideoControllerInfo(
      videoId: videoId ?? this.videoId,
      videoUrl: videoUrl ?? this.videoUrl,
      controller: controller ?? this.controller,
      state: state ?? this.state,
      createdAt: createdAt ?? this.createdAt,
      lastUsed: lastUsed ?? this.lastUsed,
      accessCount: accessCount ?? this.accessCount,
      isPreloaded: isPreloaded ?? this.isPreloaded,
      cachedPath: cachedPath ?? this.cachedPath,
    );
  }

  bool get isInitialized => controller?.value.isInitialized ?? false;
  bool get isPlaying => controller?.value.isPlaying ?? false;
  bool get isPaused => !isPlaying && isInitialized;
  bool get isDisposed => state == VideoControllerState.disposed;
  bool get isReady => state == VideoControllerState.ready && isInitialized;

  Duration get position => controller?.value.position ?? Duration.zero;
  Duration get duration => controller?.value.duration ?? Duration.zero;
  double get aspectRatio => controller?.value.aspectRatio ?? 1.0;
  bool get isBuffering => controller?.value.isBuffering ?? false;

  int get ageInMinutes => DateTime.now().difference(createdAt).inMinutes;
  int get timeSinceLastUsed => DateTime.now().difference(lastUsed).inMinutes;

  @override
  String toString() {
    return 'VideoControllerInfo(videoId: $videoId, state: $state, accessCount: $accessCount, age: ${ageInMinutes}m)';
  }
}

enum VideoControllerState {
  unloaded,
  loading,
  ready,
  playing,
  paused,
  disposed,
}
