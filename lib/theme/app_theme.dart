import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTheme {
  // ── Core palette — matches BizSplit splash screen ──────
  static const navy       = Color(0xFF001489); // deep royal blue background
  static const navyLight  = Color(0xFF0020B8); // slightly lighter blue for nav/sheets
  static const navyCard   = Color(0xFF002ACC); // card surfaces
  static const blue       = Color(0xFF4D9FFF); // bright sky blue accent
  static const blueLight  = Color(0xFF80BFFF); // lighter blue highlight
  static const blueFaint  = Color(0x1A4D9FFF); // faint blue tint
  static const blueBorder = Color(0x404D9FFF); // blue border
  static const white      = Color(0xFFFFFFFF);
  static const textPrimary   = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFFB3CCFF); // soft blue-white
  static const textMuted     = Color(0xFF6688CC); // muted blue-grey

  // ── Aliases — keeps existing code working ──────────────
  static const teal       = blue;
  static const tealLight  = blueLight;
  static const tealFaint  = blueFaint;
  static const tealBorder = blueBorder;

  static const profit  = Color(0xFF00E5A0); // bright teal green
  static const revenue = Color(0xFF4D9FFF); // sky blue
  static const biz     = Color(0xFFAA80FF); // purple
  static const savings = Color(0xFF00CCCC); // cyan
  static const spend   = Color(0xFFFF9966); // orange
  static const warning = Color(0xFFFFCC44); // yellow
  static const danger  = Color(0xFFFF5566); // red

  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: navy,
    colorScheme: const ColorScheme.dark(
      primary: blue,
      secondary: blueLight,
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
      indicatorColor: const Color(0x1A4D9FFF),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: blue);
        }
        return const IconThemeData(color: textMuted);
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const TextStyle(color: blue, fontSize: 11, fontWeight: FontWeight.w600);
        }
        return const TextStyle(color: textMuted, fontSize: 11);
      }),
    ),
    cardTheme: CardThemeData(
      color: navyCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF0040DD), width: 0.5),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: blue,
      foregroundColor: white,
      elevation: 0,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: blue,
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
        borderSide: const BorderSide(color: Color(0xFF0040DD)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF0040DD)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: blue, width: 1.5),
      ),
      labelStyle: const TextStyle(color: textSecondary),
      hintStyle: const TextStyle(color: textMuted),
      prefixIconColor: blue,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: navyLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0xFF0040DD),
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
      selectedColor: const Color(0x1A4D9FFF),
      labelStyle: const TextStyle(color: textPrimary),
      side: const BorderSide(color: Color(0xFF0040DD), width: 0.5),
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
      activeTrackColor: blue,
      inactiveTrackColor: Color(0xFF0040DD),
      thumbColor: blue,
      overlayColor: Color(0x1A4D9FFF),
    ),
  );
}