import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Use 10.0.2.2 for Android Emulator, localhost for iOS Simulator/Web
  // You might need to change this to your PC's local IP (e.g., 192.168.1.x) if testing on a physical device.
  static const String _baseUrl = 'http://localhost:5000/api';

  static String? _token;
  static Map<String, dynamic>? currentUser;

  // ─── Auth Token Management ────────────────────────────────────
  static Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    if (_token != null) {
      await fetchCurrentUser();
    }
  }

  static Future<void> _saveToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  static Future<void> logout() async {
    if (_token != null) {
      try {
        await http.post(
          Uri.parse('$_baseUrl/auth/logout'),
          headers: {'Authorization': 'Bearer $_token'},
        );
      } catch (_) {}
    }
    _token = null;
    currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  static bool get isAuthenticated => _token != null;

  // ─── Auth API ────────────────────────────────────────────────
  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );
      final data = jsonDecode(res.body);
      if (res.statusCode == 200 && data['success']) {
        await _saveToken(data['data']['token']);
        currentUser = data['data']['user'];
        return {'success': true};
      }
      return {'success': false, 'error': data['error'] ?? 'Login failed'};
    } catch (e) {
      return {'success': false, 'error': 'Network error'};
    }
  }

  static Future<Map<String, dynamic>> register(String name, String email, String password) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': name, 'email': email, 'password': password}),
      );
      final data = jsonDecode(res.body);
      if (res.statusCode == 200 && data['success']) {
        await _saveToken(data['data']['token']);
        currentUser = data['data']['user'];
        return {'success': true};
      }
      return {'success': false, 'error': data['error'] ?? 'Registration failed'};
    } catch (e) {
      return {'success': false, 'error': 'Network error'};
    }
  }

  static Future<void> fetchCurrentUser() async {
    if (_token == null) return;
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/auth/me'),
        headers: {'Authorization': 'Bearer $_token'},
      );
      final data = jsonDecode(res.body);
      if (res.statusCode == 200 && data['success']) {
        currentUser = data['data'];
      } else {
        await logout();
      }
    } catch (e) {
      debugPrint('Fetch user error: $e');
    }
  }

  // ─── Health Check ────────────────────────────────────────────
  static Future<bool> isBackendOnline() async {
    try {
      final res = await http
          .get(Uri.parse('$_baseUrl/health'))
          .timeout(const Duration(seconds: 3));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ─── Stats ───────────────────────────────────────────────────
  static Future<Map<String, dynamic>?> getStats() async {
    try {
      final res = await http
          .get(Uri.parse('$_baseUrl/stats'))
          .timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        return jsonDecode(res.body)['data'];
      }
    } catch (e) {
      debugPrint('Stats error: $e');
    }
    return null;
  }

  // ─── Detect ──────────────────────────────────────────────────
  static Future<Map<String, dynamic>?> detectImage({
    required Uint8List imageBytes,
    String modelId = 'yolov9e',
    double? lat,
    double? lng,
    String? locationName,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/detect?model=$modelId'),
      );
      
      if (_token != null) {
        request.headers['Authorization'] = 'Bearer $_token';
      }

      if (lat != null) request.fields['latitude'] = lat.toString();
      if (lng != null) request.fields['longitude'] = lng.toString();
      if (locationName != null) request.fields['location_name'] = locationName;

      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          imageBytes,
          filename: 'upload.jpg',
        ),
      );
      final streamedRes = await request.send().timeout(const Duration(seconds: 25));
      final res = await http.Response.fromStream(streamedRes);
      if (res.statusCode == 200) {
        return jsonDecode(res.body)['data'];
      }
    } catch (e) {
      debugPrint('Detect error: $e');
    }
    return null;
  }

  // ─── History ─────────────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> getHistory({int limit = 20}) async {
    if (_token == null) return [];
    try {
      final res = await http
          .get(
            Uri.parse('$_baseUrl/history?limit=$limit'),
            headers: {'Authorization': 'Bearer $_token'},
          )
          .timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body)['data'] as List;
        return data.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      debugPrint('History error: $e');
    }
    return [];
  }

  // ─── Models ──────────────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> getModels() async {
    try {
      final res = await http
          .get(Uri.parse('$_baseUrl/models'))
          .timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body)['data'] as List;
        return data.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      debugPrint('Models error: $e');
    }
    return [];
  }
}
