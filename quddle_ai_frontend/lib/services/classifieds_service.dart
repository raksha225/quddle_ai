import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../utils/helpers/storage.dart';
import 'auth_service.dart';

class ClassifiedsService {
  static String get _baseUrl => AuthService.baseUrl;

  // Post a classified ad
  static Future<Map<String, dynamic>> postClassified({
    required String title,
    required String description,
    double? price,
    String? category,
    String? location,
    int imageCount = 0,
  }) async {
    try {
      final token = await SecureStorage.readToken();
      if (token == null) {
        return {'success': false, 'message': 'Authentication required'};
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/classifieds'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'title': title,
          'description': description,
          'price': price,
          'category': category,
          'location': location,
          'imageCount': imageCount,
        }),
      );

      final data = jsonDecode(response.body);
      return data;
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // Get all classifieds
  static Future<Map<String, dynamic>> getClassifieds({
    String? category,
    String status = 'active',
  }) async {
    try {
      var url = '$_baseUrl/classifieds?status=$status';
      if (category != null) {
        url += '&category=$category';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );

      final data = jsonDecode(response.body);
      return data;
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // Get user's classifieds
  static Future<Map<String, dynamic>> getMyClassifieds() async {
    try {
      final token = await SecureStorage.readToken();
      if (token == null) {
        return {'success': false, 'message': 'Authentication required'};
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/classifieds/my'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);
      return data;
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // Upload images and update classified
  static Future<bool> uploadImages({
    required String classifiedId,
    required List<File> images,
    required List<Map<String, dynamic>> uploadUrls,
  }) async {
    try {
      final token = await SecureStorage.readToken();
      if (token == null) return false;

      // Upload images to S3
      for (int i = 0; i < images.length && i < uploadUrls.length; i++) {
        final imageBytes = await images[i].readAsBytes();
        await http.put(
          Uri.parse(uploadUrls[i]['uploadUrl']),
          headers: {'Content-Type': 'image/jpeg'},
          body: imageBytes,
        );
      }

      // Update classified with image keys
      final imageKeys = uploadUrls.map((u) => u['key'] as String).toList();
      final response = await http.put(
        Uri.parse('$_baseUrl/classifieds/$classifiedId/images'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'imageKeys': imageKeys}),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error uploading images: $e');
      return false;
    }
  }
}