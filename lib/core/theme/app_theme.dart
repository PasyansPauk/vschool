import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

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

  static ThemeData getMaterialTheme({required bool isDark}) {
    final bg = isDark ? darkBackground : lightBackground;
    final surface = isDark ? darkSurface : lightSurface;
    final textPrimary = isDark ? darkTextPrimary : lightTextPrimary;
    final textSecondary = isDark ? darkTextSecondary : lightTextSecondary;
    final border = isDark ? darkBorder : lightBorder;

    final colorScheme = isDark
        ? const ColorScheme.dark(
            primary: Color(0xFF38BDF8),
            onPrimary: Color(0xFF000000),
            secondary: Color(0xFF0A84FF),
            surface: Color(0xFF121214),
            onSurface: Color(0xFFFFFFFF),
            outline: Color(0xFF2C2C2E),
          )
        : const ColorScheme.light(
            primary: Color(0xFF0284C7),
            onPrimary: Color(0xFFFFFFFF),
            secondary: Color(0xFF0A84FF),
            surface: Color(0xFFFFFFFF),
            onSurface: Color(0xFF000000),
            outline: Color(0xFFD1D1D6),
          );

    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: bg,
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isDark ? const Color(0xFF121214) : const Color(0xFFFFFFFF),
        elevation: 8,
        indicatorColor: isDark ? const Color(0x3338BDF8) : const Color(0x220284C7),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
            );
          }
          return TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: textSecondary,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(
              color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
              size: 24,
            );
          }
          return IconThemeData(
            color: textSecondary,
            size: 24,
          );
        }),
      ),
      dividerTheme: DividerThemeData(
        color: border,
        thickness: 1,
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
