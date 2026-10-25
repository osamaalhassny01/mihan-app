/// إعدادات اتصال التطبيق بسيرفر الباك إند
class ApiConfig {
  /// الرابط الأساسي لسيرفر الباك إند السحابي في Production (Railway)
  static const String baseUrl = 'https://mihan-backend-production.up.railway.app';

  /// الروابط الافتراضية المقترحة للتبديل السريع
  static const List<Map<String, String>> serverPresets = [
    {
      'name': '☁️ السيرفر السحابي (Railway Production)',
      'url': 'https://mihan-backend-production.up.railway.app',
      'desc': 'السيرفر المباشر النشط على الإنترنت',
    },
    {
      'name': '📱 محاكي أندرويد (Android Emulator)',
      'url': 'http://10.0.2.2/mihan',
      'desc': 'للاتصال بـ localhost الحاسوب عبر المحاكي',
    },
    {
      'name': '💻 خادم محلي مباشر (Local XAMPP / Apache)',
      'url': 'http://localhost/mihan',
      'desc': 'عند تشغيل التطبيق على الويب أو سطح المكتب',
    },
  ];

  /// مسار واجهات برمجة التطبيقات
  static const String apiPrefix = '/api';

  /// اسم المنصة
  static const String appName = 'مِهَن - MIHAN';

  /// مهلة الاتصال بالثواني
  static const int timeoutSeconds = 15;
}
