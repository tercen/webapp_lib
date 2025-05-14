import 'package:flutter/material.dart';
import 'package:webapp_components/mixins/async_manager.dart';
import 'package:webapp_components/mixins/component_base.dart';
import 'package:webapp_components/mixins/state_component.dart';
import 'package:webapp_components/widgets/wait_indicator.dart';
import 'package:webapp_model/webapp_table.dart';
import 'package:webapp_utils/cache_object.dart';




class FetchComponent with
        ChangeNotifier,
        ComponentBase,
        StateComponent,
        AsyncManager{
  WebappTable dataTable = WebappTable();
  final CacheObject cacheObj = CacheObject();
  bool isInit = false;
  bool useCache = true;
  Future<WebappTable> Function() dataFetchCallback;

  FetchComponent( this.dataFetchCallback );

  @override
  void dispose() {
    super.dispose();
    cancelAllOperations();
  }

  Future<void> init() async {
    if (isActive() && !isInit) {
      super.init();
      loadTable();
      
    }
  }


  @override
  void reset() {
    cancelAllOperations();
    dataTable = WebappTable();
    isInit = false;
    init();
  }


  Future<bool> loadTable() async {
    if (!isInit) {
      isInit = true;
      busy();
      var cacheKey = getKey();
      if (useCache && cacheObj.hasCachedValue(cacheKey)) {
        dataTable = cacheObj.getCachedValue(cacheKey);
      } else {
        startFuture("dataLoad", dataFetchCallback());

        dataTable = await waitResult("dataLoad"); //  await dataFetchCallback();

        dataTable = postLoad(dataTable);
        if( useCache ){
          cacheObj.addToCache(cacheKey, dataTable);
        }
        
      }
      idle();

    }
    return true;
  }


  WebappTable postLoad(WebappTable table){
    return table;
  }

  Widget createWidget(BuildContext context){
    return Container();
  }

  Widget buildEmptyTable(){
    return Container();
  }

  Widget build(BuildContext context) {
    if (isBusy) {
      return SizedBox(
          height: 100,
          child: TercenWaitIndicator()
              .waitingMessage(suffixMsg: "  Loading Component"));
    } else {
      if (dataTable.nRows == 0) {
        return buildEmptyTable();
      } else {
        return createWidget(context);
      }
    }
  }

}