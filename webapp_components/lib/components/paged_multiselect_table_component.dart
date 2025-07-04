import 'package:flutter/material.dart';


import 'package:webapp_components/components/multiselect_table_component.dart';
import 'package:webapp_components/extra/infobox.dart';
import 'package:webapp_ui_commons/styles/styles.dart';
import 'package:webapp_utils/functions/list_utils.dart';

class PagedMultiselectTableComponent extends MultiSelectTableComponent {
  int pageSize;
  int currentPage = 1;
  final List<String> pagingOptions;

  PagedMultiselectTableComponent(
      super.id, super.groupId, super.componentLabel, super.dataFetchCallback,
      {super.excludeColumns,
      super.saveState = true,
      super.hideColumns,
      InfoBoxBuilder? infoBoxBuilder,
      super.columnOrder,
      this.pageSize = 20,
      this.pagingOptions = const ["-1", "10", "20", "50", "100"],
      cache = true}) {
    super.infoBoxBuilder = infoBoxBuilder;
    super.useCache = cache;
  }

  @override
  Widget createWidget(BuildContext context) {
    var table = dataTable;
    var nRows = table.nRows;

    var maxPages = pageSize > 0 ? (nRows / pageSize).ceil() : 1;

    colNames =
        columnOrder!.where((colName) => shouldIncludeColumn(colName)).toList();

    List<TableRow> rows = [];
    rows.add(createTableHeader(
        colNames.where((colName) => shouldDisplayColumn(colName)).toList()));

    var indices = List<int>.generate(nRows, (i) => i);
    if (sortDirection != "" && sortingCol != "") {
      indices = ListUtils.getSortedIndices(table.columns[sortingCol]!, checkAlphanumeric: true);

      if (sortDirection == "desc") {
        indices = indices.reversed.toList();
      }
    }

    var p0 = 0;
    var pf = nRows;
    if (pageSize > 0) {
      p0 = (currentPage - 1) * pageSize;
      pf = (currentPage) * pageSize;
      if (pf > nRows) {
        pf = nRows;
      }
      //Changed page size on an advanced page
      while (p0 >= pf) {
        currentPage = currentPage - 1;
        p0 = (currentPage - 1) * pageSize;
        pf = (currentPage) * pageSize - 1;
        if (pf > nRows) {
          pf = nRows;
        }
      }
    }

    for (var si = p0; si < pf; si++) {
      var ri = indices[si];
      var key = table[".key"][ri];
      var rowEls = colNames.map((col) => table[col][ri]).toList();

      rows.add(createTableRow(context, rowEls, key, rowIndex: si));
    }

    // rows.add(crreatePagingRow(p0, pf, maxPages));

    Map<int, TableColumnWidth> colWidths = infoBoxBuilder == null
        ? const {0: FixedColumnWidth(50), 1: FixedColumnWidth(10)}
        : {0: const FixedColumnWidth(50), 1: const FixedColumnWidth(50)};

    var tableWidget = Table(
      columnWidths: colWidths,
      children: rows,
    );

    return Column(
      children: [
        tableWidget,
        createPagingRow(p0, pf, maxPages)],
    );
  }

  Widget createPagingRow(int index0, int index1, int maxPages) {
    var dropDownWidget = DropdownButton(
        value: pageSize.toString(),
        items: pagingOptions
            .map((val) => DropdownMenuItem<String>(
                value: val,
                child: Text(
                  val == "-1" ? "All" : val.toString(),
                  style: Styles()["text"],
                )))
            .toList(),
        onChanged: (String? value) {
          if (value != null) {
            pageSize =  int.parse(value);
            notifyListeners();
          }
        });
    var row = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: dropDownWidget,
        ),
        Text(
          " rows per page ",
          style: Styles()["text"],
        ),
        Expanded(
            child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
                onPressed: () {
                  if (currentPage > 1) {
                    currentPage = currentPage - 1;
                    updateUiValue();
                  }
                },
                icon: Icon(
                  Icons.arrow_left_outlined,
                  color: Styles()["buttonBgLight"],
                )),
            Text(
              currentPage.toString(),
              style: Styles()["text"],
            ),
            Text(
              " / ",
              style: Styles()["text"],
            ),
            Text(
              maxPages.toString(),
              style: Styles()["text"],
            ),
            IconButton(
                onPressed: () {
                  if (currentPage < maxPages) {
                    currentPage = currentPage + 1;
                    updateUiValue();
                  }
                },
                icon: Icon(
                  Icons.arrow_right_outlined,
                  color: Styles()["buttonBgLight"],
                )),
          ],
        ))
      ],
    );
    return row;
  }
}
