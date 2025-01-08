
import 'package:sci_tercen_client/sci_client.dart' as sci;
import 'package:webapp_model/id_element.dart';
import 'package:webapp_utils/functions/list_utils.dart';



class IdElementTable {
  final Map<String, List<IdElement>> columns = {};
  final List<String> colNames = [];

  void addColumn( String columnName, {List<IdElement>? data}){
    columns[columnName] = [];
    colNames.add(columnName);
    if( data != null ){
      columns[columnName]?.addAll(data);
    }
  }

  int nRows(){
    if( colNames.isEmpty){
      return 0;
    }
    return columns[colNames[0]]!.length;
  }


  List<IdElement> getValuesByRow(int row, {List<String>? cols}){
    List<IdElement> rowValues = [];

    cols ??= colNames;

    for( var colName in cols ){
      rowValues.add( columns[colName]![row] );
    }

    return rowValues;
  }

  List<IdElement>? getValuesByIndex(int colIndex){
    return columns[colNames[colIndex]];
  }

  List<IdElement>? getValuesByName(String colName){
    return columns[colName];
  }

  IdElementTable filterAndTable(  String column, List<String> filters ){
    var idxList = ListUtils.indexWhereAllContains(this[column].map((e) => e.label.toLowerCase()).toList(), filters.first.toLowerCase());

    for( var filter in filters ){
      var newIdx = ListUtils.indexWhereAllContains(this[column].map((e) => e.label.toLowerCase()).toList(), filter.toLowerCase());

      idxList = idxList.toSet().intersection(newIdx.toSet()).toList();

    }

    var idx = idxList.toSet().toList();

    for( var col in this.colNames) {
      this.columns[col] = idx.map((e) => this[col][e]).toList();
    }

    return this;
  }


  IdElementTable filterOrTable(  String column, List<String> filters ){
    var idxList = [];

    for( var filter in filters ){
      idxList.addAll(ListUtils.indexWhereAllContains(this[column].map((e) => e.label.toLowerCase()).toList(), filter.toLowerCase()));
    }

    var idx = idxList.toSet().toList();

    for( var col in this.colNames) {
      this.columns[col] = idx.map((e) => this[col][e]).toList();
    }

    return this;
  }

  @override
  String toString(){
    if( columns.isEmpty || colNames.isEmpty ){
      return "";
    }else{
      String str = "";
      for( var colName in colNames ){
        str += colName;
        str += ",";
      }
      str += "\n";

      int nRows = columns[colNames[0]]!.length;
      for( var i = 0; i < nRows; i ++ ){
        for( var colName in colNames ){
          str += columns[colName]![i].label;
          str += ",";
        }
        str += "\n";
      }

      return str;
    }
    
  }



  void operator []=(String column, List<IdElement> values){
    columns[column] = values;
  }

  List<IdElement> operator [](String column){
    if( !columns.containsKey(column) ){
      return [];
    }else{
      return columns[column]!;
    }
  }


  static IdElementTable fromTable(sci.Table tercenTbl){
    IdElementTable uiTable = IdElementTable();

    for (var col in tercenTbl.columns) {
      var vals = (col.values as List)
          .map((e) => IdElement(e.toString(), e.toString()))
          .toList();
      uiTable.addColumn(col.name, data: vals);
    }
    return uiTable;
  }
}