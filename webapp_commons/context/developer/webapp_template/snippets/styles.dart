import 'package:flutter/material.dart';

class Styles {

  static double get minNavigationSz => 0.08;
  static double get maxNavigationSz => 0.10;
  static double get maxFooterHeight => 0.06;

  static Color get activeBackgroundColor => Colors.purple;
  static Color get activeForegroundColor => Colors.white;
  static Color get appBackgroundColor => Colors.white;
  static Color get appForegroundColor => Colors.black87;
  static Color get inactiveBackground => Color.fromARGB(255, 200, 200, 200);
  static Color get inactiveForeground => Color.fromARGB(255, 130, 130, 130);

  static TextStyle get labelStyle => TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Styles.appForegroundColor
      );

  static TextStyle get titleStyle =>  TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.bold,
        color: Styles.appForegroundColor
      );

  static TextStyle get footerTextStyle => TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: Styles.inactiveForeground
      );

  static TextStyle get appHeader => const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
      );

  static ButtonStyle get buttonStyle => ButtonStyle(
        backgroundColor: WidgetStatePropertyAll<Color>(Styles.activeBackgroundColor),
        foregroundColor: WidgetStatePropertyAll<Color>(Styles.activeForegroundColor),
        textStyle: const WidgetStatePropertyAll<TextStyle>(TextStyle(fontSize: 20, fontWeight: FontWeight.w500)),
      );

}