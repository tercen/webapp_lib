

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

  Future<void> init({ByteData? assetData}) async {
    // var bData = await rootBundle.load(assetPath ?? "assets/img/wait.webp");
    var bData = assetData ?? await rootBundle.load("assets/img/wait.webp");
    
    
    _indicator = Image.memory( bData.buffer.asUint8List(), width: 125.5*0.5, height: 135.5*0.5, );
    isInit = true;
  }

  Widget get indicator => _indicator;

  Widget waitingMessage({String prefixMsg = "", String suffixMsg = ""}) {
    Widget wdg = Center(
      child: Row(
        children: [
          Text(
            prefixMsg,
            style: Styles()["text"],
          ),
          prefixMsg != "" ? const SizedBox(width: 10,) : Container(),
          SizedBox(width: 25, height: 25, child: _indicator),
          suffixMsg != "" ? const SizedBox(width: 10,) : Container(),
          Text(
            suffixMsg,
            style: Styles()["text"],
          ),
        ],
      ),
    );

    return wdg;
  }
}