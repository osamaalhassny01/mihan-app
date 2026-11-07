import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mihan_app/main.dart';

void main() {
  testWidgets('MihanPlatformApp smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MihanPlatformApp());

    // Verify platform brand text is displayed on launch
    expect(find.text('مِهَن للخدمات الفنية'), findsOneWidget);
  });
}
