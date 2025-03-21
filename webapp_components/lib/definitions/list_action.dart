import 'package:flutter/material.dart';


typedef CheckActionCallback = bool Function( List<String> row );
typedef RowActionCallback = Future<void> Function( List<String> row ) ;

class ListAction{
  final Icon actionIcon;
  final CheckActionCallback? enabledCallback;
  final RowActionCallback callback;
  final String? description;
  final String? buttonLabel;

  final bool requireConfirmation;
  bool toggle = false;

  final Icon? toggleIcon;

  ListAction(this.actionIcon, this.callback, {this.enabledCallback, this.description, this.buttonLabel, this.toggleIcon, this.requireConfirmation = false}){
    toggle = toggleIcon != null;
  }
}