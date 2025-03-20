import 'package:flutter/material.dart';


typedef CheckActionCallback = bool Function( List<String> row );
typedef RowActionCallback = Future<void> Function( List<String> row ) ;

class ListAction{
  Icon actionIcon;
  CheckActionCallback? enabledCallback;
  RowActionCallback callback;
  String? description;
  String? buttonLabel;

  bool toggle = false;

  Icon? toggleIcon;

  ListAction(this.actionIcon, this.callback, {this.enabledCallback, this.description, this.buttonLabel, this.toggleIcon}){
    toggle = toggleIcon != null;
  }
}