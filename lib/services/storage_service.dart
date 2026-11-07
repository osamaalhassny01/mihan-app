import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/user_model.dart';

class StorageService {
  static const String _keyToken = 'auth_token';
  static const String _keyUser = 'auth_user';
  static const String _keyBaseUrl = 'api_base_url';
  static const String _keyFcmToken = 'fcm_token';
  static const String _keySavedAccounts = 'saved_accounts';

  static Future<void> saveFcmToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyFcmToken, token);
  }

  static Future<void> clearFcmToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyFcmToken);
  }

  static Future<String?> getFcmToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyFcmToken);
  }

  static Future<List<Map<String, String>>> getSavedAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keySavedAccounts);
    if (raw == null || raw.isEmpty) return [];
    try {
      final List decoded = jsonDecode(raw);
      return decoded.map((e) => Map<String, String>.from(e as Map)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveSavedAccount({
    required String email,
    required String name,
    required String role,
  }) async {
    if (email.trim().isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final list = await getSavedAccounts();

    // Remove existing if already present
    list.removeWhere((item) => (item['email'] ?? '').toLowerCase() == email.trim().toLowerCase());

    // Insert at beginning (most recently used)
    list.insert(0, {
      'email': email.trim(),
      'name': name.trim().isNotEmpty ? name.trim() : email.trim(),
      'role': role,
      'saved_at': DateTime.now().toIso8601String(),
    });

    if (list.length > 10) {
      list.removeRange(10, list.length);
    }

    await prefs.setString(_keySavedAccounts, jsonEncode(list));
  }

  static Future<void> removeSavedAccount(String email) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await getSavedAccounts();
    list.removeWhere((item) => (item['email'] ?? '').toLowerCase() == email.trim().toLowerCase());
    await prefs.setString(_keySavedAccounts, jsonEncode(list));
  }

  static Future<void> clearAllSavedAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keySavedAccounts);
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, token);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyToken);
  }

  static Future<void> saveUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUser, jsonEncode(user.toJson()));
  }

  static Future<UserModel?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_keyUser);
    if (data == null || data.isEmpty) return null;
    try {
      return UserModel.fromJson(jsonDecode(data) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  static Future<String> getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final url = prefs.getString(_keyBaseUrl);
    if (url == null || url.isEmpty || url.contains('127.0.0.1') || url.contains('localhost')) {
      return ApiConfig.baseUrl;
    }
    return url;
  }

  static Future<void> setBaseUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyBaseUrl, url);
  }

  static Future<void> clearAuth() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
    await prefs.remove(_keyUser);
  }
}
