import 'package:flutter/material.dart';

class ThemeModel {
  // Define custom colors for light and dark modes
  static Map<String, dynamic> get lightThemeColors => {
    "primaryColor": Colors.blue,

    "appBarColor": Colors.blue,
    "buttonColor": Colors.blue,
    "lockScaffoldBackgroundColor": [
      Colors.teal.shade900,
      Colors.tealAccent.shade400
    ],
    "lockTextColor": Colors.white,
    "lockButtonColor": Colors.white,
    "lockButtonSplashColor": Colors.teal,
    "lockButtonTextColor": Colors.teal,
    "textColor": Colors.black,
  };

  static Map<String, dynamic> get darkThemeColors => {
    "primaryColor": Colors.teal,
    "scaffoldBackgroundColor": Colors.black,
    "appBarColor": Colors.teal,
    "buttonColor": Colors.teal,
    "lockScaffoldBackgroundColor": [
      Colors.teal.shade600,
      Colors.teal.shade900
    ],
    "lockTextColor": Colors.black,
    "lockButtonColor": Colors.black,
    "lockButtonSplashColor": Colors.teal,
    "lockButtonTextColor": Colors.teal.shade200,
    "textColor": Colors.white,
  };


  static Color getThemeColors(String theme, String key) {
    return theme == "dark" ? darkThemeColors[key]  : lightThemeColors[key];
  }
  static List<Color> getListThemeColors(String theme, String key) {
    return theme == "dark" ? darkThemeColors[key]  : lightThemeColors[key];
  }
}
