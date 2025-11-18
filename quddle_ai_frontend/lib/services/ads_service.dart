import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../utils/helpers/storage.dart';
import 'auth_service.dart';

class AdsService {
  static String get _baseUrl => AuthService.baseUrl;

  // GET /api/ads - List all active ads (public)
  static Future<Map<String, dynamic>> getActiveAds() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/ads'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'ads': data['ads'] ?? [],
          'count': data['count'] ?? 0,
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to load active ads',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // GET /api/ads/my - List advertiser's own ads (authenticated)
  static Future<Map<String, dynamic>> getMyAds() async {
    try {
      final token = await SecureStorage.readToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Authentication required',
        };
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/ads/my'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'ads': data['ads'] ?? [],
          'count': data['count'] ?? 0,
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to load your ads',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // GET /api/ads/:id - Get specific ad details (public)
  static Future<Map<String, dynamic>> getAdById(String adId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/ads/$adId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'ad': data['ad'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to load ad',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // POST /api/ads - Create new ad (authenticated, with image upload)
  static Future<Map<String, dynamic>> createAd({
    required String title,
    required String linkUrl,
    required double paymentAmount,
    required int targetImpressions,
    required File imageFile,
  }) async {
    try {
      final token = await SecureStorage.readToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Authentication required',
        };
      }

      // Get file size and content type
      final fileSize = await imageFile.length();
      final extension = imageFile.path.split('.').last.toLowerCase();
      final contentType = extension == 'jpg' || extension == 'jpeg'
          ? 'image/jpeg'
          : extension == 'png'
              ? 'image/png'
              : extension == 'webp'
                  ? 'image/webp'
                  : 'image/jpeg';

      // Step 1: Request presigned URL
      final presignResponse = await http.post(
        Uri.parse('$_baseUrl/ads'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'title': title,
          'link_url': linkUrl,
          'payment_amount': paymentAmount,
          'target_impressions': targetImpressions,
          'contentType': contentType,
          'sizeBytes': fileSize,
        }),
      );

      final presignData = jsonDecode(presignResponse.body);

      if (presignResponse.statusCode != 201 || presignData['success'] != true) {
        return {
          'success': false,
          'message': presignData['message'] ?? 'Failed to create ad',
        };
      }

      // Step 2: Upload image to S3
      final uploadUrl = presignData['uploadUrl'];
      final imageBytes = await imageFile.readAsBytes();
      final uploadResponse = await http.put(
        Uri.parse(uploadUrl),
        headers: {'Content-Type': contentType},
        body: imageBytes,
      );

      if (uploadResponse.statusCode != 200) {
        return {
          'success': false,
          'message': 'Failed to upload image to S3',
        };
      }

      // Step 3: Return success with ad data
      return {
        'success': true,
        'ad': presignData['ad'],
        'message': 'Ad created successfully',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // PUT /api/ads/:id - Update ad (authenticated, owner only)
  static Future<Map<String, dynamic>> updateAd({
    required String adId,
    String? title,
    String? linkUrl,
    String? status,
    String? expiresAt,
  }) async {
    try {
      final token = await SecureStorage.readToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Authentication required',
        };
      }

      final body = <String, dynamic>{};
      if (title != null) body['title'] = title;
      if (linkUrl != null) body['link_url'] = linkUrl;
      if (status != null) body['status'] = status;
      if (expiresAt != null) body['expires_at'] = expiresAt;

      final response = await http.put(
        Uri.parse('$_baseUrl/ads/$adId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'ad': data['ad'],
          'message': data['message'] ?? 'Ad updated successfully',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to update ad',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // DELETE /api/ads/:id - Delete ad (authenticated, owner only)
  static Future<Map<String, dynamic>> deleteAd(String adId) async {
    try {
      final token = await SecureStorage.readToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Authentication required',
        };
      }

      final response = await http.delete(
        Uri.parse('$_baseUrl/ads/$adId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'message': data['message'] ?? 'Ad deleted successfully',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to delete ad',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // POST /api/ads/:id/impression - Record ad impression (public, rate-limited)
  static Future<Map<String, dynamic>> recordImpression({
    required String adId,
    required String userId,
    required String reelId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/ads/$adId/impression'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'user_id': userId,
          'reel_id': reelId,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['success'] == true) {
        return {
          'success': true,
          'impression': data['impression'],
          'message': data['message'] ?? 'Impression recorded',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to record impression',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // POST /api/ads/:id/click - Record ad click (public, rate-limited)
  static Future<Map<String, dynamic>> recordClick({
    required String adId,
    String? userId,
    String? reelId,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (userId != null) body['user_id'] = userId;
      if (reelId != null) body['reel_id'] = reelId;

      final response = await http.post(
        Uri.parse('$_baseUrl/ads/$adId/click'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['success'] == true) {
        return {
          'success': true,
          'click': data['click'],
          'message': data['message'] ?? 'Click recorded',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to record click',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // POST /api/ads/:id/payment - Initiate Stripe payment (authenticated, owner only)
  static Future<Map<String, dynamic>> initiatePayment(String adId) async {
    try {
      final token = await SecureStorage.readToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Authentication required',
        };
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/ads/$adId/payment'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'paymentIntent': data['paymentIntent'],
          'ad': data['ad'],
          'message': data['message'] ?? 'Payment intent created',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to initiate payment',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }
}

