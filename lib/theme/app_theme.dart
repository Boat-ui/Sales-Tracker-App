import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTheme {
  static const navy       = Color(0xFF0D1F2D);
  static const navyLight  = Color(0xFF162A3A);
  static const navyCard   = Color(0xFF1A3244);
  static const teal       = Color(0xFF1D9E75);
  static const tealLight  = Color(0xFF5DCAA5);
  static const tealFaint  = Color(0x181D9E75);
  static const tealBorder = Color(0x401D9E75);
  static const white      = Color(0xFFFFFFFF);
  static const textPrimary   = Color(0xFFEEF2F5);
  static const textSecondary = Color(0xFF8BA4B5);
  static const textMuted     = Color(0xFF4A6478);

  static const profit  = Color(0xFF1D9E75);
  static const revenue = Color(0xFF3B8EE8);
  static const biz     = Color(0xFF9B7FE8);
  static const savings = Color(0xFF5DCAA5);
  static const spend   = Color(0xFFE87B5A);
  static const warning = Color(0xFFE8A83B);
  static const danger  = Color(0xFFE85A5A);

  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: navy,
    colorScheme: const ColorScheme.dark(
      primary: teal,
      secondary: tealLight,
      surface: navyLight,
      onPrimary: white,
      onSurface: textPrimary,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: navy,
      foregroundColor: textPrimary,
      elevation: 0,
      centerTitle: false,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      titleTextStyle: TextStyle(
        color: textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: navyLight,
      indicatorColor: Color(0x181D9E75),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: teal);
        }
        return const IconThemeData(color: textMuted);
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const TextStyle(color: teal, fontSize: 11, fontWeight: FontWeight.w600);
        }
        return const TextStyle(color: textMuted, fontSize: 11);
      }),
    ),
    cardTheme: CardThemeData(
      color: navyCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF1D3A4F), width: 0.5),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: teal,
      foregroundColor: white,
      elevation: 0,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: teal,
        foregroundColor: white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: navyLight,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF1D3A4F)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF1D3A4F)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: teal, width: 1.5),
      ),
      labelStyle: const TextStyle(color: textSecondary),
      hintStyle: const TextStyle(color: textMuted),
      prefixIconColor: teal,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: navyLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0xFF1D3A4F),
      thickness: 0.5,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: navyCard,
      contentTextStyle: const TextStyle(color: textPrimary),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      behavior: SnackBarBehavior.floating,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: navyLight,
      selectedColor: const Color(0x181D9E75),
      labelStyle: const TextStyle(color: textPrimary),
      side: const BorderSide(color: Color(0xFF1D3A4F), width: 0.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: navyCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titleTextStyle: const TextStyle(
          color: textPrimary, fontSize: 17, fontWeight: FontWeight.w600),
      contentTextStyle: const TextStyle(color: textSecondary, fontSize: 14),
    ),
    sliderTheme: const SliderThemeData(
      activeTrackColor: teal,
      inactiveTrackColor: Color(0xFF1D3A4F),
      thumbColor: teal,
      overlayColor: Color(0x181D9E75),
    ),
  );
}