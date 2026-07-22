import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maatriva/main.dart';

void main() {
  testWidgets('App renders successfully smoke test', (
    WidgetTester tester,
  ) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: MaatrivaApp()));

    // Verify that the app is pumped without crashing.
    expect(find.byType(MaatrivaApp), findsOneWidget);
  });
}
