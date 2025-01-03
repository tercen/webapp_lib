import 'package:flutter/material.dart';
import 'package:webapp_components/abstract/definitions.dart';
import 'package:webapp_components/commons/id_element.dart';
import 'package:webapp_components/commons/id_element_table.dart';
// import 'package:kumo_analysis_app/components/commons/extra_widgets.dart';
// import 'package:kumo_analysis_app/components/commons/id_element_table.dart';
// import 'package:kumo_analysis_app/components/commons/wait_indicator.dart';
// import 'package:kumo_analysis_app/components/mixins/base_component.dart';
// import 'package:kumo_analysis_app/components/component.dart';
// import 'package:kumo_analysis_app/components/multi_check_component.dart';
// import 'package:kumo_analysis_app/components/select_dropdown.dart';
// import 'package:kumo_analysis_app/model/data/cache.dart';
// import 'package:kumo_analysis_app/model/model_holder.dart';
// import 'package:kumo_analysis_app/util/ui/styles.dart';
// import 'package:kumo_analysis_app/util/ui_utils.dart';
// import 'package:list_picker/list_picker.dart';
import 'package:webapp_components/components/multi_check_component.dart';
import 'package:webapp_components/mixins/component_cache.dart';
import 'package:webapp_components/widgets/wait_indicator.dart';


class MultiCheckComponentFetch extends MultiCheckComponent with ComponentCache {
  DataFetchCallback optionsFetchCallback;

  MultiCheckComponentFetch(
      super.id, super.groupId, super.componentLabel, this.optionsFetchCallback,
      {super.columns = 5});

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
              return const Text(
                  "Select a prepared data folder to see available gates");
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
                .waitingMessage(suffixMsg: "Loading display gates");
          }
        });
  }

  @override
  void setOptions(List<IdElement> optList) {
    throw Exception(
        "Options must be retrieved using the fetch callback function");
  }
}
