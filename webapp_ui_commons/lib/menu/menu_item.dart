import 'package:flutter/material.dart';

class MenuItem {
  String label;
  StatefulWidget screen;
  bool Function()? enabledCallback;

  MenuItem(this.label, this.screen, this.enabledCallback);

  bool isEnabled() {
    if (enabledCallback == null) {
      return true;
    }

    return enabledCallback!();
  }
}