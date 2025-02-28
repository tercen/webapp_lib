import 'package:flutter/material.dart';
import 'package:webapp_components/definitions/functions.dart';
import 'package:webapp_model/id_element.dart';
import 'package:webapp_model/id_element_table.dart';
import 'package:webapp_components/components/multi_check_component.dart';
import 'package:webapp_components/mixins/component_cache.dart';
import 'package:webapp_components/widgets/wait_indicator.dart';


class MultiCheckComponentFetch extends MultiCheckComponent with ComponentCache {
  DataFetchCallback optionsFetchCallback;
  final String emptyMessage;

  MultiCheckComponentFetch(
      super.id, super.groupId, super.componentLabel, this.optionsFetchCallback,
      {super.columns = 5, this.emptyMessage = "No data available"});

  Future<IdElementTable> fetchCachedOptions() async {
    var key = getKey();
    if (hasCachedValue(key)) {
      return getCachedValue(key);
    } else {
      var val = optionsFetchCallback(getParentIds(), groupId);
      addToCache(key, val);
      return val;
    }
  }

  @override
  Widget buildContent(BuildContext context) {
    return FutureBuilder(
        future: fetchCachedOptions(),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data != null) {
            if (snapshot.data!.colNames.isEmpty) {
              return Text(
                  emptyMessage);
            } else {
              options.clear();
              options
                  .addAll(snapshot.data!.columns[snapshot.data!.colNames[0]]!);
              return super.buildCheckTable();
            }
          } else if (snapshot.hasError) {
            throw Exception(snapshot.error);
          } else {
            return TercenWaitIndicator()
                .waitingMessage(suffixMsg: "Loading data");
          }
        });
  }

  @override
  void setOptions(List<IdElement> optList) {
    throw Exception(
        "Options must be retrieved using the fetch callback function");
  }
}
