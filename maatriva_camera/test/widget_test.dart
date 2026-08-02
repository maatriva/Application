import 'package:flutter_test/flutter_test.dart';
import 'package:maatriva_camera/app.dart';

void main() {
  testWidgets('Smoke test - Splash screen loads', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MaatrivaCameraApp());

    // Verify that our brand label starts on screen.
    expect(find.text('MAATRIVA'), findsOneWidget);
  });
}
