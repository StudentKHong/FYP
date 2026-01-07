// ==================================================
// Program Name   : app_theme.dart
// Purpose        : Central theme and styling used across the app
// Developer      : Mr. Ng Kuok Hong 
// Student ID     : TP069007
// Course         : Bachelor of Software Engineering (Hons) 
// Created Date   : 16 December 2025
// Last Modified  : 24 December 2025
// ==================================================

// To support changing between dark and light themes through settings.
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppTheme {
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      brightness: Brightness.light,
      seedColor: Colors.lightBlue,
    ).copyWith(onPrimary: Colors.black),
    scaffoldBackgroundColor: Color(0xFFF4F5F7),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.blue,
      foregroundColor: Colors.black,
      titleTextStyle: GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    ),
    cardTheme: CardThemeData(
      surfaceTintColor: Colors.transparent,
      color: Colors.white,
      elevation: 2,
      margin: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      prefixIconColor: Colors.black,
      suffixIconColor: Colors.black,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
    ),
    dividerColor: Colors.grey[700],
    textTheme: GoogleFonts.interTextTheme().apply(
      bodyColor: Colors.black,
      displayColor: Colors.black,
    ),
    datePickerTheme: DatePickerThemeData(
      backgroundColor: Colors.white,
      headerBackgroundColor: Colors.grey,
      headerForegroundColor: Colors.black,
      headerHelpStyle: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
      headerHeadlineStyle: GoogleFonts.inter(fontSize: 16, color: Colors.black),
      dayStyle: GoogleFonts.inter(fontSize: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.lightBlue,
        foregroundColor: Colors.white,
        elevation: 2,
        textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    ),
    iconTheme: IconThemeData(color: Colors.black),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return Colors.blue;
        return Colors.grey;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return Colors.blue.withAlpha(50);
        }
        return Colors.grey.withAlpha(50);
      }),
      trackOutlineColor: WidgetStatePropertyAll(Colors.grey.shade700),
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      brightness: Brightness.dark,
      seedColor: Colors.lightBlue.shade700,
    ).copyWith(onPrimary: Colors.white),
    scaffoldBackgroundColor: Colors.black,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.blue,
      foregroundColor: Colors.black,
      titleTextStyle: GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    ),
    cardTheme: CardThemeData(
      surfaceTintColor: Colors.transparent,
      color: Colors.white,
      elevation: 2,
      margin: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      prefixIconColor: Colors.black,
      suffixIconColor: Colors.black,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
    ),
    dividerColor: Colors.grey[700],
    textTheme: GoogleFonts.interTextTheme().apply(
      bodyColor: Colors.white,
      displayColor: Colors.white,
    ),
    datePickerTheme: DatePickerThemeData(
      backgroundColor: Colors.black,
      headerBackgroundColor: Colors.black,
      headerForegroundColor: Colors.white,
      headerHelpStyle: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
      headerHeadlineStyle: GoogleFonts.inter(fontSize: 16, color: Colors.white),
      dayStyle: GoogleFonts.inter(fontSize: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.lightBlue,
        foregroundColor: Colors.white,
        elevation: 2,
        textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    ),
    iconTheme: IconThemeData(color: Colors.black),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return Colors.lightBlue;
        return Colors.grey.shade300;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return Colors.lightBlue.withAlpha(50);
        }
        return Colors.grey.shade700;
      }),
      trackOutlineColor: WidgetStatePropertyAll(Colors.grey.shade700),
    ),
  );

  static Color getOptimalTextColor(Color backgroundColor) {
    final brightness = ThemeData.estimateBrightnessForColor(backgroundColor);
    return brightness == Brightness.dark ? Colors.white : Colors.black;
  }
}

class ThemeController extends GetxController {
  ThemeMode theme = ThemeMode.light;

  Future<void> loadLocalTheme() async {
    final preference = await SharedPreferences.getInstance();
    bool? isDarkMode = preference.getBool('isDarkMode');
    if (isDarkMode != null) {
      theme = isDarkMode ? ThemeMode.dark : ThemeMode.light;
      Get.changeThemeMode(theme);
    }
  }

  Future<void> updateTheme(bool isDarkMode) async {
    Get.changeThemeMode(isDarkMode ? ThemeMode.dark : ThemeMode.light);
    final preference = await SharedPreferences.getInstance();
    await preference.setBool('isDarkMode', isDarkMode);
  }
}
