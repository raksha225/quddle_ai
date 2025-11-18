import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/helpers/storage.dart';
import 'auth_service.dart';

class WalletService {
  static String get _baseUrl => AuthService.baseUrl;

  // Get wallet balance
  static Future<Map<String, dynamic>> getWallet() async {
    try {
      final token = await SecureStorage.readToken();
      if (token == null) {
        return {'success': false, 'message': 'Authentication required'};
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/wallet'),
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

  // Get wallet transactions
  static Future<Map<String, dynamic>> getTransactions() async {
    try {
      final token = await SecureStorage.readToken();
      if (token == null) {
        return {'success': false, 'message': 'Authentication required'};
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/wallet/transactions'),
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

  // Add money to wallet (Virtual)
  static Future<Map<String, dynamic>> addMoneyVirtual(double amount) async {
    try {
      final token = await SecureStorage.readToken();
      if (token == null) {
        return {'success': false, 'message': 'Authentication required'};
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/wallet/add-money'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'amount': amount,
        }),
      );

      final data = jsonDecode(response.body);
      return data;
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }
}
