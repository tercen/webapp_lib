import 'package:flutter/material.dart';
import 'package:webapp_model/webapp_table.dart';

typedef CheckActionCallback = bool Function( WebappTable row );
typedef RowActionCallback = Future<void> Function( WebappTable row ) ;

class ListAction{
  Icon actionIcon;
  CheckActionCallback? enabledCallback;
  RowActionCallback? callback;

  ListAction(this.actionIcon, this.callback, {this.enabledCallback});
}