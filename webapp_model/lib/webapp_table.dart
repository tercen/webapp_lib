
import 'dart:collection';

import 'package:sci_tercen_client/sci_client.dart' as sci;
import 'package:webapp_model/id_element.dart';
import 'package:webapp_model/utils/key_utils.dart';
import 'package:webapp_utils/functions/list_utils.dart';



class WebappTable extends IterableBase<WebappTable>{
  final Map<String, List<String>> columns = {};
  final List<String> colNames = [];

  int get nRows {
    if( colNames.isEmpty){
      return 0;
    }
    return columns[colNames[0]]!.length;
  }
  int get nCols => colNames.length;

  bool rowContains( int rowNum, String value, String colName,{ bool isContains = false}){
    if( rowNum >= nRows ){
      return false;
    }
    var rowTbl = select([rowNum]);

    
    if( isContains ){
      if( rowTbl[colName].first.contains(value) ){
        return true;
      }
    }else{
      if( rowTbl[colName].first == value ){
        return true;
      }
    }
  
    return false;
  }


  WebappTable selectByColValue( List<String> cols, List<String> values) {
    try {
      assert( cols.length == values.length );  
    } catch (e) {
      sci.ServiceError( 500, "WebappTable: Column Names length must be equal to values length");
    }
    
    var outTbl = WebappTable();
    List<List<String>> rows = [];
    var idxList = List<int>.generate( cols.length, (i) => i );

    for (var row = 0; row < nRows; row++) {
      var rowHasValue = !idxList.map((idx) => rowContains( row, values[idx], cols[idx])).any((test) => test == false);
      if(rowHasValue){
        rows.add(getValuesByRow(row));
      }
    }

    
    for (var col = 0; col < nCols; col++) {
      outTbl.addColumn(colNames[col],
          data: rows.map((row) => row[col]).toList());
    }
    
    return outTbl;
  }

  WebappTable selectByHash(List<int> keys) {
    var outTbl = WebappTable();
    List<List<String>> rows = [];
    for (var row = 0; row < nRows; row++) {

      var rowHash =
          KeyUtils.listToKey(columns.values.map((e) => e[row]).toList());
      if (keys.contains(rowHash)) {
        rows.add(columns.values.map((e) => e[row]).toList());
      }
    }

    for (var col = 0; col < nCols; col++) {
      outTbl.addColumn(colNames[col],
          data: rows.map((row) => row[col]).toList());
    }

    return outTbl;
  }

  bool hasColumn(String colName){
    return colNames.contains(colName);
  }

  void addColumn( String columnName, {List<String>? data}){
    columns[columnName] = [];
    colNames.add(columnName);
    if( data != null ){
      columns[columnName]?.addAll(data);
    }


  }


  void append(WebappTable otherTable){
    assert( colNames.length == otherTable.colNames.length );
    for( var cn in colNames ){
      assert( otherTable.colNames.contains(cn));

      columns[cn]!.addAll(otherTable[cn]);
    }
  }

  void removeColumn( String colName ){
    if( hasColumn(colName)){
      columns.remove(colName);
      colNames.remove(colName);
    }
  }

  WebappTable select(List<int> rows, {List<String>? cols}){
    cols ??= colNames;

    var outTbl = WebappTable();

    for( var colName in cols ){
      List<String> rowValues = [];
      for( var row in rows ){
        rowValues.add( columns[colName]![row] );
      }
      outTbl.addColumn(colName, data:rowValues);
      
    }

    return outTbl;
  }


  List<String> getValuesByRow(int row, {List<String>? cols}){
    List<String> rowValues = [];

    cols ??= colNames;

    for( var colName in cols ){
      rowValues.add( columns[colName]![row] );
    }

    return rowValues;
  }

  List<String>? getValuesByIndex(int colIndex){
    return columns[colNames[colIndex]];
  }

  List<String>? getValuesByName(String colName){
    return columns[colName];
  }

  WebappTable filterAndTable(  String column, List<String> filters ){
    var idxList = ListUtils.indexWhereAllContains(this[column].map((e) => e.toLowerCase()).toList(), filters.first.toLowerCase());

    for( var filter in filters ){
      var newIdx = ListUtils.indexWhereAllContains(this[column].map((e) => e.toLowerCase()).toList(), filter.toLowerCase());

      idxList = idxList.toSet().intersection(newIdx.toSet()).toList();

    }

    var idx = idxList.toSet().toList();

    for( var col in this.colNames) {
      this.columns[col] = idx.map((e) => this[col][e]).toList();
    }

    return this;
  }


  WebappTable filterOrTable(  String column, List<String> filters ){
    var idxList = [];

    for( var filter in filters ){
      idxList.addAll(ListUtils.indexWhereAllContains(this[column].map((e) => e.toLowerCase()).toList(), filter.toLowerCase()));
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
          str += columns[colName]![i];
          str += ",";
        }
        str += "\n";
      }

      return str;
    }
    
  }



  void operator []=(String column, List<String> values){
    columns[column] = values;
  }

  List<String> operator [](String column){
    if( !columns.containsKey(column) ){
      return [];
    }else{
      return columns[column]!;
    }
  }


  static WebappTable fromTable(sci.Table tercenTbl){
    WebappTable uiTable = WebappTable();

    for (var col in tercenTbl.columns) {
      var vals = (col.values as List)
          .map((e) => e.toString() )
          .toList();
      uiTable.addColumn(col.name, data: vals);
    }
    return uiTable;
  }
  
  @override
  Iterator<WebappTable> get iterator => WebappTableIterator(this);

}

class WebappTableIterator implements Iterator<WebappTable>{
  WebappTable table;
  int _currentRow = 0;
  
  WebappTableIterator( this.table);

  @override
  WebappTable get current => table.select([_currentRow]).first;

  @override
  bool moveNext() {
    _currentRow++;
    return _currentRow < table.nRows;
  }

}