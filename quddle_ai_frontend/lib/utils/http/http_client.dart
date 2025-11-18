import 'dart:convert';
import 'package:http/http.dart' as http;

class MyHttpHelper {
  // static const String _baseUrl = 'https://quddle-ai-app.onrender.com';
  // static const String _baseUrl = 'http://10.81.64.145:3000';
  // static const String _baseUrl = 'https://quddle-check.onrender.com';
  // static const String _baseUrl = 'http://10.81.85.41:3000';
  // static const String _baseUrl = 'http://10.81.85.41:3000';
  static const String _baseUrl = 'http://13.232.97.100:3000';
  static const mediaURL = "$_baseUrl/media/";

  // to make a GET request
  static Future<Map<String, dynamic>> get(String endpoint, String token) async {
    final response = await http.get(Uri.parse('$_baseUrl$endpoint/'));
    return _handleResponse(response);
  }

  // to make a POST request
  static Future<Map<String, dynamic>> post(
      String endpoint, dynamic data) async {
    final response = await http.post(Uri.parse('$_baseUrl$endpoint/'),
        headers: {'Content-Type': 'application/json'}, body: json.encode(data));
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> private_post(
      String endpoint, dynamic data, String token) async {
    final response = await http.post(
      Uri.parse('$_baseUrl$endpoint/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token'
      },
      body: json.encode(data),
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> private_get(
      String endpoint, String token) async {
    final response = await http.post(Uri.parse('$_baseUrl$endpoint/'),
        headers: {'Authorization': 'Bearer $token'});
    return _handleResponse(response);
  }

  // Handle the HTTP response
  static Map<String, dynamic> _handleResponse(http.Response response) {
    // print(response.statusCode);
    return json.decode(response.body);
  }
}