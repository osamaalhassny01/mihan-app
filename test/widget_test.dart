import 'package:flutter_test/flutter_test.dart';
import 'package:mihan_app/main.dart';

void main() {
  testWidgets('MihanPlatformApp smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MihanPlatformApp());

    // Verify platform brand text is displayed on launch
    expect(find.text('منصة مِهَن للخدمات الفنية'), findsOneWidget);
  });
}
