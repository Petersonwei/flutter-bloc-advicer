import 'package:advicer/2_application/core/services/theme_service.dart';
import 'package:advicer/2_application/pages/advicer/advicer_page.dart';
import 'package:advicer/theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeService(),
      child: const AdvicerApp(),
    ),
  );
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
