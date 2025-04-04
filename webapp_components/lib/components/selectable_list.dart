import 'package:flutter/material.dart';

import 'package:webapp_components/abstract/serializable_component.dart';
import 'package:webapp_components/definitions/component.dart';

import 'package:webapp_components/components/fetch_component.dart';

import 'package:webapp_components/mixins/infobox_component.dart';
import 'package:webapp_components/widgets/widget_builder.dart';

import 'package:webapp_ui_commons/styles/styles.dart';
import 'package:webapp_utils/functions/list_utils.dart';

class SelectableListComponent extends FetchComponent
    with ComponentInfoBox
    implements SerializableComponent {
  final bool sortByLabel;
  String selected = "";

  late String Function(String, {String id}) labelTransformCallback;

  String? cacheKey;
  final bool shouldSave;

  SelectableListComponent(id, groupId, componentLabel, super.dataFetchFunc,
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

  @override
  Widget buildContent(BuildContext context) {
    return build(context);
  }

  @override
  Widget createWidget(BuildContext context) {
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

  // Widget checkBox(String id, String name) {
  //   return Checkbox(
  //       value: isSelected(id),
  //       side: WidgetStateBorderSide.resolveWith((states) => BorderSide(
  //             color: Styles()["black"],
  //             width: 1.5,
  //           )),
  //       checkColor: Styles()["black"],
  //       fillColor:
  //           WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
  //         return Color.fromARGB(255, 255, 255, 255);
  //       }),
  //       onChanged: (value) {
  //         if (value == true) {
  //           selected = id;
  //         } else {
  //           selected = "";
  //         }
  //         notifyListeners();
  //       });
  // }

  void onClick(Map<String, dynamic> params, bool isSelected)  {
    if (isSelected == true) {
      selected = params["id"];
    } else {
      selected = "";
    }
    notifyListeners();
  }

  Widget createRow(String id, String name, bool isEven, BuildContext context) {
    var checkboxWidget = CommonWidgets.checkbox(
        isSelected(id), onClick, {"id": id, "name": name});
    // checkBox(id, name);

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
    super.reset();
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
