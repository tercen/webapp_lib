class ListUtils{
  static List<int> getSortedIndices( List<String> values ){
    List<int> indices = [];

    var labelList = values.map((e) => e ).toList();
    var sortedLabels = List<String>.from(labelList);

    sortedLabels.sort();

    for( var v in sortedLabels ){
      indices.add( labelList.indexWhere((e) => v == e) );
    }


    return indices;
  }

  static List<int> indexWhereAll(List<dynamic> valueList, dynamic selectedValue) {
    List<int> indices = [];
    var idx = 0;

    while (true) {
      idx = valueList.indexWhere((e) => e == selectedValue, idx);

      if (idx >= 0) {
        indices.add(idx);
        idx = idx + 1;
      } else {
        break;
      }
    }

    return indices;
  }

}