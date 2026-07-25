import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:maatriva/core/config/app_config.dart';
import 'package:maatriva/core/services/providers.dart';
import 'package:maatriva/main.dart';

void main() {
  testWidgets('App renders successfully smoke test', (
    WidgetTester tester,
  ) async {
    AppConfig.isTesting = true;
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    // Build our app with SharedPreferences provider override.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const MaatrivaApp(),
      ),
    );

    // Verify that the app is pumped without crashing.
    expect(find.byType(MaatrivaApp), findsOneWidget);

    // Flush any pending microtasks or close events scheduled in the event loop.
    await tester.pump(const Duration(milliseconds: 500));
  });
}
