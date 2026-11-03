import '../models/mahir_models.dart';
import 'api_service.dart';

class MahirStartSessionResult {
  final bool success;
  final String? sessionToken;
  final int? sessionId;
  final MahirProfessionModel? profession;
  final String? welcomeMessage;
  final String? errorMessage;

  MahirStartSessionResult({
    required this.success,
    this.sessionToken,
    this.sessionId,
    this.profession,
    this.welcomeMessage,
    this.errorMessage,
  });
}

class MahirService {
  /// جلب المهن المتاحة مصنفة حسب الفئات
  static Future<Map<String, List<MahirProfessionModel>>> getProfessions() async {
    try {
      final res = await ApiService.get('/api/mahir/professions', withAuth: false);
      if (!res.success || res.data == null) {
        return {};
      }

      final categoriesData = res.data['categories'];
      if (categoriesData is! Map<String, dynamic>) {
        return {};
      }

      final Map<String, List<MahirProfessionModel>> result = {};
      categoriesData.forEach((key, value) {
        if (value is List) {
          result[key] = value
              .map((item) => MahirProfessionModel.fromJson(item as Map<String, dynamic>))
              .toList();
        }
      });

      return result;
    } catch (_) {
      return {};
    }
  }

  /// بدء جلسة تعليمية جديدة مع ماهر AI
  static Future<MahirStartSessionResult> startSession({int? professionId}) async {
    try {
      final Map<String, dynamic> body = {};
      if (professionId != null) {
        body['profession_id'] = professionId;
      }

      final res = await ApiService.post('/api/mahir/session/start', body, withAuth: false);
      if (!res.success || res.data == null) {
        return MahirStartSessionResult(
          success: false,
          errorMessage: res.message.isNotEmpty ? res.message : 'تعذر بدء الجلسة',
        );
      }

      final data = res.data as Map<String, dynamic>;
      MahirProfessionModel? profession;
      if (data['profession'] is Map<String, dynamic>) {
        profession = MahirProfessionModel.fromJson(data['profession']);
      }

      return MahirStartSessionResult(
        success: true,
        sessionToken: data['session_token']?.toString(),
        sessionId: data['session_id'] is int
            ? data['session_id']
            : int.tryParse(data['session_id']?.toString() ?? ''),
        profession: profession,
        welcomeMessage: data['welcome_message']?.toString(),
      );
    } catch (e) {
      return MahirStartSessionResult(
        success: false,
        errorMessage: 'حدث خطأ أثناء بدء الجلسة: $e',
      );
    }
  }

  /// إرسال رسالة إلى ماهر AI والحصول على الرد التعليمي
  static Future<ApiResponse> sendMessage({
    required String sessionToken,
    required String message,
  }) async {
    return await ApiService.post(
      '/api/mahir/chat',
      {
        'session_token': sessionToken,
        'message': message,
      },
      withAuth: false,
      customTimeout: const Duration(seconds: 60),
    );
  }

  /// جلب تاريخ المحادثة لجلسة معينة
  static Future<List<MahirMessageModel>> getHistory(String sessionToken) async {
    try {
      final res = await ApiService.get('/api/mahir/session/$sessionToken/history', withAuth: false);
      if (!res.success || res.data == null) {
        return [];
      }

      final list = res.data['messages'];
      if (list is List) {
        return list
            .map((item) => MahirMessageModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }
}

