import 'package:flutter/material.dart';
import 'package:webapp_components/mixins/async_manager.dart';
import 'package:webapp_components/mixins/component_base.dart';
import 'package:webapp_components/mixins/component_cache.dart';
import 'package:webapp_components/mixins/state_component.dart';
import 'package:webapp_components/widgets/wait_indicator.dart';
import 'package:webapp_model/webapp_table.dart';

class FetchComponent with
        ChangeNotifier,
        ComponentBase,
        ComponentCache,
        StateComponent,
        AsyncManager{
  WebappTable dataTable = WebappTable();
  
  bool isInit = false;
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
      loadTable().then((onValue)=>isInit = true);
      
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
      busy();
      // notifyListeners();
      var cacheKey = getKey();
      if (hasCachedValue(cacheKey)) {
        dataTable = getCachedValue(cacheKey);
      } else {
        startFuture("dataLoad", dataFetchCallback());

        dataTable = await waitResult("dataLoad"); //  await dataFetchCallback();

        dataTable = postLoad(dataTable);

        addToCache(cacheKey, dataTable);
      }
      idle();
      // notifyListeners();
    }
    return true;
  }


  WebappTable postLoad(WebappTable table){
    return table;
  }

  Widget createWidget(BuildContext context){
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
        return Container();
      } else {
        return createWidget(context);
      }
    }
  }

}