import 'dart:io';

import 'package:advicer/2_application/core/services/theme_service.dart';
import 'package:advicer/2_application/pages/advicer/advicer_page.dart';
import 'package:advicer/injection.dart' as di;
import 'package:advicer/theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// DEBUG-ONLY TLS BYPASS SNIPPET (commented out on purpose):
//
// Use this only when the API certificate is invalid/expired and you need
// to continue local testing on simulator/device.
//
// 1) Uncomment the imports below:
// import 'dart:io';
// import 'package:flutter/foundation.dart';
//
// 2) Uncomment the block in main():
// if (kDebugMode) {
//   HttpOverrides.global = DevHttpOverrides();
// }
//
// 3) Uncomment the class below:
// class DevHttpOverrides extends HttpOverrides {
//   @override
//   HttpClient createHttpClient(SecurityContext? context) {
//     final client = super.createHttpClient(context);
//     client.badCertificateCallback = (cert, host, port) {
//       return host == 'api.flutter-community.de' ||
//           host == 'api.flutter-community.com';
//     };
//     return client;
//   }
// }
//
// IMPORTANT: Never ship this in production/App Store builds.

void main() async {
  if (kDebugMode) {
    HttpOverrides.global = DevHttpOverrides();
  }
  WidgetsFlutterBinding.ensureInitialized();
  await di.init();

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeService(),
      child: const AdvicerApp(),
    ),
  );
}

// DEBUG-ONLY TLS BYPASS
class DevHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    client.badCertificateCallback = (cert, host, port) {
      return host == 'api.flutter-community.de' ||
          host == 'api.flutter-community.com';
    };
    return client;
  }
}

class AdvicerApp extends StatelessWidget {
  const AdvicerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) => MaterialApp(
        title: 'Advicer',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeService.currentThemeMode,
        home: const AdvicerPageWrapperProvider(),
      ),
    );
  }
}
