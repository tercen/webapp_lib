import 'package:flutter/material.dart';

class Styles {
  TextStyle get labelStyle => const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
      );

    TextStyle get titleStyle => const TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.bold,
      );

      TextStyle get footerTextStyle => const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: Color.fromARGB(255, 150, 150, 150)
      );

  TextStyle get appHeader => const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
      );

  ButtonStyle get buttonStyle => const ButtonStyle(
        backgroundColor: WidgetStatePropertyAll<Color>(Colors.purple),
        foregroundColor: WidgetStatePropertyAll<Color>(Colors.white),
        textStyle: WidgetStatePropertyAll<TextStyle>(TextStyle(fontSize: 20, fontWeight: FontWeight.w500)),
      );

}