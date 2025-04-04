import 'package:flutter/material.dart';


import 'package:sci_tercen_client/sci_client.dart' as sci;
import 'package:webapp_components/components/fetch_component.dart';
import 'package:webapp_components/components/multi_check_component.dart';
import 'package:webapp_components/definitions/functions.dart';
import 'package:webapp_components/extra/modal_Screen_base.dart';
import 'package:webapp_components/mixins/component_base.dart';

import 'package:webapp_components/mixins/component_cache.dart';
import 'package:webapp_components/mixins/state_component.dart';
import 'package:webapp_components/widgets/wait_indicator.dart';
import 'package:webapp_components/widgets/widget_builder.dart';
import 'package:webapp_model/webapp_table.dart';
import 'package:webapp_ui_commons/styles/styles.dart';
import 'package:webapp_utils/functions/list_utils.dart';

import 'package:flutter/material.dart';
import 'package:webapp_components/abstract/serializable_component.dart';

import 'package:webapp_components/definitions/component.dart';
import 'package:webapp_components/mixins/component_base.dart';
import 'package:webapp_ui_commons/styles/styles.dart';

class MultiCheckComponentFetch
    extends FetchComponent
    implements SerializableComponent {
  final List<String> options = [];
  final List<String> selected = [];

  final int columns;
  final bool hasSelectAll;
  bool selectAll;
  late bool allSelected;
  double? columnWidth;
  final bool saveState;

  MultiCheckComponentFetch(id, groupId, componentLabel, super.dataFetchCallback,
      {this.columns = 5,
      this.hasSelectAll = false,
      this.selectAll = false,
      this.columnWidth,
      this.saveState = true}) {
    super.id = id;
    super.groupId = groupId;
    super.componentLabel = componentLabel;
    allSelected = selectAll;
  }

  void select(String el) {
    if (!selected.contains(el)) {
      selected.add(el);
      if (options.where((e) => selected.contains(e)).length == options.length) {
        allSelected = true;
      }
    }
  }

  @override
  WebappTable postLoad(WebappTable table){
    options.clear();
    options.addAll(table["label"]);
    return table;
  }

  void deselect(String el) {
    selected.remove(el);
    allSelected = false;
  }


  void onCheckClicked(Map<String, dynamic> params , bool newCheckValue ){
    print("OnCloick: $params $newCheckValue $selected");
    var name = params["name"]!;
    var onClick = params["onClick"];

    if( newCheckValue == true ){
      select(name);
    }else{
      deselect(name);
    }
    

    if (onClick != null) {
      onClick();
    }
    notifyListeners();
  }

  Widget checkBox(String name, bool isSelected, {Function? onClick}) {

    var checkIcon = CommonWidgets.checkbox( isSelected, onCheckClicked, {"name":name, "onClick":onClick} );

    return Row(
      children: [
        checkIcon,
        Text(
          name,
          style: Styles()["text"],
        )
      ],
    );
  }

  Widget selectAllCheckBox() {
    var checkIcon = Checkbox(        checkColor: Styles()["black"],
        side: WidgetStateBorderSide.resolveWith((states) => BorderSide(
              color: Styles()["black"],
              width: 1.5,
            )),
        fillColor:
            WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
          return Styles()["clear"];
        }),
        value: allSelected, onChanged: (value){
          if (!allSelected) {
            for (var opt in options) {
              if (!selected.contains(opt)) {
                select(opt);
              }
            }
            allSelected = true;
          } else {
            for (var opt in options) {
              if (selected.contains(opt)) {
                deselect(opt);
              }
            }
            allSelected = false;
          }

          notifyListeners();
    });


    return Row(
      children: [
        checkIcon,
        Text(
          "Select All",
          style: Styles()["text"],
        )
      ],
    );
  }

  TableRow createSelectAllRow() {
    int nCols = options.length > columns ? columns : options.length;
    List<Widget> rowWidgets = [];

    rowWidgets.add(selectAllCheckBox());
    for (var ci = 1; ci < nCols; ci++) {
      rowWidgets.add(Container());
    }

    return TableRow(children: rowWidgets);
  }

  bool isSelected(String name){
    return selected.contains(name);
  }

  Widget buildCheckTable() {
    int nCols = options.length > columns ? columns : options.length;
    int nRows = (options.length / columns).ceil();

    int idx = 0;
    List<TableRow> tableRows = [];
    if (hasSelectAll) {
      tableRows.add(createSelectAllRow());
    }

    for (var ri = 0; ri < nRows; ri++) {
      List<Widget> rowWidgets = [];
      for (var ci = 0; ci < nCols; ci++) {
        if (idx < options.length) {
          rowWidgets.add(checkBox(options[idx], isSelected(options[idx])));
          idx++;
        } else {
          rowWidgets.add(Container());
        }
      }

      tableRows.add(TableRow(children: rowWidgets));
    }

    Map<int, TableColumnWidth>? colWidthMap;
    if (columnWidth != null) {
      colWidthMap = {};
      for (var ci = 0; ci < nCols; ci++) {
        colWidthMap[ci] = FixedColumnWidth(columnWidth!);
      }
    }

    return Table(
      columnWidths: colWidthMap,
      children: tableRows,
    );
  }

  @override
  Widget buildContent(BuildContext context) {
    return buildCheckTable();
  }

  void setOptions(List<String> optList) {
    //Handled by data fetch
  }

  @override
  bool isFulfilled() {
    return getComponentValue().isNotEmpty;
  }

  @override
  ComponentType getComponentType() {
    return ComponentType.simple;
  }

  @override
  void reset() {
    selected.clear();
  }

  @override
  getComponentValue() {
    return selected;
  }

  @override
  String getStateValue() {
    return selected.join("|@|");
  }

  @override
  void setComponentValue(value) {
    selected.clear();
    selected.addAll(value);
  }

  @override
  void setStateValue(String value) {
    selected.clear();
    selected.addAll(value.split("|@|"));
  }

  @override
  bool shouldSaveState() {
    return saveState;
  }
}


// class MultiCheckComponentFetch extends  MultiCheckComponent
//     with ComponentCache, StateComponent {
//   DataFetchCallback optionsFetchCallback;
//   final String emptyMessage;

//   String displayColumn = "";
//   bool isInit = false;
//   WebappTable optionTable = WebappTable();

//   MultiCheckComponentFetch(
//       super.id, super.groupId, super.componentLabel, this.optionsFetchCallback,
//       {super.columns = 5,
//       this.emptyMessage = "No data available",
//       super.hasSelectAll = false,
//       super.selectAll = false,
//       super.columnWidth,
//       super.saveState,
//       this.displayColumn = ""});

//   Future<WebappTable> fetchCachedOptions() async {
//     var key = getKey();
//     if (hasCachedValue(key)) {
//       return getCachedValue(key);
//     } else {
//       var val = await optionsFetchCallback();
//       addToCache(key, val);
//       return val;
//     }
//   }

//   void loadSelection() {
//     var key = "${getKey()}_selection";
//     if (hasCachedValue(key)) {
//       selected.addAll(getCachedValue(key));
//     }
//   }

//   @override
//   void reset() {
//     super.reset();
//     isInit = false;
//     options.clear();
//     init().then((_) => postInit());
//   }

//   @override
//   Future<void> init() async {
//     await super.init();

//     if (isActive()) {
//       await loadOptions();
//       loadSelection();
//       isInit = true;
//     }

//     notifyListeners();
//   }

//   Future<void> loadOptions() async {
//     if (!isInit) {
//       busy();
//       optionTable = await fetchCachedOptions();
//       options.clear();
//       if (optionTable.nRows > 0) {
//         if (displayColumn == "") {
//           displayColumn = optionTable.colNames[0];
//         }
//         options.addAll(optionTable.columns[displayColumn]!);
//         if (selectAll) {
//           for (var opt in options) {
//             select(opt);
//           }
//         }
//       }
//       idle();
//     }
//   }

//   Widget buildCountWidget(BuildContext context) {
//     List<Widget> rowWidgets = [];

//     rowWidgets.add(Text(
//       "${selected.length}/${options.length} selected",
//       style: Styles()["text"],
//     ));

//     rowWidgets.add(IconButton(
//         onPressed: () {
//           var modalCheck = MultiCheckComponent("${id}_modal", getGroupId(), "",
//               columns: 5,
//               columnWidth: columnWidth,
//               selectAll: false,
//               hasSelectAll: true,
//               saveState: false);
//           modalCheck.setOptions(options);
//           for (var opt in selected) {
//             modalCheck.select(opt);
//           }

//           var selectionScreen =
//               ModalScreenBase("Marker Selection", [modalCheck]);
//           selectionScreen.addListener(() {
//             selected.clear();
//             selected.addAll(modalCheck.selected);

//             selectAll = false;

//             notifyListeners();
//           });
//           selectionScreen.build(context);
//         },
//         icon: const Icon(Icons.library_add_check_outlined)));

//     return Row(
//       children: rowWidgets,
//     );
//   }

//   @override
//   Widget buildContent(BuildContext context) {
//     if (isBusy) {
//       return TercenWaitIndicator().waitingMessage(suffixMsg: "Loading data");
//     } else {
//       return buildCountWidget(context); //super.buildCheckTable();
//     }
//   }

//   WebappTable getComponentValueAsTable() {
//     List<int> indices = [];
//     for (var s in selected) {
//       indices.addAll(ListUtils.indexWhereAll(optionTable[displayColumn], s));
//     }
//     indices.sort();
//     return optionTable.select(indices);
//   }

//   @override
//   void setOptions(List<String> optList) {
//     throw ServiceError(
//         500, "Options must be retrieved using the fetch callback function");
//   }
// }
