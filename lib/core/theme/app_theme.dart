import 'package:flutter/cupertino.dart';

class AppTheme {
  AppTheme._();

  // Dark Monochrome Colors (Default)
  static const Color darkBackground = Color(0xFF000000);
  static const Color darkSurface = Color(0xFF121214);
  static const Color darkSurfaceSecondary = Color(0xFF1C1C1E);
  static const Color darkSurfaceElevated = Color(0xFF242426);
  static const Color darkBorder = Color(0xFF2C2C2E);
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFF8E8E93);
  static const Color darkTextTertiary = Color(0xFF636366);

  // Light Monochrome Colors
  static const Color lightBackground = Color(0xFFF2F2F7);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceSecondary = Color(0xFFE5E5EA);
  static const Color lightBorder = Color(0xFFD1D1D6);
  static const Color lightTextPrimary = Color(0xFF000000);
  static const Color lightTextSecondary = Color(0xFF8E8E93);

  // Accent Colors for Grades (Subtle & Elegant)
  static const Color grade5Color = Color(0xFF34C759); // Apple Green
  static const Color grade4Color = Color(0xFF30B0C7); // Cyan
  static const Color grade3Color = Color(0xFFFF9F0A); // Warm Orange
  static const Color grade2Color = Color(0xFFFF453A); // Coral Red
  static const Color mosRedAccent = Color(0xFFE31E24); // Mos ID Red

  static CupertinoThemeData getCupertinoTheme({required bool isDark}) {
    return CupertinoThemeData(
      brightness: isDark ? Brightness.dark : Brightness.light,
      primaryColor: isDark ? const Color(0xFFFFFFFF) : const Color(0xFF000000),
      barBackgroundColor: isDark
          ? const Color(0xCC121214)
          : const Color(0xCCFFFFFF),
      scaffoldBackgroundColor:
          isDark ? darkBackground : lightBackground,
      textTheme: CupertinoTextThemeData(
        primaryColor: isDark ? darkTextPrimary : lightTextPrimary,
        textStyle: TextStyle(
          color: isDark ? darkTextPrimary : lightTextPrimary,
          fontSize: 16,
          letterSpacing: -0.2,
        ),
      ),
    );
  }

  static Color getGradeColor(int grade) {
    switch (grade) {
      case 5:
        return grade5Color;
      case 4:
        return grade4Color;
      case 3:
        return grade3Color;
      case 2:
      default:
        return grade2Color;
    }
  }
}
