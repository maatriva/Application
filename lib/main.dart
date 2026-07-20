import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'theme/app_theme.dart';
import 'routes.dart';

void main() {
  runApp(
    const ProviderScope(
      child: MaatrivaApp(),
    ),
  );
}

class MaatrivaApp extends StatelessWidget {
  const MaatrivaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(390, 844), // standard design size matching typical modern mobile device dimensions
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp.router(
          title: 'Maatriva Smart Baby Monitor',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          routerConfig: goRouter,
        );
      },
    );
  }
}
