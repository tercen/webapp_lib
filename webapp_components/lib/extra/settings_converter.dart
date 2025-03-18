import 'package:webapp_components/abstract/component.dart';
import 'package:webapp_components/mixins/component_base.dart';
import 'package:webapp_utils/model/step_setting.dart';

class SettingsConverter {
    static StepSetting? settingComponentToStepSetting(Component component) {
    //       comp.addMeta("setting.name", setting.name);
    // comp.addMeta("screen.name", groupId);
    // comp.addMeta("step.name", setting.stepName);
    // comp.addMeta("step.id", setting.stepId);

    
    if( component is ComponentBase ){
      var bComp = component as ComponentBase;
      if(bComp.hasMeta("setting.name") && bComp.hasMeta("step.id")){
        var value = component.getComponentValue();
        if( value is List<String> ){
          return StepSetting(bComp.getMeta("step.id")!.value, bComp.getMeta("setting.name")!.value, value.join(","));
        }else{
          return StepSetting(bComp.getMeta("step.id")!.value, bComp.getMeta("setting.name")!.value, value);
        }
        
      }
    }
      // return StepSetting( component.getId(), );
      //StepId, SettingName
    //   var identifier = component
    //       .getId()
    //       .replaceAll(settingIdentifier(), "")
    //       .split(settingIdSeparator());
    //   if (component is SingleValueComponent) {
    //     StepSetting entry =
    //         StepSetting(identifier[0], identifier[1], component.getValue().id);
    //     return entry;
    //   }
    //   if (component is MultiValueComponent) {
    //     StepSetting entry = StepSetting(identifier[0], identifier[1],
    //         component.getValue().map((e) => e.id).join(","));
    //     return entry;
    //   }
    // }

    return null;
    } 
}