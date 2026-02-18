import 'package:flutter/material.dart';

/// Elderly-friendly theme with large text, high contrast, and rounded elements.
class AmavelTheme {
  AmavelTheme._();

  // Brand colors
  static const Color primaryColor = Color(0xFF2E7D6B); // Warm teal-green
  static const Color primaryLight = Color(0xFF4DB8A4);
  static const Color primaryDark = Color(0xFF1B5E4D);
  static const Color accentColor = Color(0xFFF4A261); // Warm orange
  static const Color errorColor = Color(0xFFE63946);
  static const Color backgroundColor = Color(0xFFF8F6F0); // Warm off-white
  static const Color surfaceColor = Colors.white;
  static const Color textPrimary = Color(0xFF1D1D1D);
  static const Color textSecondary = Color(0xFF5A5A5A);
  static const Color textOnPrimary = Colors.white;

  // Orb colors
  static const Color orbIdle = Color(0xFF4DB8A4);
  static const Color orbListening = Color(0xFF2E7D6B);
  static const Color orbThinking = Color(0xFFF4A261);
  static const Color orbSpeaking = Color(0xFF5BC0EB);
  static const Color orbError = Color(0xFFE63946);

  // Minimum text sizes for elderly readability
  static const double textSizeSmall = 18.0;
  static const double textSizeBody = 22.0;
  static const double textSizeLarge = 28.0;
  static const double textSizeTitle = 34.0;
  static const double textSizeHeadline = 42.0;

  // Minimum touch target sizes
  static const double minTouchTarget = 56.0;
  static const double buttonHeight = 64.0;
  static const double iconSize = 32.0;
  static const double navIconSize = 36.0;

  // Border radius
  static const double borderRadius = 16.0;
  static const double borderRadiusLarge = 24.0;

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        onPrimary: textOnPrimary,
        secondary: accentColor,
        surface: surfaceColor,
        error: errorColor,
      ),
      scaffoldBackgroundColor: backgroundColor,

      // Large, readable text
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: textSizeHeadline,
          fontWeight: FontWeight.bold,
          color: textPrimary,
          height: 1.3,
        ),
        headlineMedium: TextStyle(
          fontSize: textSizeTitle,
          fontWeight: FontWeight.bold,
          color: textPrimary,
          height: 1.3,
        ),
        titleLarge: TextStyle(
          fontSize: textSizeLarge,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          height: 1.3,
        ),
        bodyLarge: TextStyle(
          fontSize: textSizeBody,
          fontWeight: FontWeight.normal,
          color: textPrimary,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          fontSize: textSizeBody,
          fontWeight: FontWeight.normal,
          color: textSecondary,
          height: 1.5,
        ),
        labelLarge: TextStyle(
          fontSize: textSizeBody,
          fontWeight: FontWeight.w600,
          color: textOnPrimary,
        ),
      ),

      // Large, rounded buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: textOnPrimary,
          minimumSize: const Size(double.infinity, buttonHeight),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadiusLarge),
          ),
          textStyle: const TextStyle(
            fontSize: textSizeBody,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Large app bar
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: textOnPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: textSizeLarge,
          fontWeight: FontWeight.bold,
          color: textOnPrimary,
        ),
        toolbarHeight: 72,
      ),

      // Bottom navigation
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceColor,
        selectedItemColor: primaryColor,
        unselectedItemColor: textSecondary,
        selectedLabelStyle: TextStyle(fontSize: textSizeSmall, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: textSizeSmall),
        type: BottomNavigationBarType.fixed,
        selectedIconTheme: IconThemeData(size: navIconSize),
        unselectedIconTheme: IconThemeData(size: navIconSize),
      ),

      // Card theme
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),

      // Icon theme
      iconTheme: const IconThemeData(
        size: iconSize,
        color: textPrimary,
      ),
    );
  }
}
