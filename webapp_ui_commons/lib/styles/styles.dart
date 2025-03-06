
import 'package:webapp_ui_commons/styles/style_base.dart';

class Styles {
  final Map<String, dynamic> styleMap = {};

  static final Styles _instance = Styles._internal();
  
  factory Styles() {
    return _instance;
  }
  
  Styles._internal();

  void init( List<StyleBase> styles ) async {
    for( var style in styles ){
      style.init();
      styleMap.addAll(style.styleMap);
    }

  }

  dynamic operator [](String key){
    if( !styleMap.keys.contains(key)){
      throw Exception("Inavlid Style key $key");
    }
    return styleMap[key];
  }
}