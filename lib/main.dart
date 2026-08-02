   import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/config/api_config.dart';
import 'core/services/providers.dart';
import 'core/theme/app_theme.dart';
import 'routes/app_routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  
  final savedCustomUrl = prefs.getString('custom_base_url');
  if (savedCustomUrl != null && savedCustomUrl.isNotEmpty) {
    ApiConfig.setCustomBaseUrl(savedCustomUrl);
  }
  
  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const MaatrivaApp(),
    ),
  );
}

class MaatrivaApp extends ConsumerWidget {
  const MaatrivaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);
    return ScreenUtilInit(
      designSize: const Size(
        390,
        844,
      ), // standard design size matching typical modern mobile device dimensions
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp.router(
          title: 'Maatriva Smart Baby Monitor',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          routerConfig: router,
          scaffoldMessengerKey: scaffoldMessengerKey,
        );
      },
    );
  }
}
