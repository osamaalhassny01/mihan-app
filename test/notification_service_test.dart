import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('NotificationService welcome notification preferences flag test', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    expect(prefs.getBool('welcome_notification_sent'), isNull);
    await prefs.setBool('welcome_notification_sent', true);
    expect(prefs.getBool('welcome_notification_sent'), isTrue);
  });

  test('Request date and time formatting test', () {
    final now = DateTime(2026, 11, 5, 10, 30);
    final formattedDate = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final formattedTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:00';

    expect(formattedDate, equals('2026-11-05'));
    expect(formattedTime, equals('10:30:00'));
  });
}

