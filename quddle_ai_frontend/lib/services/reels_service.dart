import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import '../utils/helpers/storage.dart';
import 'auth_service.dart';

class ReelsService {
  static String get _baseUrl => AuthService.baseUrl; // reuse API base

  static Future<Map<String, dynamic>> requestPresign({
    required String contentType,
    required int sizeBytes,
  }) async {
    print('🔄 Requesting presigned URL...');
    print('   ContentType: $contentType');
    print('   Size: ${(sizeBytes / 1024 / 1024).toStringAsFixed(2)} MB');
    
    final token = await SecureStorage.readToken();
    final response = await http.post(
      Uri.parse('$_baseUrl/reels/presign'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'contentType': contentType,
        'sizeBytes': sizeBytes,
      }),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      print('✅ Presigned URL received :');
      print('   ReelId: ${data['reelId']}');
      print('   Key: ${data['key']}');
      return data;
    }
    print('❌ Failed to get presigned URL: ${data['message']}');
    throw Exception(data['message'] ?? 'Failed to get presigned URL');
  }

  static Future<void> uploadToS3({
    required String uploadUrl,
    required File file,
    required String contentType,
    required int contentLength,
    void Function(int sent, int total)? onProgress,
  }) async {
    print('🚀 Starting S3 upload...');
    print('   File: ${file.path}');
    print('   ContentType: $contentType');
    print('   ContentLength: $contentLength');
    
    final dio = Dio();
    await dio.put(
      uploadUrl,
      data: file.openRead(),
      options: Options(
        headers: {
          'Content-Type': contentType,
          'Content-Length': contentLength.toString(),
        },
        sendTimeout: const Duration(minutes: 5),
        receiveTimeout: const Duration(minutes: 5),
      ),
      onSendProgress: (sent, total) {
        final progress = (sent / total * 100).toStringAsFixed(1);
        print('📤 Upload progress: $progress% ($sent/$total bytes)');
        onProgress?.call(sent, total);
      },
    );
    
    print('✅ S3 upload completed successfully!');
  }

  static Future<Map<String, dynamic>> finalize({
    required String reelId,
    required String key,
    String? s3Url,
    int? durationSec,
    int? sizeBytes,
  }) async {
    print('💾 Finalizing reel...');
    print('   ReelId: $reelId');
    print('   Key: $key');
    print('   Size: ${sizeBytes != null ? '${(sizeBytes / 1024 / 1024).toStringAsFixed(2)} MB' : 'Unknown'}');
    
    final token = await SecureStorage.readToken();
    final response = await http.post(
      Uri.parse('$_baseUrl/reels/finalize'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'reelId': reelId,
        'key': key,
        if (s3Url != null) 's3Url': s3Url,
        if (durationSec != null) 'durationSec': durationSec,
        if (sizeBytes != null) 'sizeBytes': sizeBytes,
      }),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      print('✅ Reel finalized and saved to database!');
      print('   S3 URL: ${data['reel']['s3_url']}');
      return data['reel'];
    }
    print('❌ Failed to finalize reel: ${data['message']}');
    throw Exception(data['message'] ?? 'Failed to finalize reel');
  }

  // Fetch current user's reels
  static Future<List<dynamic>> listMyReels() async {
    final token = await SecureStorage.readToken();
    final response = await http.get(
      Uri.parse('$_baseUrl/reels'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      final reels = (data['reels'] as List?) ?? [];
      print('📄 Loaded ${reels.length} reels');
      return reels;
    }
    print('❌ Failed to load reels: ${data['message']}');
    throw Exception(data['message'] ?? 'Failed to load reels');
  }

  // List all reels from all users (public feed)
  static Future<List<dynamic>> listAllReels() async {
    final token = await SecureStorage.readToken();
    final response = await http.get(
      Uri.parse('$_baseUrl/reels/all'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      final reels = (data['reels'] as List?) ?? [];
      print('📄 Loaded ${reels.length} reels from all users');
      return reels;
    }
    print('❌ Failed to load all reels: ${data['message']}');
    throw Exception(data['message'] ?? 'Failed to load all reels');
  }

  static Future<String?> getPlaybackUrl(String reelId) async {
    try {
      print('🔗 Getting playback URL for reel: $reelId');
      final token = await SecureStorage.readToken();
      if (token == null) {
        print('❌ No access token available');
        throw Exception('No access token');
      }

      print('🔗 Making request to: $_baseUrl/reels/$reelId/playback-url');
      final response = await http.get(
        Uri.parse('$_baseUrl/reels/$reelId/playback-url'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('🔗 Response status: ${response.statusCode}');
      print('🔗 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['playbackUrl'] != null) {
          print('🎬 Got presigned playback URL for reel: $reelId');
          return data['playbackUrl'] as String;
        } else {
          print('❌ API returned success=false: ${data['message']}');
        }
      } else {
        print('❌ HTTP error: ${response.statusCode}');
      }
      
      return null;
    } catch (e) {
      print('❌ Error getting playback URL for $reelId: $e');
      return null;
    }
  }

  static Future<bool> deleteReel(String reelId) async {
    final token = await SecureStorage.readToken();
    if (token == null) return false;
    final response = await http.delete(
      Uri.parse('$_baseUrl/reels/$reelId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) return true;
    try {
      final data = json.decode(response.body);
      print('Delete reel failed: ${data['message']}');
    } catch (_) {}
    return false;
  }

  // Like a reel
  static Future<Map<String, dynamic>> likeReel(String reelId) async {
    print('❤️ Liking reel: $reelId');
    
    final token = await SecureStorage.readToken();
    if (token == null) {
      print('❌ No access token available');
      throw Exception('No access token');
    }

    final response = await http.post(
      Uri.parse('$_baseUrl/reels/$reelId/like'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    final data = json.decode(response.body);
    
    if (response.statusCode == 200 && data['success'] == true) {
      print('✅ Reel liked successfully!');
      print('   New like count: ${data['reel']['likes_count']}');
      return data;
    } else {
      print('❌ Failed to like reel: ${data['message']}');
      throw Exception(data['message'] ?? 'Failed to like reel');
    }
  }
}


