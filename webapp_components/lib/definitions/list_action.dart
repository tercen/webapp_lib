import 'package:flutter/material.dart';


typedef CheckActionCallback = bool Function( List<String> row );
typedef RowActionCallback = Future<void> Function( List<String> row ) ;

class ListAction{
  Icon actionIcon;
  CheckActionCallback? enabledCallback;
  RowActionCallback callback;
  String? description;
  String? buttonLabel;

  ListAction(this.actionIcon, this.callback, {this.enabledCallback, this.description, this.buttonLabel});
}