import 'dart:async';

import 'package:flutter/material.dart';
import 'package:webapp_components/abstract/serializable_component.dart';
import 'package:webapp_components/definitions/component.dart';
import 'package:webapp_components/definitions/functions.dart';

import 'package:webapp_components/mixins/component_base.dart';
import 'package:webapp_components/mixins/component_cache.dart';
import 'package:webapp_components/mixins/infobox_component.dart';
import 'package:webapp_components/widgets/wait_indicator.dart';
import 'package:webapp_model/webapp_table.dart';
import 'package:webapp_ui_commons/styles/styles.dart';
import 'package:webapp_utils/functions/list_utils.dart';

class SelectableListComponent
    with ChangeNotifier, ComponentBase, ComponentInfoBox, ComponentCache
    implements SerializableComponent {
  final bool sortByLabel;
  String selected = "";

  late String Function(String, {String id}) labelTransformCallback;

  String? cacheKey;
  final bool shouldSave;

  final DataFetchCallback dataFetchFunc;

  SelectableListComponent(id, groupId, componentLabel, this.dataFetchFunc,
      {infoBoxBuilder,
      String Function(String, {String id})? pathTransformCallback,
      this.sortByLabel = false,
      this.shouldSave = true}) {
    super.id = id;
    super.groupId = groupId;
    super.componentLabel = componentLabel;
    super.infoBoxBuilder = infoBoxBuilder;

    if (pathTransformCallback == null) {
      labelTransformCallback = basename;
    } else {
      labelTransformCallback = pathTransformCallback;
    }
  }

  String basename(String name, {String id = ""}) {
    return name;
  }

  Future<WebappTable> callCachedCallback(Map<String, dynamic> values) async {
    if (cacheKey == null) {
      return await dataFetchFunc();
    } else {
      if (hasCachedValue(selected)) {
        return getCachedValue(selected) as WebappTable;
      } else {
        var cachedTable = await dataFetchFunc();
        addToCache(selected, cachedTable);
        return cachedTable;
      }
    }
  }

  @override
  Widget buildContent(BuildContext context) {
    var cacheKey = getKey();
    if (hasCachedValue(cacheKey)) {
      return createTable(context, getCachedValue(cacheKey));
    } else {
      return FutureBuilder(
          future: callCachedCallback(getAncestorValues()) as Future<dynamic>?,
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data != null) {
              addToCache(cacheKey, snapshot.data);
              return createTable(context, snapshot.data);
            } else if (snapshot.hasError) {
              throw Exception(snapshot.error);
            } else {
              return TercenWaitIndicator().waitingMessage(
                  suffixMsg: "Loading Table..."); // Load message
            }
          });
    }
  }

  Widget createTable(BuildContext context, WebappTable dataTable) {
    List<Widget> tableRows = [];
    assert(dataTable.hasColumn("label"));
    assert(dataTable.hasColumn("id"));

    var labels = dataTable["label"];
    var ids = dataTable["id"];

    var indices = List<int>.generate(dataTable.nRows, (i) => i);
    if (sortByLabel) {
      indices = ListUtils.getSortedIndices(labels);
    }

    for (var i in indices) {
      String lbl = labels[i];
      lbl = labelTransformCallback(labels[i], id: ids[i]);

      tableRows.add(createRow(ids[i], lbl, i % 2 == 0, context));
    }

    return Column(children: tableRows);
  }

  bool isSelected(String id) {
    return selected != "" && selected.contains(id);
  }

  Widget checkBox(String id, String name) {
    return Checkbox(
        value: isSelected(id),
        side: WidgetStateBorderSide.resolveWith((states) => BorderSide(
              color: Styles()["black"],
              width: 1.5,
            )),
        fillColor:
            WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
          return Color.fromARGB(255, 255, 255, 255);
        }),
        onChanged: (value) {
          if (value == true) {
            selected = id;
          } else {
            selected = "";
          }
          notifyListeners();
        });
    // return IconButton(
    //     onPressed: () {
    //       isSelected(id)
    //           ? selected = ""
    //           : selected = id;
    //       notifyListeners();
    //     },
    //     icon: isSelected(id)
    //         ? const Icon(Icons.check_box_outlined)
    //         : const Icon(Icons.check_box_outline_blank));
  }

  Widget createRow(String id, String name, bool isEven, BuildContext context) {
    var checkboxWidget = checkBox(id, name);

    var rowWdg = Row(
      children: [
        const SizedBox(
          width: 15,
        ),
        SizedBox(
          width: 50,
          child: checkboxWidget,
        ),
        buildInfoBoxIcon(id, context, title: "${infoBoxBuilder?.title}: $name"),
        //Flexible allows text wrapping in the row
        Flexible(
            child: Text(
          name,
          style: Styles()["text"],
        )),
      ],
    );

    return Container(
      constraints: const BoxConstraints(minHeight: 45),
      color: isEven ? Styles()["evenRow"] : Styles()["oddRow"],
      child: rowWdg,
    );
  }

  @override
  bool isFulfilled() {
    return selected != "";
  }

  @override
  ComponentType getComponentType() {
    return ComponentType.list;
  }

  @override
  void reset() {
    selected = "";
  }

  @override
  getComponentValue() {
    return selected;
  }

  @override
  String getStateValue() {
    return selected;
  }

  @override
  void setComponentValue(value) {
    selected = value;
  }

  @override
  void setStateValue(String value) {
    selected = value;
  }

  @override
  bool shouldSaveState() {
    return shouldSave;
  }
}
