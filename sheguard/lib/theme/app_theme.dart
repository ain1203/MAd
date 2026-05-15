import 'package:flutter/material.dart';

class SafeHerColors {
  // Brand Colors
  static const Color primary = Color(0xFF6A1B9A);
  static const Color primaryLight = Color(0xFF9C4DCC);
  static const Color primaryDark = Color(0xFF38006B);
  
  static const Color accent = Color(0xFFE1BEE7);
  static const Color softPurple = Color(0xFFF3E5F5);
  
  static const Color emergencyRed = Color(0xFFD32F2F);
  static const Color sosPink = Color(0xFFFF4081);
  
  static const Color textDark = Color(0xFF212121);
  static const Color textMuted = Color(0xFF757575);
}

class AppThemes {
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: SafeHerColors.primary,
    scaffoldBackgroundColor: Colors.white,
    colorScheme: const ColorScheme.light(
      primary: SafeHerColors.primary,
      secondary: SafeHerColors.primaryLight,
      surface: Colors.white,
      onSurface: SafeHerColors.textDark,
      error: SafeHerColors.emergencyRed,
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: SafeHerColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: SafeHerColors.primary,
      unselectedItemColor: SafeHerColors.textMuted,
    ),
    textTheme: const TextTheme(
      headlineMedium: TextStyle(color: SafeHerColors.textDark, fontWeight: FontWeight.bold),
      bodyLarge: TextStyle(color: SafeHerColors.textDark),
      bodySmall: TextStyle(color: SafeHerColors.textMuted),
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: SafeHerColors.primary,
    scaffoldBackgroundColor: const Color(0xFF121212),
    colorScheme: const ColorScheme.dark(
      primary: SafeHerColors.primaryLight,
      secondary: SafeHerColors.accent,
      surface: const Color(0xFF1E1E1E),
      onSurface: Colors.white,
      error: SafeHerColors.emergencyRed,
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFF1E1E1E),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1E1E1E),
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF1E1E1E),
      selectedItemColor: SafeHerColors.primaryLight,
      unselectedItemColor: Colors.white54,
    ),
    textTheme: const TextTheme(
      headlineMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      bodyLarge: TextStyle(color: Colors.white70),
      bodySmall: TextStyle(color: Colors.white38),
    ),
  );
}
