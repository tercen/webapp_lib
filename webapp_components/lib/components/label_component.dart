import 'package:flutter/material.dart';

import 'package:webapp_components/abstract/component.dart';
import 'package:webapp_components/definitions/component.dart';
import 'package:webapp_components/mixins/component_base.dart';
import 'package:webapp_ui_commons/styles/styles.dart';
import 'package:webapp_utils/functions/string_utils.dart';

class LabelComponent  extends Component with ComponentBase {
  final String text;
  LabelComponent(this.text){
    super.id = StringUtils.getRandomString(4);
    super.groupId = LAYOUT_GROUP;
    super.componentLabel = "";
  }

  @override
  Widget buildContent(BuildContext context) {
    return Text(
      text,
      style: Styles()["textH2"],
    );
  }

  @override
  ComponentType getComponentType() {
    return ComponentType.simpleNoLabel;
  }

  

  @override
  void reset(){
    
  } 

  // @override
  // bool isActive() {
  //   return true;
  // }

  @override
  bool isFulfilled() {
    return true;
  }

  @override
  String label() {
    return "";
  }

  

}