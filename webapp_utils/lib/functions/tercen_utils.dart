import 'package:sci_tercen_client/sci_client.dart';
import 'package:webapp_utils/functions/string_utils.dart';

class TercenUtils {
  static Table joinTables( Table tbl1, Table tbl2, List<String> onl, List<String> onr, {List<String> excludeColumns = const []}){
    List<List> newColumnValues = [];
    int numCols = tbl1.columns.length + tbl2.columns.length - excludeColumns.length;
    for( var i = 0; i < numCols; i++){
      newColumnValues.add([]);
    }
    var tbl1Cols = tbl1.columns.where((col) => onl.any((onk) => col.name.contains(onk)) );
    var tbl2Cols = tbl2.columns.where((col) => onr.any((onk) => col.name.contains(onk)) );
    var tbl1AllCols = tbl1.columns.where((col) => !excludeColumns.contains(col.name) );
    var tbl2AllCols = tbl2.columns.where((col) => !excludeColumns.contains(col.name) );

    final tbl2Index = <String, List<int>>{};
    for( var ri2 = 0; ri2 < tbl2.nRows; ri2++){
      var key = tbl2Cols.map((col) => col.values[ri2]).join("_");
      tbl2Index.putIfAbsent(key, () => []).add(ri2);
    }

    for( var ri = 0; ri < tbl1.nRows; ri++){
      var lKeyVals = tbl1Cols.map((col) => col.values[ri]).join("_");
      final tbl2RowIndices = tbl2Index[lKeyVals];

      if( tbl2RowIndices!= null ){
        for( var ri2 in tbl2RowIndices ){
           var combinedValues = <dynamic>[];
            for (var col in tbl1AllCols  ) {
              combinedValues.add(col.values[ri]);
            }
            for (var col in tbl2AllCols) {
              combinedValues.add(col.values[ri2]);
            }

            for (var i = 0; i < combinedValues.length; i++) {
              newColumnValues[i].add(combinedValues[i]);
            }
        }
      }
    }

    var newTable = Table();
    newTable.nRows = tbl1.nRows;
    var ci = 0;
    for( var col in tbl1.columns){
      if( !excludeColumns.contains(col.name)){
        var newCol = Column();
        newCol.copyFrom(col);
        newCol.name = StringUtils.removeNamespace(newCol.name);
        newCol.id = StringUtils.removeNamespace(newCol.id);
        newCol.values = newColumnValues[ci];
        newCol.type = col.type;
        newTable.columns.add(newCol);
        ci++;
      }
    }
    for( var col in tbl2.columns){
      if( !excludeColumns.contains(col.name)){
        var newCol = Column();
        newCol.copyFrom(col);
        newCol.name = StringUtils.removeNamespace(newCol.name);
        newCol.id = StringUtils.removeNamespace(newCol.id);
        newCol.values = newColumnValues[ci];
        newCol.type = col.type;
        newTable.columns.add(newCol);
        ci++;
      }
    }

    return newTable;
  }

}