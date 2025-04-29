import 'package:sci_tercen_client/sci_client.dart';
import 'package:webapp_utils/functions/string_utils.dart';

class TercenUtils {
  static Table joinTables( Table tbl1, Table tbl2, List<String> onl, List<String> onr, {List<String> excludeColumns = const []}){
    List<List> newColumnValues = [];
    int numCols = tbl1.columns.length + tbl2.columns.length - excludeColumns.length;
    for( var i = 0; i < numCols; i++){
      newColumnValues.add([]);
    }

    for( var ri = 0; ri < tbl1.nRows; ri++){
      var lKeyVals = tbl1.columns.where((col) => onl.contains(col.name)).map((col) => col.values[ri]).join("_");
      
      // ===================================
      //GET Values in tbl2 that match lKeyVals
      for( var ri2 = 0; ri2 < tbl2.nRows; ri2++){
        var rKeyVals = tbl2.columns.where((col) => onr.contains(col.name)).map((col) => col.values[ri2]).join("_");

        if( rKeyVals == lKeyVals ){

          var ci = 0;

          for( var col in tbl1.columns){
            if( !excludeColumns.contains(col.name)){
              newColumnValues[ci].add(col.values[ri]);
              ci++;
            }
          }

          for( var col in tbl2.columns){
            if( !excludeColumns.contains(col.name)){
              newColumnValues[ci].add(col.values[ri2]);
              ci++;
            }
          }
          break;
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