import 'package:flutter/services.dart';
import 'package:json_string/json_string.dart';
import 'package:webapp_workflow/service/model/settings_entry.dart';


class SettingsDataService{
  final Map<String, List<SettingsEntry>> _settingsMap = {};

  List<SettingsEntry> get( String key ){
    if( !_settingsMap.containsKey(key)){
      throw Exception("Key $key not found in settings map");
    }
    return _settingsMap[key]!;
  }

  Future<void> loadSettings(List<String> settingsFiles ) async {
    await Future.wait(settingsFiles.map((e) => _loadSettingsFile(e)));
    var settings = await Future.wait(settingsFiles.map((e) => _loadSettingsFile(e)));

    for (var i = 0; i < settings.length; i++) {
      _settingsMap[settingsFiles[i]] = settings[i];  
    }
  }

  Future<List<SettingsEntry>> _loadSettingsFile(String path) async {

    List<SettingsEntry> settingsList = [];

    String settingsStr = await rootBundle.loadString(path);
    try {
      final jsonString = JsonString(settingsStr);
      final settingsMap = jsonString.decodedValueAsMap;

      
      for(int i = 0; i < settingsMap["settings"].length; i++){
        Map<String, dynamic> jsonEntry = settingsMap["settings"][i];  
        
        SettingsEntry setting = SettingsEntry(
          jsonEntry["step_name"],
          jsonEntry["step_id"],
          jsonEntry["setting_name"],
          jsonEntry["section"],
          jsonEntry["hint"],
          jsonEntry["type"], 
          jsonEntry["value"],
          jsonEntry["mode"]);

        if( jsonEntry.keys.contains("options") ){
          List<String> options = jsonEntry["options"].toString().replaceAll("[", "").replaceAll("]", "").split(",").map((e) => e.trim()).toList();

          setting.addOptions(options);
        }

        settingsList.add(setting);
      }

    } on Exception catch (e) {
        print('Invalid JSON: $e');
    }
    return settingsList;
  }
}