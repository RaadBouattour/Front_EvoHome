import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  static const String baseUrl = 'http://localhost:4000/api/auth';
  static final _storage = FlutterSecureStorage();

  static Future<void> saveToken(String token) async {
    await _storage.write(key: 'access_token', value: token);
  }

  static Future<String?> _getToken() async {
    return await _storage.read(key: 'access_token');
  }

  static Future<void> logout() async {
    await _storage.delete(key: 'access_token');
  }

  static Future<Map<String, dynamic>> login(String email, String password) async {
    final url = Uri.parse('$baseUrl/signin');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await saveToken(data['token']);
      return {
        'success': true,
        'token': data['token'],
        'user': data['user'],
      };
    } else {
      return {
        'success': false,
        'message': 'Login failed: ${response.body}',
      };
    }
  }

  static Future<void> signup({
    required String firstname,
    required String lastname,
    required String email,
    required String password,
  }) async {
    final url = Uri.parse('$baseUrl/signup');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'firstname': firstname,
        'lastname': lastname,
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception(jsonDecode(response.body)['message'] ?? 'Signup failed');
    }
  }

  static Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    final url = Uri.parse('$baseUrl/reset-password');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'code': code,
        'newPassword': newPassword,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(jsonDecode(response.body)['message'] ?? 'Failed to reset password');
    }
  }

  static Future<void> verifyResetCode({
    required String email,
    required String code,
  }) async {
    final url = Uri.parse('$baseUrl/verify-code');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'code': code,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(jsonDecode(response.body)['message'] ?? 'Invalid code');
    }
  }

  static Future<void> requestPasswordReset(String email) async {
    final url = Uri.parse('$baseUrl/request-reset');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );

    if (response.statusCode != 200) {
      throw Exception(jsonDecode(response.body)['message'] ?? 'Failed to send reset code');
    }
  }

  static Future<Map<String, dynamic>> getUserProfile() async {
    final token = await _getToken();

    final response = await http.get(
      Uri.parse('$baseUrl/me'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load profile: ${response.statusCode}');
    }
  }

  static Future<bool> updateUserField(String field, String value) async {
    final token = await _getToken();

    final body = jsonEncode({field.toLowerCase(): value});
    print("🔄 Sending update request for field: $field");
    print("📦 Payload: $body");

    final response = await http.put(
      Uri.parse('$baseUrl/info'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: body,
    );

    if (response.statusCode == 200) {
      print("✅ $field updated successfully");
      return true;
    } else {
      print('❌ Error updating $field: ${response.body}');
      return false;
    }
  }



  static Future<bool> updateEmailWithPassword({
    required String oldEmail,
    required String newEmail,
    required String password,
  }) async {
    final token = await _getToken(); // ✅ Get the token

    final url = Uri.parse('$baseUrl/email');
    final response = await http.put(
      url,
      headers: {
        'Authorization': 'Bearer $token', // ✅ ADD THIS LINE
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'oldEmail': oldEmail,
        'newEmail': newEmail,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Failed to update email');
    }
  }



}
