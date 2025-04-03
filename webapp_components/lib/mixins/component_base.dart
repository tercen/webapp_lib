import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:webapp_components/abstract/component.dart';
import 'package:webapp_model/id_element.dart';
import 'package:sci_tercen_client/sci_client.dart';


mixin class ComponentBase {
  late final String id;
  late final String groupId;
  late final String componentLabel;
  

  String description = "";
 
  final List<Pair> _metaList = [];

  final List<Component> ancestors = [];

  ValueNotifier<int> uiUpdate = ValueNotifier(0);

  String getKey(){
    var key = "${getId()}_${getGroupId()}";
    for( var comp in ancestors ){
      key = "$key${  comp.getComponentValue().hashCode.toString() }";
    }

    return key;
  }

  void addUiListener(VoidCallback listener) {
    uiUpdate.addListener(listener);
  }

  void addParent(Component parent) {
    parent.addListener((){
      reset();
    });
    ancestors.add(parent);
  }

  Future<void> init() async {
    //Generally useful for components which fetch data
  }

  void postInit(){

  }

  String getId(){
    return id;
  }

  String getGroupId(){
    return groupId;
  }

  String getDescription(){
    return description;
  }

  void reset(){
    throw Exception("Reset not implemented. [$id, $groupId, $componentLabel]");
  }

  bool isActive() {
    var parentsActive = true;
    for( var parent in ancestors ){
      parentsActive = parentsActive && (parent.isActive() && parent.isFulfilled());
    }
    return true && parentsActive;
  }


  String label() {
    return componentLabel;
  }

  List<String> getParentIds(){
    return ancestors.map((e) => e.getId()).toList();
  }

  Map<String, List<IdElement>> getAncestorValues(){
    Map<String, List<IdElement>> vals = {};

    // for( var ancestor in ancestors ){
    //   if( ancestor is SingleValueComponent   ){
    //     vals[ancestor.getId()] = [ancestor.getValue()];
    //   }
    //   if( ancestor is MultiValueComponent ){
    //     vals[ancestor.getId()] = ancestor.getValue();
    //   }
      
    // }
    return vals;
  }


  List<Pair> get meta => UnmodifiableListView(_metaList);

  bool hasMeta(String key){
    return _metaList.any((m) => m.key == key);
  }

  void addMeta(String key, String value){
    if( !hasMeta(key)){
      _metaList.add(Pair.from(key, value));
    }else{
      // TODO define behavior here
    }
  }

  Pair? getMeta(String key){
    return _metaList.firstWhere((m) => m.key == key, orElse: null);
  }

}