import 'package:flutter/material.dart';

class AppTheme {
  // Color Palette
  static const Color primaryRose = Color(0xFFFFB6C1);
  static const Color secondaryPlum = Color(0xFF8B4789);
  static const Color accentGold = Color(0xFFF7E7CE);
  static const Color neutralWhite = Color(0xFFFFF8F0);
  static const Color textCharcoal = Color(0xFF2F2F2F);
  static const Color shadowSoft = Color(0x108B4789);

  static const LinearGradient romanticGradient = LinearGradient(
    colors: [primaryRose, accentGold, secondaryPlum],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Inter',
      primaryColor: primaryRose,
      scaffoldBackgroundColor: neutralWhite,

      // Color Scheme
      colorScheme: const ColorScheme.light(
        primary: primaryRose,
        secondary: secondaryPlum,
        tertiary: accentGold,
        surface: neutralWhite,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textCharcoal,
        onSurfaceVariant: textCharcoal,
      ),

      // Text Theme
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontFamily: 'PlayfairDisplay',
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: textCharcoal,
        ),
        displayMedium: TextStyle(
          fontFamily: 'PlayfairDisplay',
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: textCharcoal,
        ),
        headlineLarge: TextStyle(
          fontFamily: 'PlayfairDisplay',
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: textCharcoal,
        ),
        headlineMedium: TextStyle(
          fontFamily: 'PlayfairDisplay',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textCharcoal,
        ),
        titleLarge: TextStyle(
          fontFamily: 'Inter',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textCharcoal,
        ),
        bodyLarge: TextStyle(
          fontFamily: 'Inter',
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: textCharcoal,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: textCharcoal,
        ),
        labelLarge: TextStyle(
          fontFamily: 'DancingScript',
          fontSize: 16,
          color: secondaryPlum,
        ),
      ),

      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: accentGold),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: accentGold),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryRose, width: 2),
        ),
        labelStyle: const TextStyle(color: secondaryPlum),
        hintStyle: TextStyle(color: textCharcoal.withOpacity(0.6)),
        // Ensure text is visible
        prefixIconColor: secondaryPlum,
        suffixIconColor: secondaryPlum,
      ),

      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryRose,
          foregroundColor: Colors.white,
          elevation: 8,
          shadowColor: shadowSoft,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: accentGold, width: 2),
          foregroundColor: secondaryPlum,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Card Theme
      cardTheme: const CardThemeData(),

      // AppBar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: neutralWhite,
        foregroundColor: textCharcoal,
        elevation: 2,
        shadowColor: shadowSoft,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: 'PlayfairDisplay',
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: textCharcoal,
        ),
      ),

      // Bottom Navigation Bar
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: neutralWhite,
        selectedItemColor: primaryRose,
        unselectedItemColor: secondaryPlum,
        elevation: 8,
        showSelectedLabels: true,
        showUnselectedLabels: true,
      ),
    );
  }

  static ThemeData get darkTheme {
    return lightTheme.copyWith(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: textCharcoal,
      colorScheme: const ColorScheme.dark(
        primary: primaryRose,
        secondary: secondaryPlum,
        tertiary: accentGold,
        surface: textCharcoal,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: neutralWhite,
      ),
    );
  }
}
