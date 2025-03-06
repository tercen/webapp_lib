import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:webapp_ui_commons/styles/style_base.dart';

class DefaultStyle extends StyleBase {
  @override
  void init() {
    styleMap["black"] = Color.fromARGB(255, 26, 26, 41);
    styleMap["lightBlack"] = Colors.black26;
    styleMap["gray"] = Color.fromARGB(255, 180, 180, 190);
    styleMap["darkGray"] = Color.fromARGB(255, 120, 120, 130);
    styleMap["white"] = Color.fromARGB(255, 240, 240, 230);
    styleMap["linkBlue"] = Color.fromARGB(255, 55, 22, 163);
    styleMap["red"] = Color.fromARGB(255, 255, 37, 37);

    styleMap["selectedBg"] = Color.fromARGB(255, 101, 155, 255);
    styleMap["selectedMenuBg"] = Color.fromARGB(255, 51, 65, 85);
    styleMap["selectedMenuFg"] = Color.fromARGB(255, 240, 240, 230);
    styleMap["hoverBg"] = Color.fromARGB(100, 175, 172, 221);
    styleMap["tooltipBg"] = Color.fromARGB(199, 14, 11, 62);

    styleMap["headerRow"] = Color.fromARGB(30, 80, 200, 255);
    styleMap["evenRow"] = Color.fromARGB(30, 255, 255, 255);
    styleMap["oddRow"] = Color.fromARGB(30, 120, 240, 255);

    styleMap["borderRounding"] = BorderRadius.circular(8.0);
    styleMap["textH1"] = TextStyle(
        fontSize: 20,
        color: styleMap["black"],
        fontWeight: FontWeight.bold,
        decoration: TextDecoration.none);

    styleMap["textH2"] = TextStyle(
        fontSize: 18,
        color: styleMap["black"],
        fontWeight: FontWeight.w600,
        decoration: TextDecoration.none);

    styleMap["menuText"] = TextStyle(
        fontSize: 18,
        color: styleMap["black"],
        fontWeight: FontWeight.w600,
        decoration: TextDecoration.none);

    styleMap["menuTextSelected"] = TextStyle(
        fontSize: 18,
        color: styleMap["white"],
        fontWeight: FontWeight.w600,
        decoration: TextDecoration.none);
    styleMap["menuTextDisabled"] = TextStyle(
        fontSize: 18,
        color: styleMap["gray"],
        fontWeight: FontWeight.w600,
        decoration: TextDecoration.none);
    styleMap["text"] = TextStyle(
        fontSize: 16,
        color: styleMap["black"],
        fontWeight: FontWeight.w400,
        decoration: TextDecoration.none);
    styleMap["textGray"] = TextStyle(
        fontSize: 16,
        color: styleMap["darkGray"],
        fontWeight: FontWeight.normal,
        decoration: TextDecoration.none);
    styleMap["textTooltip"] = TextStyle(
        fontSize: 16,
        color: styleMap["white"],
        fontWeight: FontWeight.normal,
        decoration: TextDecoration.none);

    styleMap["textFile"] = TextStyle(
        fontSize: 14,
        fontFamily: "RobotMono",
        color: styleMap["black"],
        decoration: TextDecoration.none);
    styleMap["textBold"] = TextStyle(
        fontSize: 16,
        color: styleMap["black"],
        fontWeight: FontWeight.bold,
        decoration: TextDecoration.none);
    styleMap["textButton"] = TextStyle(
        fontSize: 16,
        color: styleMap["white"],
        fontWeight: FontWeight.w400,
        decoration: TextDecoration.none);

    styleMap["textHref"] = TextStyle(
        fontSize: 16,
        color: styleMap["linkBlue"],
        fontWeight: FontWeight.bold,
        decoration: TextDecoration.underline);

    styleMap["textBlocked"] = TextStyle(
        fontSize: 16,
        color: styleMap["white"],
        fontWeight: FontWeight.w400,
        decoration: TextDecoration.none);

    styleMap["tooltipDecoration"] = BoxDecoration(
      color: styleMap["tooltipBg"],
      borderRadius: styleMap["borderRounding"],
    );

    styleMap["buttonEnabled"] = ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: styleMap["borderRounding"],
        ),
        textStyle: TextStyle(color: styleMap["white"]).merge( styleMap["textBold"] ),
        backgroundColor: Color.fromARGB(255, 40, 60, 70),
        foregroundColor: styleMap["white"]);
    styleMap["buttonDisabled"] = ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: styleMap["borderRounding"],
        ),
        backgroundColor: styleMap["gray"],
        foregroundColor: styleMap["darkGray"]);
  }
}
