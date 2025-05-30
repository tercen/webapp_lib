import 'package:flutter/material.dart';
import 'package:webapp_components/definitions/component.dart';
import 'package:webapp_components/mixins/input_validator.dart';
import 'package:webapp_ui_commons/styles/styles.dart';
import 'package:webapp_components/abstract/single_value_component.dart';
import 'package:webapp_model/id_element.dart';


import '../mixins/component_base.dart';

class InputTextComponent with ChangeNotifier, ComponentBase, InputValidator implements SingleValueComponent {
  final TextEditingController controller = TextEditingController();

  final List<void Function()> onChangeFunctions = [];
  final List<void Function()> onFocusLostFunctions = [];

  
  InputTextComponent(id, groupId, componentLabel){
    super.id = id;
    super.groupId = groupId;
    super.componentLabel = componentLabel;

  }

  @override
  void validate(){
    validateSingleInput(getValue());
  }

  @override
  Widget buildContent(BuildContext context) {
    return Focus(
      onFocusChange: (hasFocus) {
        if( !hasFocus ){
          for( var func in onFocusLostFunctions){
            func();
          }
          notifyListeners();
        }
      },
      child: TextField(

        controller: controller,
        
        onChanged: (value) {
          for( var func in onChangeFunctions){
            func();
          }
          notifyListeners();
        } ,
        onTapOutside: (event) {
          
        },
        style: Styles.text,
        decoration: InputDecoration(
          border: OutlineInputBorder(borderRadius: Styles.borderRounding),
        )))
    ;
  }

  @override
  void dispose() {
    super.dispose();
    controller.dispose();
  }


  void setData(data) {
    controller.text = data;
  }



  void onChange(void Function() callback) {
    controller.addListener(callback);
  }

  

  void onLoseFocus(void Function() callback) {
    onFocusLostFunctions.add(callback);
    
  }

  @override
  IdElement getValue() {
    return IdElement(controller.text, controller.text);
  }

  @override
  void setValue(IdElement value) {
    controller.text = value.label;
  }
  
  @override
  bool isFulfilled() {
    return controller.text != "";
  }
  
  @override
  ComponentType getComponentType() {
    return ComponentType.simple;
  }
  

}
