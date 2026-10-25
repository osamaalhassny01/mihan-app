/// إعدادات اتصال التطبيق بسيرفر الباك إند
class ApiConfig {
  /// الرابط الأساسي لسيرفر الباك إند السحابي في Production (Railway)
  static const String baseUrl = 'https://mihan-backend-production.up.railway.app';

  /// مسار واجهات برمجة التطبيقات
  static const String apiPrefix = '/api';

  /// اسم المنصة
  static const String appName = 'مِهَن - MIHAN';

  /// مهلة الاتصال بالثواني
  static const int timeoutSeconds = 15;
}
