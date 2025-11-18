import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class VideoCacheService {
  static final VideoCacheService _instance = VideoCacheService._internal();
  factory VideoCacheService() => _instance;
  VideoCacheService._internal();

  static const int maxCacheSize = 100 * 1024 * 1024; // 100MB
  static const int maxCacheFiles = 10;

  Future<String> getCacheDirectory() async {
    final directory = await getApplicationDocumentsDirectory();
    final cacheDir = Directory(path.join(directory.path, 'video_cache'));
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    return cacheDir.path;
  }

  Future<String?> getCachedVideoPath(String videoId) async {
    final cacheDir = await getCacheDirectory();
    final videoFile = File(path.join(cacheDir, '$videoId.mp4'));
    return videoFile.existsSync() ? videoFile.path : null;
  }

  Future<bool> cacheVideo(String videoId, String videoUrl) async {
    try {
      final cacheDir = await getCacheDirectory();
      final videoFile = File(path.join(cacheDir, '$videoId.mp4'));
      
      // Download video
      final response = await HttpClient().getUrl(Uri.parse(videoUrl));
      final request = await response.close();
      final bytes = await request.toList();
      final videoData = bytes.expand((x) => x).toList();
      
      // Save to cache
      await videoFile.writeAsBytes(videoData);
      
      // Clean up old cache if needed
      await _cleanupCache();
      
      print('Cached video: $videoId');
      return true;
    } catch (e) {
      print('Error caching video $videoId: $e');
      return false;
    }
  }

  Future<void> _cleanupCache() async {
    try {
      final cacheDir = await getCacheDirectory();
      final files = Directory(cacheDir).listSync()
          .where((file) => file is File && file.path.endsWith('.mp4'))
          .cast<File>()
          .toList();

      // Sort by modification time (oldest first)
      files.sort((a, b) => a.lastModifiedSync().compareTo(b.lastModifiedSync()));

      // Remove oldest files if we exceed limits
      while (files.length > maxCacheFiles) {
        await files.first.delete();
        files.removeAt(0);
      }

      // Check total cache size
      int totalSize = 0;
      for (final file in files) {
        totalSize += await file.length();
      }

      // Remove oldest files if size exceeds limit
      while (totalSize > maxCacheSize && files.isNotEmpty) {
        final file = files.first;
        totalSize -= await file.length();
        await file.delete();
        files.removeAt(0);
      }
    } catch (e) {
      print('Error cleaning up cache: $e');
    }
  }

  Future<void> clearCache() async {
    try {
      final cacheDir = await getCacheDirectory();
      final directory = Directory(cacheDir);
      if (await directory.exists()) {
        await directory.delete(recursive: true);
      }
      print('Cache cleared');
    } catch (e) {
      print('Error clearing cache: $e');
    }
  }

  Future<int> getCacheSize() async {
    try {
      final cacheDir = await getCacheDirectory();
      final directory = Directory(cacheDir);
      if (!await directory.exists()) return 0;

      int totalSize = 0;
      await for (final entity in directory.list(recursive: true)) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }
      return totalSize;
    } catch (e) {
      print('Error getting cache size: $e');
      return 0;
    }
  }

  Future<List<String>> getCachedVideoIds() async {
    try {
      final cacheDir = await getCacheDirectory();
      final directory = Directory(cacheDir);
      if (!await directory.exists()) return [];

      final files = directory.listSync()
          .where((file) => file is File && file.path.endsWith('.mp4'))
          .cast<File>()
          .toList();

      return files.map((file) => path.basenameWithoutExtension(file.path)).toList();
    } catch (e) {
      print('Error getting cached video IDs: $e');
      return [];
    }
  }
}
