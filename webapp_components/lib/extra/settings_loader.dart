// import 'package:flutter/services.dart';
// import 'package:json_string/json_string.dart';
// import 'package:kumo_analysis_app/components/component.dart';
// import 'package:kumo_analysis_app/components/input_text.dart';
// import 'package:kumo_analysis_app/components/multi_check_component.dart';
// import 'package:kumo_analysis_app/components/select_dropdown.dart';

// import 'package:kumo_analysis_app/model/data/settings.dart';
// import 'package:kumo_analysis_app/util/ui_utils.dart';
// import 'package:kumo_analysis_app/util/util.dart';
// import 'package:kumo_analysis_app/webapp_data.dart';

// class SettingsLoader {
//   final String settingsJsonPath;
//   final String groupId;
//   final WebAppData modelLayer;
//   SettingsLoader(this.modelLayer, this.groupId, this.settingsJsonPath);

//         // {
//         //     "section": "UMAP",
//         //     "mode": "default",
//         //     "step_name": "UMAP",
//         //     "step_id": "730cda6b-e33d-4c8d-945a-0eecba5cb23c",
//         //     "setting_name":"[UMAP] N Neighbors",
//         //     "hint": "The number of neighbors considered in UMAP",
//         //     "type": "int",
//         //     "value": "15"
//         // },

//   static String settingIdSeparator(){
//     return "|@|";
//   }

//   static String settingIdentifier(){
//     return "|SETTING|";
//   }

//   static SettingsEntry? settingComponentToSettingEntry(Component component){
//     if( component.getId().startsWith(settingIdentifier())){
//       var identifier = component.getId().replaceAll(settingIdentifier(), "").split(settingIdSeparator());
//       if( component is SingleValueComponent ){
//         SettingsEntry entry = SettingsEntry("", identifier[0], identifier[1], "", "", "", component.getValue().id, "");
//         return entry;  
//       }
//       if( component is MultiValueComponent ){
//         SettingsEntry entry = SettingsEntry("", identifier[0], identifier[1], "", "", "", component.getValue().map((e) => e.id).join(","), "");
//         return entry;  
//       }
      
//     }
    
//     return null;
//   }

//   List<Component> componentsFromSettings(  {String? mode, String? stepId, String? section} )  {
//     List<Component> comps = [];

//     List<SettingsEntry> settings =  modelLayer.settingsService.get(settingsJsonPath); 

//     if( mode != null){
//       settings = settings.where((e) => e.mode == mode ).toList();
//     }
//     if( stepId != null){
//       settings = settings.where((e) => e.stepId == stepId ).toList();
//     }
//     if( section != null){
//       settings = settings.where((e) => e.section == section ).toList();
//     }

//     for( var setting in settings ){
//       var settingId = "${settingIdentifier()}${setting.stepId}${settingIdSeparator()}${setting.settingName}";
//       // print("Iterating over ${setting.settingName} of type ${setting.type}");
//       switch (setting.type) { 
//         case "int":
//         case "double":
//         case "string":
//           // var rndId = getRandomString(5);
//           var comp = InputTextComponent( settingId, groupId, setting.settingName );
//           comp.setData(setting.textValue);
//           comps.add(comp); 
          
//           break;
//         case "ListMultiple":
//           var comp = MultiCheckComponent(settingId, groupId, setting.settingName, columns: 5);
//           comp.setOptions(setting.options.map((e) => IdElement(e, e)).toList());
//           comp.setValue(setting.textValue.split(",").map((e) => IdElement(e, e)).toList()  );
//           comps.add(comp);
//           break;
//         case "ListSingle":
//           var comp = SelectDropDownComponent(settingId, groupId, setting.settingName);
//           comp.selected = IdElement(setting.textValue, setting.textValue);
//           comp.setOptions(setting.options.map((e) => IdElement(e, e)).toList());
//           comps.add(comp);
//           break;
//         default:
//       }
//     }


//     return comps;
//   }

// }
