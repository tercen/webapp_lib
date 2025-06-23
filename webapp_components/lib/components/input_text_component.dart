import 'package:flutter/material.dart';
import 'package:webapp_components/abstract/serializable_component.dart';
import 'package:webapp_components/definitions/component.dart';
import 'package:webapp_components/mixins/input_validator.dart';
import 'package:webapp_ui_commons/styles/styles.dart';



import '../mixins/component_base.dart';

class InputTextComponent with ChangeNotifier, ComponentBase, InputValidator implements SerializableComponent {
  final TextEditingController controller = TextEditingController();

  final List<void Function()> onChangeFunctions = [];
  final List<void Function()> onFocusLostFunctions = [];

  final bool saveState;
  
  InputTextComponent(id, groupId, componentLabel, {this.saveState = true}){
    super.id = id;
    super.groupId = groupId;
    super.componentLabel = componentLabel;
    // controller.addListener(updateValue);
    // updateTrack.addListener(modelUpdated);
  }



  @override
  void validate(){
    validateSingleInput(getComponentValue());
  }

  @override
  Widget buildContent(BuildContext context) {
    return Focus(
      onFocusChange: (hasFocus) {
        if( !hasFocus ){
          // setValue(id, getGroupId(),  [controller.text], notify: false);
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
          if( onChangeFunctions.isNotEmpty ){
            notifyListeners();
          }
          
        } ,
        onTapOutside: (event) {
          // setValue(id, getGroupId(),  [controller.text], notify: false);
        },
        style: Styles()["text"],
        decoration: InputDecoration(
          border: OutlineInputBorder(borderRadius: Styles()["borderRounding"]),
        )))
    ;
  }

  @override
  void dispose() {
    super.dispose();
    controller.dispose();
  }


  // void setData(data) {
  //   controller.text = data;
  // }



  void onChange(void Function() callback) {
    controller.addListener(callback);
  }

  

  void onLoseFocus(void Function() callback) {
    onFocusLostFunctions.add(callback);
    
  }

  @override
  bool isFulfilled() {
    return controller.text != "" && isInputValid( getComponentValue() );
  }
  
  @override
  ComponentType getComponentType() {
    return ComponentType.simple;
  }
  
  @override
  getComponentValue() {
    return controller.text;
  }
  
  @override
  void setComponentValue(value) {
    controller.text = value;
    // updateValue();
  }
  
  @override
  String getStateValue() {
    return controller.text;
  }
  
  @override
  void setStateValue(String value) {
    setComponentValue(value);
  }
  
  @override
  bool shouldSaveState() {
    return saveState;
  }
  

}
