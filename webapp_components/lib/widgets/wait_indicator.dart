import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webapp_ui_commons/styles/styles.dart';

class TercenWaitIndicator {
  bool isInit = false;
  static final TercenWaitIndicator _singleton = TercenWaitIndicator._internal();

  factory TercenWaitIndicator() {
    return _singleton;
  }

  TercenWaitIndicator._internal();

  late final Image _indicator;
  late final Image _indicatorLarge;

  Future<void> init({ByteData? assetData}) async {
    // var bData = await rootBundle.load(assetPath ?? "assets/img/wait.webp");
    var bData = assetData ?? await rootBundle.load("assets/img/wait.webp");

    _indicator = Image.memory(
      bData.buffer.asUint8List(),
      width: 125.5 * 0.5,
      height: 135.5 * 0.5,
    );
    _indicatorLarge = Image.memory(
      bData.buffer.asUint8List(),
      width: 125.5,
      height: 135.5,
    );
    isInit = true;
  }

  Widget get indicator => _indicator;

  Widget waitingMessage(
      {String prefixMsg = "",
      String suffixMsg = "",
      String bottomMsg = "",
      double size = 25.0, double bottomFontSize = 16}) {
    Widget wdg = Center(
        child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              prefixMsg,
              style: Styles()["text"],
            ),
            prefixMsg != ""
                ? const SizedBox(
                    width: 10,
                  )
                : Container(),
            SizedBox(width: size, height: size, child: _indicator),
            suffixMsg != ""
                ? const SizedBox(
                    width: 10,
                  )
                : Container(),
            Text(
              suffixMsg,
              style: Styles()["text"],
            ),
          ],
        ),
        bottomMsg != ""
            ? Padding(
                padding: const EdgeInsets.only(top: 20.0),
                child: Text(
                  bottomMsg,
                  style: Styles()["text"].copyWith(fontSize: bottomFontSize),
                ),
              )
            : Container(),
      ],
    ));

    return wdg;
  }
}
