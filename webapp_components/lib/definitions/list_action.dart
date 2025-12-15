import 'package:flutter/material.dart';
import 'package:webapp_components/components/label_component.dart';
import 'package:webapp_components/extra/modal_Screen_base.dart';
import 'package:webapp_model/webapp_table.dart';
import 'package:webapp_ui_commons/styles/styles.dart';


typedef CheckActionCallback = bool Function( WebappTable row );
typedef RowActionCallback = Future<void> Function( WebappTable row ) ;

class ListAction{
  final Icon actionIcon;

  final CheckActionCallback? enabledCallback;
  final RowActionCallback callback;
  final String? description;
  final String? buttonLabel;
  final String? underLabel;

  final String confirmationMessage;

  bool get requireConfirmation => confirmationMessage != "";
  bool toggle = false;

  final Icon? toggleIcon;

  late Icon disabledIcon;

  ListAction(this.actionIcon, this.callback, {this.enabledCallback, this.description, this.buttonLabel, this.underLabel, this.toggleIcon, this.confirmationMessage = ""}){
    toggle = toggleIcon != null;
    disabledIcon = Icon( actionIcon.icon, color: Styles()["gray"],);
  }

  Icon getIcon({WebappTable? params}){
    if( params == null){
      params = WebappTable();
    }
    if(  isEnabled(params)){
      
      if( toggleIcon != null && toggle ){
        return toggleIcon!;
      }else{
        return actionIcon;
      }
      
    }else{
      return disabledIcon;
    }
  }

  bool isEnabled(WebappTable params){
    return this.enabledCallback == null || this.enabledCallback!( params );
  }



  Future<void> callAction(WebappTable params, {BuildContext? context}) async {
    if( isEnabled(params)){
      if( requireConfirmation ){
        assert( context != null );
        var confScreen = ModalScreenBase("Confirmation", [LabelComponent(confirmationMessage)]);
        confScreen.addListener(() {
          callback(params);
        });
        confScreen.build(context!);
      }else{
        if( toggleIcon != null ){
          toggle = !toggle;
        }
        callback(params);
      }
    }
  }
}