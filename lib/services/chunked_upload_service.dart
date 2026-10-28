import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'api_service.dart';
import 'storage_service.dart';

class ChunkedUploadProgress {
  final int currentChunk;
  final int totalChunks;
  final double percentage;
  final int bytesSent;
  final int totalBytes;

  ChunkedUploadProgress({
    required this.currentChunk,
    required this.totalChunks,
    required this.percentage,
    required this.bytesSent,
    required this.totalBytes,
  });
}

class ChunkedUploadService {
  // الحجم الافتراضي لكل جزء: 2 ميجابايت لتفادي تجاوز مهلة الشبكة واستقرار الاتصال
  static const int defaultChunkSize = 2 * 1024 * 1024;
  // الحد الأقصى للملف: 300 ميجابايت
  static const int maxFileSizeBytes = 300 * 1024 * 1024;

  /// رفع ملف كبير بنظام التجزئة متعدد الأجزاء (Chunked Multipart Upload)
  static Future<ApiResponse> uploadLargeFile({
    required File file,
    int chunkSize = defaultChunkSize,
    void Function(ChunkedUploadProgress progress)? onProgress,
  }) async {
    try {
      if (!await file.exists()) {
        return ApiResponse(
          success: false,
          message: 'الملف المطلوب رفعه غير موجود على مسار الجهاز.',
        );
      }

      final totalBytes = await file.length();
      if (totalBytes > maxFileSizeBytes) {
        return ApiResponse(
          success: false,
          message: 'حجم الملف يتجاوز الحد الأقصى المسموح به (300 ميجابايت).',
        );
      }

      final baseUrl = await StorageService.getBaseUrl();
      final token = await StorageService.getToken();
      final uploadUri = Uri.parse('$baseUrl/api/upload/chunk');

      // إنشاء معرف فريد لعملية الرفع
      final fileName = file.path.split(Platform.pathSeparator).last;
      final uploadId = 'up_${DateTime.now().millisecondsSinceEpoch}_$totalBytes';
      final totalChunks = (totalBytes / chunkSize).ceil();

      final randomAccessFile = await file.open(mode: FileMode.read);
      int bytesSent = 0;
      ApiResponse? lastResponse;

      for (int chunkIndex = 0; chunkIndex < totalChunks; chunkIndex++) {
        final start = chunkIndex * chunkSize;
        final currentChunkLength = (start + chunkSize > totalBytes)
            ? (totalBytes - start)
            : chunkSize;

        await randomAccessFile.setPosition(start);
        final chunkBytes = await randomAccessFile.read(currentChunkLength);

        // تجهيز طلب الإرسال متعدد الأجزاء
        final request = http.MultipartRequest('POST', uploadUri);
        if (token != null && token.isNotEmpty) {
          request.headers['Authorization'] = 'Bearer $token';
        }
        request.headers['Accept'] = 'application/json';

        request.fields['upload_id'] = uploadId;
        request.fields['chunk_index'] = chunkIndex.toString();
        request.fields['total_chunks'] = totalChunks.toString();
        request.fields['file_name'] = fileName;

        request.files.add(
          http.MultipartFile.fromBytes(
            'file_chunk',
            chunkBytes,
            filename: 'part_$chunkIndex',
          ),
        );

        final streamedResponse = await request.send().timeout(const Duration(seconds: 45));
        final response = await http.Response.fromStream(streamedResponse);

        if (response.statusCode >= 200 && response.statusCode < 300) {
          final data = jsonDecode(utf8.decode(response.bodyBytes));
          lastResponse = ApiResponse.fromJson(data, statusCode: response.statusCode);

          bytesSent += chunkBytes.length;
          final percentage = (bytesSent / totalBytes).clamp(0.0, 1.0);

          if (onProgress != null) {
            onProgress(ChunkedUploadProgress(
              currentChunk: chunkIndex + 1,
              totalChunks: totalChunks,
              percentage: percentage,
              bytesSent: bytesSent,
              totalBytes: totalBytes,
            ));
          }
        } else {
          await randomAccessFile.close();
          try {
            final errorData = jsonDecode(utf8.decode(response.bodyBytes));
            return ApiResponse.fromJson(errorData, statusCode: response.statusCode);
          } catch (_) {
            return ApiResponse(
              success: false,
              message: 'فشل في رفع الجزء $chunkIndex (كود الخطأ: ${response.statusCode})',
              statusCode: response.statusCode,
            );
          }
        }
      }

      await randomAccessFile.close();
      return lastResponse ?? ApiResponse(success: true, message: 'اكتمل الرفع بنجاح');
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'حدث استثناء أثناء رفع الملف بالتجزئة: $e',
      );
    }
  }
}
