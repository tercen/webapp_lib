
import 'package:flutter/material.dart';

class Styles {
  static const black = Color.fromARGB(255, 26, 26, 41);
  static const gray = Color.fromARGB(255, 180, 180, 190);
  static const darkGray = Color.fromARGB(255, 120, 120, 130);
  static const white = Color.fromARGB(255, 240, 240, 230);
  static const linkBLue = Color.fromARGB(255, 55, 22, 163);

  static const selectedBg = Color.fromARGB(255, 101, 155, 255);
  static const selectedMenuBg = Color.fromARGB(255, 51, 65, 85);
  static const selectedMenuFg = Styles.white;
  static const hoverBg = Color.fromARGB(100, 175, 172, 221);
  static const tooltipBg = Color.fromARGB(199, 14, 11, 62);


  static const headerRow = Color.fromARGB(30, 80, 200, 255);
  static const evenRow = Color.fromARGB(30, 255, 255, 255);
  static const oddRow = Color.fromARGB(30, 120, 240, 255);

  static final BorderRadius borderRounding = BorderRadius.circular(8.0);

  @Deprecated("Use width")
  static const double tfWidthSmall = 120;
  @Deprecated("Use width")
  static const double tfWidthMedium = 200;
  @Deprecated("Use width")
  static const double tfWidthLarge = 400;

  static const double widthIcon = 40;
  static const double widthSmall = 120;
  static const double widthMedium = 200;
  static const double widthLarge = 500;
  static const double widthXLarge = 700;

  static const double heightSmall = 30;
  static const double heightMedium = 50;
  static const double heightLarge = 80;
  static const double smallTableHeight = 200;
  static const double mediumTableHeight = 400;
  static const double largeTableHeight = 650;

  static const double paddingNone = 0;
  static const double paddingSmall = 10;
  static const double paddingMedium = 20;
  static const double paddingLarge = 40;

  //TODO Read from configuration at some point, perhaps
  static const textH1 = TextStyle(
      fontSize: 20,
      color: Styles.black,
      fontWeight: FontWeight.bold,
      decoration: TextDecoration.none);
  static const textH2 = TextStyle(
      fontSize: 18,
      color: Styles.black,
      fontWeight: FontWeight.w600,
      decoration: TextDecoration.none);
  static const menuText = TextStyle(
      fontSize: 18,
      color: Styles.black,
      fontWeight: FontWeight.w600,
      decoration: TextDecoration.none);
  static const menuTextSelected = TextStyle(
      fontSize: 18,
      color: Styles.white,
      fontWeight: FontWeight.w600,
      decoration: TextDecoration.none);
  static const menuTextDisabled = TextStyle(
      fontSize: 18,
      color: Styles.gray,
      fontWeight: FontWeight.w600,
      decoration: TextDecoration.none);
  static const text = TextStyle(
      fontSize: 16,
      color: Styles.black,
      fontWeight: FontWeight.w400,
      decoration: TextDecoration.none);
  static const textGray = TextStyle(
      fontSize: 16,
      color: Styles.darkGray,
      fontWeight: FontWeight.normal,
      decoration: TextDecoration.none);
  static const textTooltip = TextStyle(
      fontSize: 16,
      color: Styles.white,
      fontWeight: FontWeight.normal,
      decoration: TextDecoration.none);
  static const textFile = TextStyle(
      fontSize: 14,
      fontFamily: "RobotMono",
      color: Styles.black,
      decoration: TextDecoration.none);
  static const textBold = TextStyle(
      fontSize: 16,
      color: Styles.black,
      fontWeight: FontWeight.bold,
      decoration: TextDecoration.none);
  static const textButton = TextStyle(
      fontSize: 16,
      color: Styles.white,
      fontWeight: FontWeight.w400,
      decoration: TextDecoration.none);

  static const textHref = TextStyle(
      fontSize: 16,
      color: Styles.linkBLue,
      fontWeight: FontWeight.bold,
      decoration: TextDecoration.underline);

  static const textBlocked = TextStyle(
      fontSize: 16,
      color: Styles.white,
      fontWeight: FontWeight.w400,
      decoration: TextDecoration.none);

  static var tooltipDecoration = BoxDecoration(
    color: Styles.tooltipBg,
    borderRadius: Styles.borderRounding,
  );

  static ButtonStyle buttonEnabled = ElevatedButton.styleFrom(
      shape: RoundedRectangleBorder(
        borderRadius: Styles.borderRounding,
      ),
      backgroundColor: Styles.black,
      foregroundColor: Styles.white);

  static ButtonStyle buttonDisabled = ElevatedButton.styleFrom(
      shape: RoundedRectangleBorder(
        borderRadius: Styles.borderRounding,
      ),
      backgroundColor: Styles.gray,
      foregroundColor: Styles.darkGray);
}