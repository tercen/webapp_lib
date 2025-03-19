import 'dart:async';

import 'package:flutter/material.dart';
import 'package:webapp_components/abstract/component.dart';
import 'package:webapp_components/abstract/serializable_component.dart';
import 'package:webapp_components/definitions/component.dart';

import 'package:webapp_components/definitions/functions.dart';
import 'package:webapp_components/abstract/multi_value_component.dart';
import 'package:webapp_components/abstract/single_value_component.dart';

import 'package:webapp_components/mixins/component_base.dart';
import 'package:webapp_components/mixins/component_cache.dart';
import 'package:webapp_components/widgets/wait_indicator.dart';
import 'package:webapp_model/webapp_table.dart';
import 'package:webapp_ui_commons/styles/styles.dart';

class ListComponent with ChangeNotifier, ComponentBase, ComponentCache implements Component {
  final List<int> expandedRows = [];

  //ACTION Controls
  bool isBusy = false; // Download can take a bit
  final List<ExpansionTileController> expansionControllers = [];
  final TextEditingController filterController = TextEditingController();
  bool expandAll = false;
  //END OF ACTION Controls

  final bool sortByLabel;
  final bool collapsible ;
  


  final DataFetchCallback dataFetchFunc;
  

  ListComponent(id, groupId, componentLabel, this.dataFetchFunc, {this.sortByLabel = false, this.collapsible = true }){
    super.id = id;
    super.groupId = groupId;
    super.componentLabel = componentLabel;
  }


  Widget createListEntry(String value){
    return Text(value);
  }

  Widget createWidget(BuildContext context, WebappTable table ){
    expansionControllers.clear();
    var colName = table.colNames.first;
    var data = table.columns[colName]!;

    var rows = new List<int>.generate(10, (i) => i);
    var listEntries = rows.map((row) {
      if( collapsible ){
        return collapsibleWrap(row, "Content", createListEntry(data[row]));
      }else{
        return createListEntry(data[row]);
      }
    }).toList();
    // var listEntries = data.map((e) {
    //   if( collapsible ){
    //     return collapsibleWrap("Content", createListEntry(e));
    //   }else{
    //     return createListEntry(e);
    //   }
    // } ).toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: listEntries,
    );
  }
  

  Widget collapsibleWrap( int row, String title, Widget wdg){
    expansionControllers.add(ExpansionTileController());

    var expTile = ExpansionTile(
      key: GlobalKey(),
      title: Text(title, style: Styles()["textH2"],),
      controller: expansionControllers.last,
      initiallyExpanded: expandedRows.contains(row),
        onExpansionChanged: (isExpanded) {
          if(isExpanded ){
            expandedRows.add(row);
          }else{
            expandedRows.remove(row);
          }
        },
      children: [wdg],
    );
    

    return expTile;
  }





  Widget expandAllActionWidget(){
    return IconButton(onPressed: () {
      for( var ctrl in expansionControllers ){
        ctrl.expand();
      }

    }, icon: const Icon(Icons.expand));
  }

  Widget collapseAllActionWidget(){
    return IconButton(onPressed: () {
      for( var ctrl in expansionControllers ){
        
        ctrl.collapse();
      }

    }, icon: const Icon(Icons.compress));
  }

    Widget filterActionWidget(){
    return 
        TextField( 
          controller: filterController,
          onChanged: (val){
            notifyListeners();
          },
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.filter_alt),
            hintText: "Filter",
            hintStyle: TextStyle(color: Color.fromARGB(150, 150, 150, 150)),
            border: OutlineInputBorder()
          ),
         );
  }
  Widget wrapActionWidget( Widget wdg,{ double? width }){
    return Container(
      constraints: BoxConstraints(maxWidth: width ?? 40),
      child: wdg,
    );
  }

    Widget createToolbar(){
    var sep = const SizedBox(width: 15,);
    return Row(
      children: [
        wrapActionWidget(expandAllActionWidget()),
        sep,
        wrapActionWidget(collapseAllActionWidget()),
        sep,
        wrapActionWidget(filterActionWidget(), width: 200),
      ],
    );
  }


  bool shouldIncludeEntry( String title ){
    return title.contains(filterController.text);
  }


  String getCacheKey(){
    var key = "${getId()}${getGroupId()}";
    for( var a in ancestors ){
      key = "$key${a.getComponentValue().toString()}";
    }
    return key;
  }

  Widget waitingIndicator(){
    //153.5x125.5
    // CircularProgressIndicator
    return Container(
      child: Align(
        alignment: Alignment.center,
        child: Column(
          children: [
            TercenWaitIndicator().indicator,
            const Text("Loading List", style: TextStyle(fontSize: 16 ),)
          ],
        ),
      ),
    );
  }

  @override
  Widget buildContent(BuildContext context) {
    var cacheKey = getCacheKey();
    print("Rebuilding with $cacheKey");
    if( hasCachedValue(cacheKey)){
      return createWidget(context, getCachedValue(cacheKey));
    }else{
      return FutureBuilder(
        future: dataFetchFunc() as Future<dynamic>?, 
        builder: (context, snapshot){
          if( snapshot.connectionState == ConnectionState.waiting ){
            return  waitingIndicator();
          }else if( snapshot.hasData && snapshot.data != null){
            addToCache(cacheKey, snapshot.data);
            return createWidget(context, snapshot.data);
          }else if( snapshot.hasError ){
            print("ERROR");
            print(snapshot.error);
            throw Exception(snapshot.error);
          }else{
            return TercenWaitIndicator().waitingMessage(suffixMsg: "  Loading List"); // Load message
          }

        });
    }
  }



 
  @override
  bool isFulfilled() {
    return true;
  }

  @override
  ComponentType getComponentType() {
    return ComponentType.list;
  }
  


  @override
  void reset(){
    // notifyListeners();
  }
  
  @override
  getComponentValue() {
    return "";
  }
  
  @override
  void setComponentValue(value) {
    
  }
  

  
}
