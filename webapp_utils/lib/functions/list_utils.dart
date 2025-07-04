import 'package:webapp_utils/functions/string_utils.dart';

class ListUtils {
  static int _extractNumber(String s) {
    final match = RegExp(r'\d+').firstMatch(s);
    return match != null ? int.parse(match.group(0)!) : 0;
  }

  static List<int> _argsort<T>(List<T> list, int Function(T a, T b) compare) {
    final indices = List<int>.generate(list.length, (i) => i);
    indices.sort((i, j) => compare(list[i], list[j]));
    return indices;
  }

  static List<int> getSortedIndices(List<String> values,
      {bool checkAlphanumeric = false}) {
    if (checkAlphanumeric == true) {
      final hasNumberRegex = RegExp(r'\d+');
      bool allHaveNumbers = values.every((s) => hasNumberRegex.hasMatch(s));

      return allHaveNumbers
          ? ListUtils._argsort(
              values,
              (a, b) => ListUtils._extractNumber(a)
                  .compareTo(ListUtils._extractNumber(b)))
          : ListUtils._argsort(values, (a, b) => a.compareTo(b));
    }else{
      return ListUtils._argsort(values, (a, b) => a.compareTo(b));
    }

    // List<int> indices = [];

    // var labelList = values.map((e) => e).toList();
    // var sortedLabels = List<String>.from(labelList);

    // sortedLabels.sort();

    // for (var v in sortedLabels) {
    //   var idx = labelList.indexWhere((e) => v == e);
    //   labelList[idx] = StringUtils.getRandomString(5);

    //   indices.add(idx);
    // }

    // return indices;
  }

  static List<int> indexWhereAll(
      List<dynamic> valueList, dynamic selectedValue) {
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

  static List<int> indexWhereAllContains(List<String> valueList, String val) {
    List<int> indices = [];
    var idx = 0;

    while (true) {
      idx = valueList.indexWhere((e) => e.contains(val), idx);

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
