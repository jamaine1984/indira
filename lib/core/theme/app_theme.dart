import 'package:flutter/material.dart';

class AppTheme {
  // Color Palette — vibrant South Asian inspired
  static const Color primaryRose = Color(0xFFE91E63);
  static const Color secondaryPlum = Color(0xFF7B1FA2);
  static const Color accentGold = Color(0xFFFFD700);
  static const Color neutralWhite = Color(0xFFFFF8E1);
  static const Color textCharcoal = Color(0xFF1A1A2E);
  static const Color shadowSoft = Color(0x207B1FA2);

  static const LinearGradient romanticGradient = LinearGradient(
    colors: [primaryRose, Color(0xFFFF6090), accentGold, secondaryPlum],
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

      // Text Theme — bolder weights throughout
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontFamily: 'PlayfairDisplay',
          fontSize: 32,
          fontWeight: FontWeight.w900,
          color: textCharcoal,
        ),
        displayMedium: TextStyle(
          fontFamily: 'PlayfairDisplay',
          fontSize: 28,
          fontWeight: FontWeight.w800,
          color: textCharcoal,
        ),
        headlineLarge: TextStyle(
          fontFamily: 'PlayfairDisplay',
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: textCharcoal,
        ),
        headlineMedium: TextStyle(
          fontFamily: 'PlayfairDisplay',
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: textCharcoal,
        ),
        titleLarge: TextStyle(
          fontFamily: 'Inter',
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: textCharcoal,
        ),
        bodyLarge: TextStyle(
          fontFamily: 'Inter',
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: textCharcoal,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: textCharcoal,
        ),
        labelLarge: TextStyle(
          fontFamily: 'DancingScript',
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: secondaryPlum,
        ),
      ),

      // Icon Theme — bolder icons
      iconTheme: const IconThemeData(
        size: 26,
        color: textCharcoal,
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
            fontWeight: FontWeight.w700,
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
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        elevation: 4,
        shadowColor: shadowSoft,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: Colors.white,
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),

      // SnackBar Theme
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentTextStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        elevation: 6,
      ),

      // Dialog Theme
      dialogTheme: DialogThemeData(
        backgroundColor: neutralWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        titleTextStyle: const TextStyle(
          fontFamily: 'PlayfairDisplay',
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: textCharcoal,
        ),
        contentTextStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          color: textCharcoal,
        ),
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: accentGold,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        labelStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: textCharcoal,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),

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
