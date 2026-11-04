import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'storage_service.dart';
import 'api_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('FCM Background Message: ${message.messageId} - ${message.notification?.title}');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// تهيئة Firebase وخدمة الإشعارات
  static Future<void> initialize() async {
    try {
      await Firebase.initializeApp();
      debugPrint('Firebase Core Initialized Successfully.');

      // إعداد معالج الإشعارات في الخلفية
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // طلب الإذن بالإشعارات (خاصة بنظام Android 13+ و iOS)
      final settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      debugPrint('FCM Authorization Status: ${settings.authorizationStatus}');

      // جلب وحفظ توكن الجهاز
      await updateDeviceToken();

      // الاستماع لتجديد التوكن
      _messaging.onTokenRefresh.listen((newToken) async {
        debugPrint('FCM Token Refreshed: $newToken');
        await StorageService.saveFcmToken(newToken);
        await syncTokenWithBackend(newToken);
      });

      // استقبال الإشعارات أثناء فتح التطبيق (Foreground)
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('FCM Foreground Message: ${message.notification?.title} - ${message.notification?.body}');
        // يمكن هنا إظهار SnackBar أو تنبيه محلي داخل التطبيق
      });

      // التعامل مع الضغط على الإشعار والتطبيق بالخلفية
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('FCM Notification Clicked (Background): ${message.data}');
      });

      // التعامل مع الإشعار الذي تسبب بفتح التطبيق من وضع الإغلاق التام
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('FCM Initial Message (Terminated): ${initialMessage.data}');
      }
    } catch (e) {
      debugPrint('Error initializing Firebase / FCM: $e');
    }
  }

  /// استخراج توكن الجهاز وحفظه محلياً
  static Future<String?> updateDeviceToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null && token.isNotEmpty) {
        debugPrint('FCM Device Token: $token');
        await StorageService.saveFcmToken(token);
        await syncTokenWithBackend(token);
        return token;
      }
    } catch (e) {
      debugPrint('Failed to get FCM token: $e');
    }
    return null;
  }

  /// إرسال توكن الإشعارات إلى السيرفر لربطه بحساب المستخدم الحالي
  static Future<void> syncTokenWithBackend(String fcmToken) async {
    try {
      final authToken = await StorageService.getToken();
      if (authToken == null || authToken.isEmpty) {
        return; // المستخدم لم يسجل الدخول بعد
      }
      await ApiService.post('/api/profile/fcm-token', {
        'fcm_token': fcmToken,
      });
      debugPrint('FCM Token synced with backend.');
    } catch (e) {
      debugPrint('Failed to sync FCM token with backend: $e');
    }
  }
}
