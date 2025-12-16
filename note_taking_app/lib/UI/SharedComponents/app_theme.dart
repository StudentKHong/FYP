// To support changing between dark and light themes through settings.
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppTheme {
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primarySwatch: Colors.blue,
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.blue,
      foregroundColor: Colors.white,
    ),
    cardColor: Colors.white,
    dividerColor: Colors.grey,
    textTheme: const TextTheme(
      titleMedium: TextStyle(color: Colors.black, fontSize: 18),
      bodyMedium: TextStyle(color: Colors.black87, fontSize: 16),
      bodyLarge: TextStyle(color: Colors.black, fontSize: 18),
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primarySwatch: Colors.blue,
    scaffoldBackgroundColor: Colors.black,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.blueGrey,
      foregroundColor: Colors.white,
    ),
    cardColor: Colors.grey[900],
    dividerColor: Colors.grey[700],
    textTheme: const TextTheme(
      titleMedium: TextStyle(color: Colors.white, fontSize: 18),
      bodyMedium: TextStyle(color: Colors.white70, fontSize: 16),
      bodyLarge: TextStyle(color: Colors.white, fontSize: 18),
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
