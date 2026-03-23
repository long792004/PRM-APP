import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../config/app_config.dart';

class ApiService {
  static const String baseUrl = AppConfig.baseUrl;

  /// Chuyển đổi path tương đối (/uploads/...) thành URL tuyệt đối (http://localhost:3000/uploads/...)
  static String getFullAudioUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http')) return url; // Link ngoài (S3, Youtube, etc.)
    
    // Xóa '/api' ở cuối baseUrl để lấy Domain gốc
    final rootUrl = baseUrl.replaceAll('/api', '');
    // Đảm bảo không bị double slash
    final cleanUrl = url.startsWith('/') ? url : '/$url';
    return '$rootUrl$cleanUrl';
  }

  // ─── TOKEN HELPERS ────────────────────────────────────────────────────────

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', token);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    await prefs.remove('user_role');
    await prefs.remove('user_email');
  }

  static Future<void> saveUserInfo(String role, String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_role', role);
    await prefs.setString('user_email', email);
  }

  static Future<Map<String, String?>> getUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'role': prefs.getString('user_role'),
      'email': prefs.getString('user_email'),
    };
  }

  // ─── HEADER ───────────────────────────────────────────────────────────────

  static Future<Map<String, String>> _authHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ─── AUTH ─────────────────────────────────────────────────────────────────

  /// Trả về {'token': ..., 'user': {'role': ..., 'email': ...}}
  static Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200) {
      return data;
    }
    throw Exception(data['error'] ?? 'Đăng nhập thất bại');
  }

  /// Đăng ký user mới — role luôn là 'user' do BE quy định
  static Future<void> register(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 201) {
      throw Exception(data['error'] ?? 'Đăng ký thất bại');
    }
  }

  // ─── EXAMS ───────────────────────────────────────────────────────────────

  static Future<List<dynamic>> getExams() async {
    final headers = await _authHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/admin/exams'),
      headers: headers,
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    }
    throw Exception('Không thể tải bài thi');
  }

  static Future<Map<String, dynamic>> createExam(Map<String, dynamic> data, {List<http.MultipartFile>? files}) async {
    final token = await getToken();
    
    if (files == null || files.isEmpty) {
      final headers = await _authHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/admin/exams'),
        headers: headers,
        body: jsonEncode(data),
      );
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 201) return body;
      throw Exception(body['error'] ?? 'Không thể tạo bài thi');
    } else {
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/admin/exams'));
      if (token != null) request.headers['Authorization'] = 'Bearer $token';
      
      request.fields['examData'] = jsonEncode(data);
      request.files.addAll(files);

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      
      if (response.statusCode == 201) return body;
      throw Exception(body['error'] ?? 'Không thể tạo bài thi');
    }
  }

  static Future<Map<String, dynamic>> updateExam(String id, Map<String, dynamic> data, {List<http.MultipartFile>? files}) async {
    final token = await getToken();
    
    if (files == null || files.isEmpty) {
      final headers = await _authHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/admin/exams/$id'),
        headers: headers,
        body: jsonEncode(data),
      );
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) return body;
      throw Exception(body['error'] ?? 'Không thể cập nhật bài thi');
    } else {
      var request = http.MultipartRequest('PUT', Uri.parse('$baseUrl/admin/exams/$id'));
      if (token != null) request.headers['Authorization'] = 'Bearer $token';
      
      request.fields['examData'] = jsonEncode(data);
      request.files.addAll(files);

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      
      if (response.statusCode == 200) return body;
      throw Exception(body['error'] ?? 'Không thể cập nhật bài thi');
    }
  }

  static Future<void> deleteExam(String id) async {
    final headers = await _authHeaders();
    final response = await http.delete(
      Uri.parse('$baseUrl/admin/exams/$id'),
      headers: headers,
    );
    if (response.statusCode != 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(body['error'] ?? 'Không thể xóa bài thi');
    }
  }

  // ─── RECORDINGS / HISTORY ────────────────────────────────────────────────

  static Future<List<dynamic>> getHistory() async {
    final headers = await _authHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/users/history'),
      headers: headers,
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    }
    throw Exception('Không thể tải lịch sử');
  }

  // ─── SUBMISSIONS ─────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> submitWriting(String questionId, String essay) async {
    final headers = await _authHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/submissions/writing'),
      headers: headers,
      body: jsonEncode({
        'questionId': questionId,
        'essay': essay,
      }),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 201) return data['data'];
    throw Exception(data['error'] ?? 'Lỗi gửi bài Writing');
  }

  static Future<Map<String, dynamic>> submitSpeaking(String questionId, String audioFilePath) async {
    final token = await getToken();
    var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/submissions/speaking'));
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    request.fields['questionId'] = questionId;
    
    if (kIsWeb) {
      final response = await http.get(Uri.parse(audioFilePath));
      request.files.add(http.MultipartFile.fromBytes(
        'audio', 
        response.bodyBytes, 
        filename: 'audio.webm'
      ));
    } else {
      request.files.add(await http.MultipartFile.fromPath('audio', audioFilePath));
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    final data = jsonDecode(response.body);

    if (response.statusCode == 201) return data['data'];
    throw Exception(data['error'] ?? 'Lỗi gửi bài Speaking');
  }

  static Future<Map<String, dynamic>> submitObjective(String examId, List<Map<String, String>> answers) async {
    final headers = await _authHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/submissions/objective'),
      headers: headers,
      body: jsonEncode({
        'examId': examId,
        'answers': answers,
      }),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 201) return data['data'];
    throw Exception(data['error'] ?? 'Lỗi gửi bài Reading/Listening');
  }

  // ─── ADMIN ────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getAdminStats() async {
    final headers = await _authHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/admin/stats'),
      headers: headers,
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Không thể tải thống kê');
  }
}
