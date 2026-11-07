import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/app_theme.dart';
import 'controllers/auth_controller.dart';
import 'controllers/customer_controller.dart';
import 'controllers/provider_controller.dart';
import 'controllers/mahir_controller.dart';
import 'services/notification_service.dart';
import 'views/auth/splash_view.dart';
import 'views/notifications/notifications_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.initialize();
  runApp(const MihanPlatformApp());
}

class MihanPlatformApp extends StatefulWidget {
  const MihanPlatformApp({super.key});

  @override
  State<MihanPlatformApp> createState() => _MihanPlatformAppState();
}

class _MihanPlatformAppState extends State<MihanPlatformApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();

  void _openInboxIfReady(AuthController auth, bool requested) {
    if (!requested || !auth.isAuthenticated || !auth.isInitialized) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          !NotificationService.openInboxRequested.value ||
          !auth.isAuthenticated) {
        return;
      }
      final navigator = _navigatorKey.currentState;
      if (navigator == null) return;
      NotificationService.openInboxRequested.value = false;
      navigator.push(
          MaterialPageRoute<void>(builder: (_) => const NotificationsView()));
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthController()),
        ChangeNotifierProvider(create: (_) => CustomerController()),
        ChangeNotifierProvider(create: (_) => ProviderController()),
        ChangeNotifierProvider(create: (_) => MahirController()),
      ],
      child: Consumer<AuthController>(
        builder: (context, auth, _) => ValueListenableBuilder<bool>(
          valueListenable: NotificationService.openInboxRequested,
          builder: (context, requested, _) {
            _openInboxIfReady(auth, requested);
            return MaterialApp(
              navigatorKey: _navigatorKey,
              title: 'مِهَن',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              builder: (context, child) {
                return Directionality(
                  textDirection: TextDirection.rtl,
                  child: child ?? const SizedBox.shrink(),
                );
              },
              home: const SplashView(),
            );
          },
        ),
      ),
    );
  }
}
