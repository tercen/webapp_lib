import 'package:flutter/material.dart';

import 'package:webapp_components/components/multi_check_fetch.dart';

import 'package:webapp_model/webapp_table.dart';

class MultiCheckComponent extends MultiCheckComponentFetch {
  MultiCheckComponent(id, groupId, componentLabel,
      {super.columns = 5,
      super.hasSelectAll = false,
      super.selectAll = false,
      super.columnWidth,
      super.saveState = true})
      : super(id, groupId, componentLabel, () async {
          return WebappTable();
        }) {
    allSelected = selectAll;
  }

  @override
  void reset() {
    selected.clear();
  }

  Future<WebappTable> optionLoadHolder() async {
    return WebappTable();
  }

  @override
  WebappTable postLoad(WebappTable table) {
    //Prevent options clearing
    return table;
  }

  @override
  Widget buildContent(BuildContext context) {
    return buildCheckTable();
  }

  @override
  void setOptions(List<String> optList) {
    options.clear();

    options.addAll(optList);

    if (selectAll) {
      for (var opt in options) {
        select(opt);
      }
      selectAll = false;
    }
  }
}
