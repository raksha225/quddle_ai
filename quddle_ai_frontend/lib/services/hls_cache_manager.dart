import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:crypto/crypto.dart';

enum CacheStatus { cached, caching, notCached }

class HlsCacheManager {
  static final HlsCacheManager _instance = HlsCacheManager._internal();

  factory HlsCacheManager() => _instance;

  HlsCacheManager._internal();

  static const _cacheDirName = 'hls_video_cache';
  
  final _cachingUrls = <String>{};

  Future<File> _getLocalM3u8File(String m3u8Url) async {
    final cacheDir = await _getCacheDirectory();
    final videoId = _generateVideoId(m3u8Url);
    final videoDir = Directory(p.join(cacheDir.path, videoId));
    return File(p.join(videoDir.path, 'main.m3u8'));
  }

  Future<CacheStatus> getCacheStatus(String m3u8Url) async {
    if (_cachingUrls.contains(m3u8Url)) return CacheStatus.caching;
    final localFile = await _getLocalM3u8File(m3u8Url);
    if (await localFile.exists()) return CacheStatus.cached;
    return CacheStatus.notCached;
  }

  Future<String> getLocalHlsUrl(String m3u8Url) async {
    final localFile = await _getLocalM3u8File(m3u8Url);
    if (await localFile.exists()) return localFile.path;
    throw Exception("Video is not cached locally.");
  }

  Future<void> cacheVideoInBackground(String m3u8Url) async {
    final status = await getCacheStatus(m3u8Url);
    if (status == CacheStatus.caching) debugPrint("Video is caching: $m3u8Url");
    if (status == CacheStatus.cached) debugPrint("Video already cached: $m3u8Url");
    if (status != CacheStatus.notCached) return;

    _cachingUrls.add(m3u8Url);
    debugPrint("Starting cache for: $m3u8Url");

    final videoId = _generateVideoId(m3u8Url);
    final cacheDir = await _getCacheDirectory();
    final videoDir = Directory(p.join(cacheDir.path, videoId));

    try {
      await videoDir.create(recursive: true);

      final uri = Uri.parse(m3u8Url);
      final response = await http.get(uri);
      if (response.statusCode != 200) throw Exception('Failed to download M3U8');

      final lines = response.body.split('\n');
      final segmentUrls = _extractSegmentUrls(uri, lines);

      for (final segUrl in segmentUrls.toSet()) {
        final fileName = p.basename(segUrl.path);
        final localFile = File(p.join(videoDir.path, fileName));
        if (await localFile.exists()) continue;

        final segResp = await http.get(segUrl);
        if (segResp.statusCode == 200) {
          await localFile.writeAsBytes(segResp.bodyBytes);
        } else {
          debugPrint('Warning: Failed to download segment: $segUrl');
        }
      }

      final localContent = _rewriteM3u8WithLocalPaths(lines);
      final localM3u8File = await _getLocalM3u8File(m3u8Url);
      await localM3u8File.writeAsString(localContent);

      print("Caching finished for: $m3u8Url");
    } catch (e, st) {
      debugPrint('Error caching video: $e\n$st');
      if (await videoDir.exists()) await videoDir.delete(recursive: true);
    } finally {
      _cachingUrls.remove(m3u8Url);
      print("REMOVED from the queue");
    }
  }

  List<Uri> _extractSegmentUrls(Uri baseUri, List<String> lines) {
    final urls = <Uri>[];
    for (final line in lines) {
      final t = line.trim();
      if (t.isEmpty || t.startsWith('#')) continue;
      urls.add(baseUri.resolve(t));
    }
    return urls;
  }

  String _rewriteM3u8WithLocalPaths(List<String> lines) {
    return lines.map((line) {
      final t = line.trim();
      if (t.isEmpty || t.startsWith('#')) return t;
      return p.basename(t);
    }).join('\n');
  }

  Future<Directory> _getCacheDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final cacheDir = Directory(p.join(appDir.path, _cacheDirName));
    if (!await cacheDir.exists()) await cacheDir.create(recursive: true);
    return cacheDir;
  }

  String _generateVideoId(String url) {
    final bytes = utf8.encode(url);
    final digest = sha1.convert(bytes);
    return digest.toString();
  }
}
