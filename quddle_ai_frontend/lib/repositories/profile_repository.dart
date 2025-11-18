import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../utils/helpers/storage.dart';

class ProfileRepository {
  Future<UserModel> getProfile() async {
    final userId = await SecureStorage.readUserId();
    final token = await SecureStorage.readToken();

    if (userId == null || token == null) {
      throw Exception('User not authenticated');
    }

    final result = await AuthService.getProfile(userId, token);

    if (result['success'] && result['user'] != null) {
      return UserModel.fromJson(result['user']);
    } else {
      // Try refreshing token
      final refreshSuccess = await AuthService.refreshSessionIfNeeded();
      if (refreshSuccess) {
        final newToken = await SecureStorage.readToken();
        final retryResult = await AuthService.getProfile(userId, newToken);
        
        if (retryResult['success'] && retryResult['user'] != null) {
          return UserModel.fromJson(retryResult['user']);
        }
      }
      throw Exception(result['message'] ?? 'Failed to load profile');
    }
  }

  Future<UserModel> updateProfile({
    String? name,
    String? phone,
    String? profileImageUrl,
  }) async {
    // TODO: Implement update profile API call
    // For now, just reload profile
    return getProfile();
  }
}