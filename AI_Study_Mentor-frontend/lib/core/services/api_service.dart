import 'dart:convert';
import 'dart:async';
import 'dart:io' show Platform, SocketException;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'navigator_key.dart';

class ApiService {
  // Tự chọn URL theo platform:
  // - Web (Chrome): localhost
  // - Windows desktop: localhost
  // - Android emulator: 10.0.2.2 (trỏ về máy host)
  // - Android thật: đổi thành IP LAN của máy tính
  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:8080';
    try {
      if (Platform.isAndroid) return 'http://10.24.32.32:8080';
      // Windows, macOS, Linux desktop
      return 'http://localhost:8080';
    } catch (_) {
      return 'http://localhost:8080';
    }
  }

  static const _timeout = Duration(seconds: 30);
  static const _aiTimeout = Duration(seconds: 60);

  static String? _token;
  static String? _userId;
  static String? _email;
  static String? _educationLevel;
  static String? _preferredStyle;
  static int _xpPoints = 0;

  static String? get token => _token;
  static String? get userId => _userId;
  static String? get email => _email;
  static String? get educationLevel => _educationLevel;
  static String? get preferredStyle => _preferredStyle;
  static int get xpPoints => _xpPoints;
  static bool get isLoggedIn => _token != null;

  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  // ── XỬ LÝ 401: token hết hạn ────────────────────────
  static void _handle401() {
    _token = null; _userId = null;
    clearSession();
    try {
      final nav = navigatorKey.currentState;
      if (nav != null) nav.pushNamedAndRemoveUntil('/', (_) => false);
    } catch (_) {}
  }

  // ── Wrapper an toàn — KHÔNG BAO GIỜ CRASH ────────────
  static Future<Map<String, dynamic>> _safePost(String path, Map<String, dynamic> body,
      {Duration timeout = const Duration(seconds: 30)}) async {
    try {
      final url = '$baseUrl$path';
      final res = await http.post(Uri.parse(url),
        headers: _headers, body: jsonEncode(body)).timeout(timeout);
      if (res.statusCode == 401 || res.statusCode == 403) {
        _handle401();
        return {'success': false, 'message': 'Phiên đăng nhập hết hạn. Đăng nhập lại.'};
      }
      final decoded = jsonDecode(res.body);
      if (decoded is Map<String, dynamic>) return decoded;
      return {'success': false, 'message': 'Dữ liệu không hợp lệ'};
    } on TimeoutException {
      return {'success': false, 'message': 'Hết thời gian chờ. Thử lại sau.'};
    } on http.ClientException catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: ${e.message}'};
    } catch (e) {
      // Bắt SocketException qua string vì web không có dart:io
      final msg = e.toString();
      if (msg.contains('SocketException') || msg.contains('Connection refused')) {
        return {'success': false, 'message': 'Không kết nối được server.\nKiểm tra backend đã chạy chưa.'};
      }
      return {'success': false, 'message': 'Lỗi kết nối mạng.'};
    }
  }

  static Future<Map<String, dynamic>> _safeGet(String path) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl$path'), headers: _headers).timeout(_timeout);
      if (res.statusCode == 401 || res.statusCode == 403) {
        _handle401();
        return {'success': false, 'message': 'Phiên đăng nhập hết hạn.'};
      }
      final decoded = jsonDecode(res.body);
      if (decoded is Map<String, dynamic>) return decoded;
      return {'success': false, 'message': 'Dữ liệu không hợp lệ'};
    } on TimeoutException {
      return {'success': false, 'message': 'Hết thời gian chờ.'};
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối.'};
    }
  }

  // ── Session ───────────────────────────────────────────
  static Future<void> _saveSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_token != null) prefs.setString('token', _token!);
      if (_userId != null) prefs.setString('userId', _userId!);
      if (_email != null) prefs.setString('email', _email!);
      if (_educationLevel != null) prefs.setString('educationLevel', _educationLevel!);
      if (_preferredStyle != null) prefs.setString('preferredStyle', _preferredStyle!);
      prefs.setInt('xpPoints', _xpPoints);
    } catch (_) {}
  }

  static Future<bool> loadSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('token');
      _userId = prefs.getString('userId');
      _email = prefs.getString('email');
      _educationLevel = prefs.getString('educationLevel');
      _preferredStyle = prefs.getString('preferredStyle');
      _xpPoints = prefs.getInt('xpPoints') ?? 0;
      return _token != null;
    } catch (_) { return false; }
  }

  static Future<void> clearSession() async {
    _token = null; _userId = null; _email = null;
    _educationLevel = null; _preferredStyle = null; _xpPoints = 0;
    try { (await SharedPreferences.getInstance()).clear(); } catch (_) {}
  }

  // ── Auth ──────────────────────────────────────────────
  static Future<Map<String, dynamic>> login(String email, String password) async {
    final body = await _safePost('/api/auth/login', {'email': email, 'password': password});
    _extractAuth(body);
    return body;
  }

  static Future<Map<String, dynamic>> register(String email, String password, String fullName) async {
    final body = await _safePost('/api/auth/register', {'email': email, 'password': password, 'fullName': fullName});
    _extractAuth(body);
    return body;
  }

  static void _extractAuth(Map<String, dynamic> body) {
    if (body['success'] == true && body['data'] != null && body['data'] is Map) {
      final data = body['data'] as Map<String, dynamic>;
      _token = data['token']?.toString();
      _userId = data['userId']?.toString();
      _email = data['email']?.toString();
      _educationLevel = data['educationLevel']?.toString();
      _preferredStyle = data['preferredStyle']?.toString();
      _xpPoints = (data['xpPoints'] is num) ? (data['xpPoints'] as num).toInt() : 0;
      _saveSession();
    }
  }

  // ── AI Ask ────────────────────────────────────────────
  static Future<Map<String, dynamic>> askAI(String question, {String? imageBase64, String? mimeType}) async {
    final body = <String, dynamic>{'contentText': question};
    if (imageBase64 != null) body['imageBase64'] = imageBase64;
    if (mimeType != null) body['imageMimeType'] = mimeType;
    return _safePost('/api/ai/ask', body, timeout: _aiTimeout);
  }

  static Future<List<dynamic>> getHistory() async {
    try {
      final body = await _safeGet('/api/ai/history');
      if (body['success'] == true && body['data'] is List) return body['data'] as List;
      return [];
    } catch (_) { return []; }
  }

  // ── Quiz ──────────────────────────────────────────────
  static Future<Map<String, dynamic>> generateQuiz(String topic, {int num = 5}) async {
    return _safePost('/api/quiz/generate', {'topic': topic, 'numQuestions': num}, timeout: _aiTimeout);
  }

  static Future<Map<String, dynamic>> gradeQuiz(String qqId, String answer) async {
    return _safePost('/api/quiz/grade', {'qqId': qqId, 'userAnswer': answer});
  }

  // ── Profile ───────────────────────────────────────────
  static Future<Map<String, dynamic>> getProfile() async {
    final body = await _safeGet('/api/users/me');
    if (body['success'] == true && body['data'] is Map) {
      final d = body['data'] as Map<String, dynamic>;
      _xpPoints = (d['xpPoints'] is num) ? (d['xpPoints'] as num).toInt() : _xpPoints;
      _educationLevel = d['educationLevel']?.toString() ?? _educationLevel;
      _preferredStyle = d['preferredStyle']?.toString() ?? _preferredStyle;
    }
    return body;
  }

  static Future<List<dynamic>> getNotifications() async {
    try {
      final body = await _safeGet('/api/notifications');
      if (body['success'] == true && body['data'] is List) return body['data'] as List;
      return [];
    } catch (_) { return []; }
  }

  static Future<Map<String, dynamic>> addBookmark(String questionId) async {
    return _safePost('/api/bookmarks', {'questionId': questionId});
  }

  static Future<List<dynamic>> getBookmarks() async {
    try {
      final body = await _safeGet('/api/bookmarks');
      if (body['success'] == true && body['data'] is List) return body['data'] as List;
      return [];
    } catch (_) { return []; }
  }

  static Future<List<dynamic>> getLeaderboard() async {
    try {
      final body = await _safeGet('/api/leaderboard');
      if (body['success'] == true && body['data'] is List) return body['data'] as List;
      return [];
    } catch (_) { return []; }
  }
}
