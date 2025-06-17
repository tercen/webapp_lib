import 'package:flutter/material.dart';
import 'package:webapp_model/webapp_table.dart';
import 'package:webapp_ui_commons/styles/styles.dart';

class RowTextColorFormatter {
  bool Function(WebappTable) shouldHighlight;
  RowTextColorFormatter(this.shouldHighlight);

  TextStyle highlightStyle(){
    return (Styles()["text"] as TextStyle).copyWith(color: Styles()["red"]);
  }
}