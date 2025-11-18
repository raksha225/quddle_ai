import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/helpers/storage.dart';

class AuthService {
  // static const String baseUrl = 'https://quddle-ai-app.onrender.com/api'; // Production
  // static const String baseUrl = 'http://10.81.64.145:3000/api'; // Physical iPhone
  // static const String baseUrl = 'https://quddle-check.onrender.com/api'; // Physical iPhone
  static const String baseUrl = "http://13.232.97.100:3000/api"; // aws server
  // static const String baseUrl = 'http://10.81.85.41:3000/api'; // iOS Simulator
  // For Android emulator use: 'http://10.0.2.2:3000/api'
  // For physical device use your computer's IP: 'http://192.168.x.x:3000/api'
    
  // Register a new user
  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    
    String? phone,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'phone': phone,
        }),
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 201) {
        return {
          'success': true,
          'message': data['message'],
          'user': data['user'],
          'session': data['session'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Registration failed',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Login user
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        // Persist token & user
        final String? token = data['session']?['access_token'];
        final String? refresh = data['session']?['refresh_token'];
        final String userId = data['user']?['id']?.toString() ?? '';
        final String? email = data['user']?['email']?.toString();
        final String? name = data['user']?['name']?.toString();
        if (token != null && token.isNotEmpty && userId.isNotEmpty) {
          await SecureStorage.saveSession(
            accessToken: token,
            userId: userId,
            email: email,
            name: name,
            refreshToken: refresh,
          );
        }
        return {
          'success': true,
          'message': data['message'],
          'user': data['user'],
          'session': data['session'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Login failed',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Get user profile
  static Future<Map<String, dynamic>> getProfile(String userId, String? token) async {
    try {
      final headers = {
        'Content-Type': 'application/json',
      };
      
      // Add Authorization header if token is provided
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
      
      final response = await http.get(
        Uri.parse('$baseUrl/auth/profile/$userId'),
        headers: headers,
      );

      final data = jsonDecode(response.body);

      // print('data: $data');
      if (response.statusCode == 200) {
        return {
          'success': true,
          'user': data['user'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to get profile',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Logout user
  static Future<Map<String, dynamic>> logout() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/logout'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        // Clear persisted session
        await SecureStorage.clear();
        return {
          'success': true,
          'message': data['message'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Logout failed',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Test protected route
  static Future<Map<String, dynamic>> testProtectedRoute(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/protected'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'],
          'user': data['user'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Access denied',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Refresh session using refresh token
  static Future<bool> refreshSessionIfNeeded() async {
    try {
      final refresh = await SecureStorage.readRefreshToken();
      print('Refresh token found: ${refresh != null && refresh.isNotEmpty}');
      
      if (refresh == null || refresh.isEmpty) {
        print('No refresh token available');
        return false;
      }
      
      print('Attempting token refresh...');
      final response = await http.post(
        Uri.parse('$baseUrl/auth/refresh'),
        headers: { 'Content-Type': 'application/json' },
        body: jsonEncode({ 'refreshToken': refresh }),
      );
      
      print('Refresh response status: ${response.statusCode}');
      print('Refresh response body: ${response.body}');
      
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        final String? token = data['session']?['access_token'];
        final String userId = data['user']?['id']?.toString() ?? '';
        final String? email = data['user']?['email']?.toString();
        final String? name = data['user']?['name']?.toString();
        final String? newRefresh = data['session']?['refresh_token'];
        
        print('New token received: ${token != null && token.isNotEmpty}');
        print('User ID: $userId');
        
        if (token != null && token.isNotEmpty && userId.isNotEmpty) {
          await SecureStorage.saveSession(
            accessToken: token,
            userId: userId,
            email: email,
            name: name,
            refreshToken: newRefresh ?? refresh,
          );
          print('Token refresh successful');
          return true;
        }
      }
      
      print('Token refresh failed - status: ${response.statusCode}, success: ${data['success']}');
      return false;
    } catch (e) {
      print('Token refresh error: $e');
      return false;
    }
  }
}
