import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'storage_service.dart';

class ApiResponse {
  final bool success;
  final String message;
  final dynamic data;
  final dynamic errors;

  ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.errors,
  });

  factory ApiResponse.fromJson(Map<String, dynamic> json) {
    return ApiResponse(
      success: json['success'] == true,
      message: json['message']?.toString() ?? '',
      data: json['data'],
      errors: json['errors'],
    );
  }
}

class ApiService {
  static const Duration _timeout = Duration(seconds: 15);

  static Future<Map<String, String>> _headers([bool withAuth = true]) async {
    final headers = {
      'Content-Type': 'application/json; charset=utf-8',
      'Accept': 'application/json',
    };

    if (withAuth) {
      final token = await StorageService.getToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  static Future<ApiResponse> get(String endpoint, {bool withAuth = true}) async {
    try {
      final baseUrl = await StorageService.getBaseUrl();
      final uri = Uri.parse('$baseUrl$endpoint');
      final headers = await _headers(withAuth);

      final response = await http.get(uri, headers: headers).timeout(_timeout);
      return _parseResponse(response);
    } on SocketException {
      return ApiResponse(success: false, message: 'تعذر الاتصال بالخادم. تحقق من تشغيل السيرفر أو اتصال الإنترنت.');
    } on HttpException {
      return ApiResponse(success: false, message: 'خطأ في بروتوكول الاتصال بالخادم.');
    } on FormatException {
      return ApiResponse(success: false, message: 'استجابة غير صالحة من الخادم.');
    } catch (e) {
      return ApiResponse(success: false, message: 'حدث خطأ غير متوقع: $e');
    }
  }

  static Future<ApiResponse> post(String endpoint, Map<String, dynamic> body, {bool withAuth = true}) async {
    try {
      final baseUrl = await StorageService.getBaseUrl();
      final uri = Uri.parse('$baseUrl$endpoint');
      final headers = await _headers(withAuth);

      final response = await http.post(
        uri,
        headers: headers,
        body: jsonEncode(body),
      ).timeout(_timeout);

      return _parseResponse(response);
    } on SocketException {
      return ApiResponse(success: false, message: 'تعذر الاتصال بالخادم. تحقق من تشغيل السيرفر.');
    } catch (e) {
      return ApiResponse(success: false, message: 'حدث خطأ أثناء إرسال البيانات: $e');
    }
  }

  static ApiResponse _parseResponse(http.Response response) {
    try {
      final body = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      return ApiResponse.fromJson(body);
    } catch (_) {
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiResponse(success: true, message: 'تم بنجاح');
      }
      return ApiResponse(
        success: false,
        message: 'فشل الطلب مع رمز الحالة (${response.statusCode})',
      );
    }
  }
}
