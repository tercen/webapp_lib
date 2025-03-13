import 'package:flutter/services.dart';
import 'package:json_string/json_string.dart';
import 'package:webapp_model/settings/settings_filter.dart';
import 'package:webapp_utils/model/settings_entry.dart';


class SettingsDataService{
  static final SettingsDataService _singleton = SettingsDataService._internal();
  
  factory SettingsDataService() {
    return _singleton;
  }

  
  SettingsDataService._internal();

  SettingsFilter settingsFilters = SettingsFilter(filters: []);

  Future<void> loadSettingsFilter(String assetPath) async {
    var assetString = await rootBundle.loadString(assetPath);
    final jsonString = JsonString(assetString);

    settingsFilters = SettingsFilter.fromJson(jsonString.decodedValueAsMap);
   
  }

  final Map<String, List<SettingsEntry>> _settingsMap = {};

  List<SettingsEntry> get( String key ){
    if( !_settingsMap.containsKey(key)){
      throw Exception("Key $key not found in settings map");
    }
    return _settingsMap[key]!;
  }

  Future<void> loadSettings( List<String> nameList, List<String> assetList  ) async {
    assert(nameList.length == assetList.length);
    var settings = await Future.wait(assetList.map((e) => _loadSettingsFile(e)));
    for( var i = 0; i < nameList.length; i++ ){
      _settingsMap[nameList[i]] = settings[i];
    }
  }

  Future<List<SettingsEntry>> _loadSettingsFile(String path) async {
    if( path == ""){
      return [];
    }
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