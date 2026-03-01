import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static const Color lightPrimaryColor = Color(0xFFF7F7F8);
  static const Color lightSecondaryColor = Color(0xFFFFFFFF);
  static const Color lightAccentColor = Color(0xFF2D3142);

  static const Color darkPrimaryColor = Color(0xFF1B1D26);
  static const Color darkSecondaryColor = Color(0xFF2A2D3A);
  static const Color darkAccentColor = Color(0xFFF2F2F2);

  static const Color iconColor = Color(0xFFFFB703);
  static const Color actionColor = Color(0xFFFB8500);

  static const TextStyle lightHeadingText = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: lightAccentColor,
  );

  static const TextStyle lightBodyText = TextStyle(
    fontSize: 16,
    color: lightAccentColor,
  );

  static TextStyle get darkHeadingText =>
      lightHeadingText.copyWith(color: darkAccentColor);
  static TextStyle get darkBodyText =>
      lightBodyText.copyWith(color: darkAccentColor);

  static TextTheme get lightTextTheme => const TextTheme(
        headlineMedium: lightHeadingText,
        bodyMedium: lightBodyText,
      );

  static TextTheme get darkTextTheme => TextTheme(
        headlineMedium: darkHeadingText,
        bodyMedium: darkBodyText,
      );

  static ThemeData get lightTheme => ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: lightPrimaryColor,
        colorScheme: const ColorScheme.light(
          primary: lightSecondaryColor,
          secondary: actionColor,
          onPrimary: lightAccentColor,
          onSecondary: lightAccentColor,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: lightSecondaryColor,
          foregroundColor: lightAccentColor,
          elevation: 0,
        ),
        textTheme: lightTextTheme,
      );

  static ThemeData get darkTheme => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: darkPrimaryColor,
        colorScheme: const ColorScheme.dark(
          primary: darkSecondaryColor,
          secondary: actionColor,
          onPrimary: darkAccentColor,
          onSecondary: darkAccentColor,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: darkSecondaryColor,
          foregroundColor: darkAccentColor,
          elevation: 0,
        ),
        textTheme: darkTextTheme,
      );
}
