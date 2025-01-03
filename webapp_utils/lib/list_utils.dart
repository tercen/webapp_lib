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

}