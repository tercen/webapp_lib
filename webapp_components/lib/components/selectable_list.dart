import 'dart:async';

import 'package:flutter/material.dart';
import 'package:webapp_components/abstract/definitions.dart';
import 'package:webapp_components/abstract/single_value_component.dart';
import 'package:webapp_components/commons/id_element.dart';
import 'package:webapp_components/commons/id_element_table.dart';
import 'package:webapp_components/mixins/component_base.dart';
import 'package:webapp_components/mixins/component_cache.dart';
import 'package:webapp_components/mixins/infobox_component.dart';
import 'package:webapp_components/widgets/wait_indicator.dart';
import 'package:webapp_ui_commons/styles/styles.dart';
import 'package:webapp_utils/list_utils.dart';

class SelectableListComponent
    with ChangeNotifier, ComponentBase, ComponentInfoBox, ComponentCache
    implements SingleValueComponent {
  final bool sortByLabel;
  IdElement _selected = IdElement("", "");

  late String Function(IdElement) labelTransformCallback;

  String? _cacheKey;

  final DataFetchCallback dataFetchFunc;

  SelectableListComponent(id, groupId, componentLabel, this.dataFetchFunc,
      {infoBoxBuilder,
      String Function(IdElement)? pathTransformCallback,
      this.sortByLabel = false}) {
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

  String basename(IdElement el) {
    return el.label;
  }

  void setCacheKey(String key) {
    _cacheKey = key;
  }

  Future<IdElementTable> _callCachedCallback(
      Map<String, dynamic> values) async {
    if (_cacheKey == null) {
      return await dataFetchFunc(getParentIds(), groupId);
    } else {
      if (hasCachedValue(_selected.id)) {
        return getCachedValue(_selected.id) as IdElementTable;
      } else {
        var cachedIdElementTable = await dataFetchFunc(getParentIds(), groupId);
        addToCache(_selected.id, cachedIdElementTable);
        return cachedIdElementTable;
      }
    }
  }

  String getCacheKey() {
    var key = "${getId()}${getGroupId()}";
    for (var a in ancestors) {
      if (a is SingleValueComponent) {
        key = "$key${a.getValue().id}";
      }
    }
    return key;
  }

  @override
  Widget buildContent(BuildContext context) {
    var cacheKey = getCacheKey();
    if (hasCachedValue(cacheKey)) {
      return _createTable(context, getCachedValue(cacheKey));
    } else {
      return FutureBuilder(
          future: _callCachedCallback(getAncestorValues()) as Future<dynamic>?,
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data != null) {
              addToCache(cacheKey, snapshot.data);
              return _createTable(context, snapshot.data);
            } else if (snapshot.hasError) {
              throw Exception(snapshot.error);
            } else {
              return TercenWaitIndicator().waitingMessage(
                  suffixMsg: "Loading Table..."); // Load message
            }
          });
    }
  }

  Widget _createTable(BuildContext context, IdElementTable dataTable) {
    List<Widget> tableRows = [];
    var dataList = dataTable.getValuesByIndex(0) ?? [];

    var indices = List<int>.generate(dataList.length, (i) => i);
    if (sortByLabel) {
      indices =
          ListUtils.getSortedIndices(dataList.map((e) => e.label).toList());
    }

    for (var i in indices) {
      String lbl = dataList[i].label;
      lbl =
          labelTransformCallback(IdElement(dataList[i].id, dataList[i].label));

      tableRows.add(_createRow(dataList[i].id, lbl, i % 2 == 0, context));
    }

    return Column(children: tableRows);
  }

  IconButton _checkBox(String id, String name, bool isSelected) {
    return IconButton(
        onPressed: () {
          isSelected
              ? _selected = IdElement("", "")
              : _selected = IdElement(id, name);
          notifyListeners();
        },
        icon: isSelected
            ? const Icon(Icons.check_box_outlined)
            : const Icon(Icons.check_box_outline_blank));
  }

  Widget _createRow(String id, String name, bool isEven, BuildContext context) {
    var isSelected =
        [_selected.id, _selected.label].join("_") == [id, name].join("_");

    var checkboxWidget = _checkBox(id, name, isSelected);

    var rowWdg = Row(
      children: [
        const SizedBox(
          width: 15,
        ),
        SizedBox(
          width: 50,
          child: checkboxWidget,
        ),
        buildInfoBoxIcon(id, name, context),
        //Flexible allows text wrapping in the row
        Flexible(
            child: Text(
          name,
          style: Styles.text,
        )),
      ],
    );

    return Container(
      constraints: const BoxConstraints(minHeight: 45),
      color: isEven ? Styles.evenRow : Styles.oddRow,
      child: rowWdg,
    );
  }

  @override
  IdElement getValue() {
    return _selected;
  }

  @override
  bool isFulfilled() {
    return getValue().id != "";
  }

  @override
  ComponentType getComponentType() {
    return ComponentType.list;
  }

  @override
  void setValue(IdElement value) {
    _selected = value;
  }

  @override
  void reset() {
    _selected = IdElement("", "");
  }
}