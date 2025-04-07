import 'dart:async';

import 'package:flutter/material.dart';
import 'package:webapp_components/abstract/component.dart';
import 'package:webapp_components/abstract/serializable_component.dart';
import 'package:webapp_components/components/fetch_component.dart';
import 'package:webapp_components/definitions/component.dart';

import 'package:webapp_components/definitions/functions.dart';


import 'package:webapp_components/mixins/component_base.dart';
import 'package:webapp_components/mixins/component_cache.dart';
import 'package:webapp_components/widgets/wait_indicator.dart';
import 'package:webapp_model/webapp_table.dart';
import 'package:webapp_ui_commons/styles/styles.dart';

class ListComponent
    extends FetchComponent implements Component{
  final List<int> expandedRows = [];

  //ACTION Controls
  bool isBusy = false; // Download can take a bit
  final List<ExpansionTileController> expansionControllers = [];
  final TextEditingController filterController = TextEditingController();
  bool expandAll = false;
  //END OF ACTION Controls

  final bool sortByLabel;
  final bool collapsible;

  // final DataFetchCallback dataFetchFunc;

  ListComponent(id, groupId, componentLabel, super.dataFetchFunc,
      {this.sortByLabel = false, this.collapsible = true, bool cache = true}) {
    super.id = id;
    super.groupId = groupId;
    super.componentLabel = componentLabel;
    super.useCache = cache;
  }

  Widget createListEntry(String value) {
    return Text(value);
  }
  
  @override
  Widget createWidget(BuildContext context) {
    expansionControllers.clear();
    var colName = dataTable.colNames.first;
    var data = dataTable.columns[colName]!;

    var rows = new List<int>.generate(10, (i) => i);
    var listEntries = rows.map((row) {
      if (collapsible) {
        return collapsibleWrap(row, "Content", createListEntry(data[row]));
      } else {
        return createListEntry(data[row]);
      }
    }).toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: listEntries,
    );
  }

  Widget collapsibleWrap(int row, String title, Widget wdg) {
    expansionControllers.add(ExpansionTileController());

    var expTile = ExpansionTile(
      key: GlobalKey(),
      title: Text(
        title,
        style: Styles()["textH2"],
      ),
      controller: expansionControllers.last,
      initiallyExpanded: expandedRows.contains(row),
      onExpansionChanged: (isExpanded) {
        if (isExpanded) {
          expandedRows.add(row);
        } else {
          expandedRows.remove(row);
        }
      },
      children: [wdg],
    );

    return expTile;
  }

  Widget expandAllActionWidget() {
    return IconButton(
        onPressed: () {
          for (var ctrl in expansionControllers) {
            ctrl.expand();
          }
        },
        icon: const Icon(Icons.expand));
  }

  Widget collapseAllActionWidget() {
    return IconButton(
        onPressed: () {
          for (var ctrl in expansionControllers) {
            ctrl.collapse();
          }
        },
        icon: const Icon(Icons.compress));
  }

  Widget filterActionWidget() {
    return TextField(
      controller: filterController,
      onChanged: (val) {
        notifyListeners();
      },
      decoration: const InputDecoration(
          prefixIcon: Icon(Icons.filter_alt),
          hintText: "Filter",
          hintStyle: TextStyle(color: Color.fromARGB(150, 150, 150, 150)),
          border: OutlineInputBorder()),
    );
  }

  Widget wrapActionWidget(Widget wdg, {double? width}) {
    return Container(
      constraints: BoxConstraints(maxWidth: width ?? 40),
      child: wdg,
    );
  }

  Widget createToolbar(BuildContext context) {
    var sep = const SizedBox(
      width: 15,
    );
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

  bool shouldIncludeEntry(String title) {
    return title.contains(filterController.text);
  }

  Widget waitingIndicator() {
    //153.5x125.5
    // CircularProgressIndicator
    return Container(
      child: Align(
        alignment: Alignment.center,
        child: Column(
          children: [
            TercenWaitIndicator().indicator,
            const Text(
              "Loading List",
              style: TextStyle(fontSize: 16),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget buildContent(BuildContext context) {
    return build(context);
  }


  // @override
  // Widget buildContent(BuildContext context) {
  //   var cacheKey = getKey();

  //   if (hasCachedValue(cacheKey)) {
  //     return createWidget(context, getCachedValue(cacheKey));
  //   } else {
  //     return FutureBuilder(
  //         future: dataFetchFunc() as Future<dynamic>?,
  //         builder: (context, snapshot) {
  //           if (snapshot.connectionState == ConnectionState.waiting) {
  //             return waitingIndicator();
  //           } else if (snapshot.hasData && snapshot.data != null) {
  //             addToCache(cacheKey, snapshot.data);
  //             return createWidget(context, snapshot.data);
  //           } else if (snapshot.hasError) {
  //             print("ERROR");
  //             print(snapshot.error);
  //             throw Exception(snapshot.error);
  //           } else {
  //             return TercenWaitIndicator()
  //                 .waitingMessage(suffixMsg: "  Loading List"); // Load message
  //           }
  //         });
  //   }
  // }

  @override
  bool isFulfilled() {
    return true;
  }

  @override
  ComponentType getComponentType() {
    return ComponentType.list;
  }

  @override
  void reset() {
    // notifyListeners();
  }

  @override
  getComponentValue() {
    return "";
  }

  @override
  void setComponentValue(value) {}
}
