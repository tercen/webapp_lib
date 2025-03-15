import 'package:json_annotation/json_annotation.dart';
import 'package:sci_tercen_client/sci_client.dart';
import 'package:webapp_model/model/view_object.dart';

part 'view_state.g.dart';

@JsonSerializable()
class ViewState {
  List<ViewObject> objects;

  ViewState({required this.objects});

  factory ViewState.fromJson(Map<String, dynamic> json) =>
      _$ViewStateFromJson(json);

  Map<String, dynamic> toJson() => _$ViewStateToJson(this);

  void clear(){
    objects.clear();
  }

  String operator [](String key) {
    var objList = objects.where((o) => o.key == key );
    if( objList.isEmpty ){
      throw ServiceError(500, "View key does not exist", "View key $key does not exist");
    }

    return objList.first.values;
  }

  void operator []=(String key, String value) {
    var objList = objects.where((o) => o.key == key );
    if( objList.isEmpty ){
      objects.add(ViewObject(key: key, values: value));
    }else{
      objList.first.values = value;
    }
  }

  bool hasKey(String key){
    return objects.any((o) => o.key == key );
  }

}