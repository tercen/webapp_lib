import 'package:flutter/material.dart';
import 'package:webapp_components/abstract/component.dart';
import 'package:webapp_components/action_components/definitions.dart';
import 'package:webapp_components/definitions/component.dart';
import 'package:webapp_components/mixins/component_base.dart';
import 'package:webapp_ui_commons/styles/styles.dart';


class ButtonComponent extends ChangeNotifier with ComponentBase implements Component  {
  final String id;
  final String groupId;
  final String componentLabel;
  final ActionCallback action;
  final List<Component>? parents;
  
  final bool blocking;
  bool initEnabled;


  ButtonComponent(this.id, this.groupId, this.componentLabel, this.action, { this.parents, this.blocking = false, this.initEnabled = true});


  @override
  Widget buildContent(BuildContext context) {
    bool btnEnabled = isEnabled();
    return ElevatedButton( style: btnEnabled
                        ? Styles()["buttonEnabled"]
                        : Styles()["buttonDisabled"],
                    onPressed: () async {
                      btnEnabled
                          ? _doAction() // Change function here
                          : null;
                    },
                    child: Text(
                      componentLabel,
                      style: Styles()["textButton"],
                    ));
  }

  Future<void> _doAction() async {
    if( blocking ){
      await action();
    }else{
      action();
    }
  }


  void enable(){
    initEnabled = true;
  }

  void disable(){
    initEnabled = false;
  }

  bool isEnabled() {
    bool enabled = initEnabled;
    if( parents != null){
      enabled = true;
      for( var p in parents! ){
        enabled = enabled && p.isFulfilled();
      }
    }

    return enabled;
  }

  @override
  String label() {
    return componentLabel;
  }
  
  
  @override
  String getId() {
    return id;
  }

  @override
  ComponentType getComponentType() {
    return ComponentType.simpleNoLabel;
  }

  @override
  getComponentValue() {
    return "";
  }

  @override
  String getGroupId() {
    return groupId;
  }

  @override
  bool isFulfilled() {
    return true;
  }

  @override
  void setComponentValue(value) {
    
  }

}