
class SettingsEntry{
  static const String typeInt = "int";
  static const String typeDouble = "double";
  static const String typeText = "string";
  static const String typeBool = "boolean";
  static const String typeListSingle = "ListSingle";
  static const String typeListMultiple = "ListMultiple";
  static const String typeRichText = "RichText";


  final String settingName;
  final String stepName;
  final String stepId;
  final String hint;
  final String type;
  final String mode;
  final String section;
  
  late String textValue;
  late List<String> options = [];


  SettingsEntry(this.stepName, this.stepId, this.settingName, this.section,  this.hint, this.type, this.textValue, this.mode) {
    textValue = textValue.trim();

  }

  void clearOptions(){

    options.clear();
  }

  void addOptions(List<String> opt){

    for( var o in opt ){
      options.add(o);
    }
  }

  String info(){
    return "Name: $settingName\nType: $type\nValue: $textValue\nSection: $section";
  }
}

