import 'package:flutter/material.dart';
import 'package:webapp_components/abstract/definitions.dart';
import 'package:webapp_components/abstract/component.dart';
import 'package:webapp_components/mixins/component_base.dart';
import 'package:webapp_utils/string_utils.dart';

class HorizontalBarComponent  extends Component with ComponentBase {
  final double thickness;
  HorizontalBarComponent({this.thickness = 2}){
    super.id = StringUtils.getRandomString(4);
    super.groupId = "LAYOUT";
    super.componentLabel = "";
  }

  @override
  Widget buildContent(BuildContext context) {
    return Container(
      height: thickness,
      color: Colors.black,
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