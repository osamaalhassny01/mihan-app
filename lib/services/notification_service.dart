import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  static FirebaseMessaging get _messaging => FirebaseMessaging.instance;
  static bool _initialized = false;
  static final ValueNotifier<bool> openInboxRequested = ValueNotifier(false);
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'mihan_channel',
    'إشعارات مِهَن',
    description: 'إشعارات الطلبات وتحديثات الخدمة والرسائل الترحيبية',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  /// تهيئة Firebase والإشعارات المحلية
  static Future<void> initialize() async {
    if (_initialized) return;
    try {
      await Firebase.initializeApp();
      debugPrint('Firebase Core Initialized Successfully.');

      // إعداد الإشعارات المحلية
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
      );

      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (response) {
          openInboxRequested.value = true;
        },
      );

      // إنشاء القناة لنظام Android
      final androidPlatform = _localNotifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlatform != null) {
        await androidPlatform.createNotificationChannel(_channel);
        await androidPlatform.requestNotificationsPermission();
      }

      // إعداد معالج الإشعارات في الخلفية لـ FCM
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // طلب الإذن بالإشعارات عبر Firebase
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

      // الاستماع لتجديد التوكن
      _messaging.onTokenRefresh.listen((newToken) async {
        debugPrint('FCM token refreshed.');
        await StorageService.saveFcmToken(newToken);
        await syncTokenWithBackend(newToken);
      });

      // استقبال الإشعارات أثناء فتح التطبيق (Foreground) وإظهارها كـ Heads-up Notification
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('FCM Foreground Message: ${message.notification?.title} - ${message.notification?.body}');
        final notif = message.notification;
        if (notif != null || message.data['title'] != null) {
          showNotification(
            id: message.hashCode,
            title: notif?.title ?? message.data['title']?.toString() ?? 'مِهَن',
            body: notif?.body ?? message.data['body']?.toString() ?? '',
            payload: message.data.toString(),
          );
        }
      });

      // التفاعل مع النقر على الإشعار من الخلفية
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        openInboxRequested.value = true;
      });

      final initialMessage = await _messaging.getInitialMessage();
      final localLaunch = await _localNotifications.getNotificationAppLaunchDetails();
      if (initialMessage != null || (localLaunch?.didNotificationLaunchApp ?? false)) {
        openInboxRequested.value = true;
      }

      _initialized = true;
      unawaited(updateDeviceToken());

      // إرسال الإشعار الترحيبي عند أول تشغيل للتطبيق
      await checkAndSendWelcomeNotification();
    } catch (e) {
      debugPrint('Error initializing Firebase / Local Notifications: $e');
    }
  }

  /// إظهار إشعار محلي على الجهاز مباشرة
  static Future<void> showNotification({
    int id = 0,
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'mihan_channel',
      'إشعارات مِهَن',
      channelDescription: 'إشعارات الطلبات وتحديثات الخدمة والرسائل الترحيبية',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      playSound: true,
      enableVibration: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(id, title, body, details, payload: payload);
  }

  /// فحص وإرسال الإشعار الترحيبي عند تثبيت/فتح التطبيق لأول مرة
  static Future<void> checkAndSendWelcomeNotification({bool force = false}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final alreadySent = prefs.getBool('welcome_notification_sent') ?? false;

      if (!alreadySent || force) {
        // تأخير بسيط لمدة ثانيتين ليظهر الإشعار بانسيابية بعد فتح الواجهة
        Future.delayed(const Duration(seconds: 2), () async {
          await showNotification(
            id: 1001,
            title: 'أهلاً بك في مِهَن! 🛠️',
            body: 'يسعدنا انضمامك إلى منصة مِهَن، يمكنك الآن استكشاف أفضل الفنيين والخدمات بكل سهولة.',
          );
          await prefs.setBool('welcome_notification_sent', true);
          debugPrint('Welcome notification delivered successfully.');
        });
      }
    } catch (e) {
      debugPrint('Error sending welcome notification: $e');
    }
  }

  /// فحص الإشعارات محلياً (للتجربة المباشرة على الجهاز)
  static Future<void> testNotificationLocally() async {
    await showNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: '🔔 اختبار إشعار مِهَن (محلي)',
      body: 'نظام الإشعارات يعمل بنجاح وبأعلى كفاءة على جهازك!',
    );
  }

  /// استخراج توكن الجهاز وحفظه محلياً
  static Future<String?> updateDeviceToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null && token.isNotEmpty) {
        debugPrint('FCM device token obtained.');
        await StorageService.saveFcmToken(token);
        await syncTokenWithBackend(token);
        return token;
      }
    } catch (e) {
      debugPrint('Failed to get FCM token: $e');
    }
    return null;
  }

  /// إرسال توكن الإشعارات إلى السيرفر
  static Future<bool> syncTokenWithBackend(String fcmToken) async {
    try {
      final authToken = await StorageService.getToken();
      if (authToken == null || authToken.isEmpty) return false;
      final response = await ApiService.post('/api/profile/fcm-token', {
        'fcm_token': fcmToken,
      });
      if (!response.success) {
        debugPrint('FCM token sync failed: ${response.statusCode} ${response.message}');
        return false;
      }
      debugPrint('FCM token synced with backend.');
      return true;
    } catch (e) {
      debugPrint('Failed to sync FCM token with backend: $e');
      return false;
    }
  }

  static Future<void> unregisterDevice() async {
    final token = await StorageService.getFcmToken();
    if (token != null && token.isNotEmpty) {
      try {
        await ApiService.post('/api/profile/fcm-token/remove', {'fcm_token': token})
            .timeout(const Duration(seconds: 3));
      } catch (e) {
        debugPrint('Could not unregister notification device: $e');
      }
    }
    try {
      if (_initialized) await _messaging.deleteToken().timeout(const Duration(seconds: 3));
    } catch (e) {
      debugPrint('Could not delete FCM token: $e');
    }
    await StorageService.clearFcmToken();
  }
}
