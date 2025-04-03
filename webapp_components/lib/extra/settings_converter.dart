import 'package:webapp_components/abstract/component.dart';
import 'package:webapp_components/mixins/component_base.dart';
import 'package:webapp_utils/model/step_setting.dart';

class SettingsConverter {
    static StepSetting? settingComponentToStepSetting(Component component) {
   
    if( component is ComponentBase ){
      var bComp = component as ComponentBase;
      if(bComp.hasMeta("setting.name") && bComp.hasMeta("step.id")){
        var value = component.getComponentValue();
        if( value is List<String> ){
          return StepSetting(bComp.getMeta("step.id")!.value, bComp.getMeta("setting.name")!.value, value.join(","));
        }else{
          return StepSetting(bComp.getMeta("step.id")!.value, bComp.getMeta("setting.name")!.value, value.toString());
        }
        
      }
    }

    return null;
    } 
}