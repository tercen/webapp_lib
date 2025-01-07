import 'package:webapp_components/abstract/component.dart';
import 'package:webapp_components/abstract/multi_value_component.dart';
import 'package:webapp_components/abstract/single_value_component.dart';
import 'package:webapp_components/components/input_text_component.dart';
import 'package:webapp_components/components/multi_check_component.dart';
import 'package:webapp_components/components/select_dropdown.dart';
import 'package:webapp_components/settings/settings_entry.dart';
import 'package:webapp_components/service/settings_data_service.dart';
import 'package:webapp_model/id_element.dart';
import 'package:webapp_workflow/model/step_setting.dart';


class SettingsLoader {
  final String settingsJsonPath;
  final String groupId;

  SettingsLoader( this.groupId, this.settingsJsonPath);

  static String settingIdSeparator(){
    return "|@|";
  }

  static String settingIdentifier(){
    return "|SETTING|";
  }

  static StepSetting? settingComponentToStepSetting(Component component){
    if( component.getId().startsWith(settingIdentifier())){
      //StepId, SettingName
      var identifier = component.getId().replaceAll(settingIdentifier(), "").split(settingIdSeparator());
      if( component is SingleValueComponent ){
        
        StepSetting entry = StepSetting( identifier[0], identifier[1], component.getValue().id);
        return entry;  
      }
      if( component is MultiValueComponent ){
        StepSetting entry = StepSetting( identifier[0], identifier[1], component.getValue().map((e) => e.id).join(","));
        return entry;  
      }
      
    }
    
    return null;
  }

  List<Component> componentsFromSettings(  {String? mode, String? stepId, String? section} )  {
    List<Component> comps = [];
    var settingsService = SettingsDataService();
    List<SettingsEntry> settings = settingsService.get(settingsJsonPath); 

    if( mode != null){
      settings = settings.where((e) => e.mode == mode ).toList();
    }
    if( stepId != null){
      settings = settings.where((e) => e.stepId == stepId ).toList();
    }
    if( section != null){
      settings = settings.where((e) => e.section == section ).toList();
    }

    for( var setting in settings ){
      var settingId = "${settingIdentifier()}${setting.stepId}${settingIdSeparator()}${setting.settingName}";
      // print("Iterating over ${setting.settingName} of type ${setting.type}");
      switch (setting.type) { 
        case "int":
        case "double":
        case "string":
          // var rndId = getRandomString(5);
          var comp = InputTextComponent( settingId, groupId, setting.settingName );
          comp.setData(setting.textValue);
          comps.add(comp); 
          
          break;
        case "ListMultiple":
          var comp = MultiCheckComponent(settingId, groupId, setting.settingName, columns: 5);
          comp.setOptions(setting.options.map((e) => IdElement(e, e)).toList());
          comp.setValue(setting.textValue.split(",").map((e) => IdElement(e, e)).toList()  );
          comps.add(comp);
          break;
        case "ListSingle":
          var comp = SelectDropDownComponent(settingId, groupId, setting.settingName);
          comp.selected = IdElement(setting.textValue, setting.textValue);
          comp.setOptions(setting.options.map((e) => IdElement(e, e)).toList());
          comps.add(comp);
          break;
        default:
      }
    }


    return comps;
  }

}
