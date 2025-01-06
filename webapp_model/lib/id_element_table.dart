

import 'package:webapp_model/id_element.dart';



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

  
  List<IdElement> operator [](String column){
    if( !columns.containsKey(column) ){
      return [];
    }else{
      return columns[column]!;
    }

  }
}