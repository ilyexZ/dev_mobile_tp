import 'package:flutter/material.dart';

class AppStyles {
  // Colors
  static const primaryColor = Color.fromARGB(255, 63, 63, 63);
  static const accentColor = Colors.orange;
  static const textColor = Color.fromARGB(221, 255, 255, 255);
  static const primaryIconColor = Colors.white;
  static const appBarBackgroundColor= Colors.black26;

  // Text Styles
  static const appBarTitleStyle = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w900,
    color: textColor,
  );

  static const songTitle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w900,
    color: textColor,
  );

  static const songArtist = TextStyle(fontSize: 16, color: textColor);

  // Image dimensions
  static const coverSize = 320.0;

  // Icon size
  static const controlIconSize = 64.0;
}
