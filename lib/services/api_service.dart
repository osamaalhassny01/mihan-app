import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'storage_service.dart';

class ApiResponse {
  final bool success;
  final String message;
  final dynamic data;
  final dynamic errors;
  final int? statusCode;

  ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.errors,
    this.statusCode,
  });

  factory ApiResponse.fromJson(Map<String, dynamic> json, {int? statusCode}) {
    return ApiResponse(
      success: json['success'] == true,
      message: json['message']?.toString() ?? '',
      data: json['data'],
      errors: json['errors'],
      statusCode: statusCode,
    );
  }
}

class ServerHealthResult {
  final bool isConnected;
  final String message;
  final int latencyMs;
  final String? serverName;
  final String url;

  ServerHealthResult({
    required this.isConnected,
    required this.message,
    required this.latencyMs,
    this.serverName,
    required this.url,
  });
}

class ApiService {
  static const Duration _timeout = Duration(seconds: 15);

  /// فحص مباشر وصحي لحالة الاتصال بالسيرفر
  static Future<ServerHealthResult> checkHealth({String? customUrl}) async {
    final baseUrl = customUrl ?? await StorageService.getBaseUrl();
    final stopwatch = Stopwatch()..start();

    try {
      final uri = Uri.parse('$baseUrl/api/ping');
      final res = await http.get(uri).timeout(const Duration(seconds: 8));
      stopwatch.stop();

      if (res.statusCode >= 200 && res.statusCode < 300) {
        try {
          final data = jsonDecode(utf8.decode(res.bodyBytes));
          return ServerHealthResult(
            isConnected: true,
            message: data['message'] ?? 'الخادم يعمل بصورة ممتازة',
            latencyMs: stopwatch.elapsedMilliseconds,
            serverName: data['data']?['server'] ?? 'MIHAN Backend',
            url: baseUrl,
          );
        } catch (_) {
          return ServerHealthResult(
            isConnected: true,
            message: 'متصل بالخادم بنجاح',
            latencyMs: stopwatch.elapsedMilliseconds,
            url: baseUrl,
          );
        }
      } else {
        // Fallback test /api/categories
        final catUri = Uri.parse('$baseUrl/api/categories');
        final catRes = await http.get(catUri).timeout(const Duration(seconds: 8));
        if (catRes.statusCode >= 200 && catRes.statusCode < 300) {
          return ServerHealthResult(
            isConnected: true,
            message: 'متصل بالخادم (استجابة الكتالوج)',
            latencyMs: stopwatch.elapsedMilliseconds,
            url: baseUrl,
          );
        }
        return ServerHealthResult(
          isConnected: false,
          message: 'استجاب السيرفر برمز خطأ (${res.statusCode})',
          latencyMs: stopwatch.elapsedMilliseconds,
          url: baseUrl,
        );
      }
    } on SocketException catch (e) {
      stopwatch.stop();
      return ServerHealthResult(
        isConnected: false,
        message: 'تعذر الوصول للسيرفر: تأكد من العنوان والإنترنت (${e.osError?.message ?? "خطأ مقبس"})',
        latencyMs: 0,
        url: baseUrl,
      );
    } on TimeoutException {
      stopwatch.stop();
      return ServerHealthResult(
        isConnected: false,
        message: 'انتهت مهلة انتظار استجابة السيرفر (تجاوز 8 ثوانٍ)',
        latencyMs: 0,
        url: baseUrl,
      );
    } catch (e) {
      stopwatch.stop();
      return ServerHealthResult(
        isConnected: false,
        message: 'تعذر الاتصال بالسيرفر: $e',
        latencyMs: 0,
        url: baseUrl,
      );
    }
  }

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
    } on SocketException catch (e) {
      return ApiResponse(
        success: false,
        message: 'تعذر الاتصال بالخادم. تحقق من رابط السيرفر واتصالك بالإنترنت. (${e.message})',
      );
    } on TimeoutException {
      return ApiResponse(
        success: false,
        message: 'انتهت مهلة الاتصال بالخادم دون استجابة (15 ثانية).',
      );
    } on HttpException {
      return ApiResponse(success: false, message: 'خطأ في بروتوكول الاتصال بالخادم.');
    } on FormatException {
      return ApiResponse(success: false, message: 'استجابة غير صالحة من الخادم (تنسيق غير متوقع).');
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
    } on SocketException catch (e) {
      return ApiResponse(
        success: false,
        message: 'تعذر الاتصال بالخادم أثناء إرسال البيانات. تحقق من الرابط والإنترنت. (${e.message})',
      );
    } on TimeoutException {
      return ApiResponse(
        success: false,
        message: 'استغرق إرسال البيانات وقتًا طويلاً وانتهت المهلة.',
      );
    } catch (e) {
      return ApiResponse(success: false, message: 'حدث خطأ أثناء إرسال البيانات: $e');
    }
  }

  static ApiResponse _parseResponse(http.Response response) {
    try {
      final body = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      return ApiResponse.fromJson(body, statusCode: response.statusCode);
    } catch (_) {
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiResponse(success: true, message: 'تم بنجاح', statusCode: response.statusCode);
      }
      return ApiResponse(
        success: false,
        message: 'فشل الطلب مع رمز الحالة (${response.statusCode})',
        statusCode: response.statusCode,
      );
    }
  }
}
