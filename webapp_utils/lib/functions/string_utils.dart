import 'dart:math';

class StringUtils {
  static const _chars =
      'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
  static Random _rnd = Random();

  static String getRandomString(int length) =>
      String.fromCharCodes(Iterable.generate(length,
          (_) => _chars.codeUnitAt(StringUtils._rnd.nextInt(_chars.length))));

  static String removeNamespace(String name) {
    if (!name.endsWith("filename") &&
        !name.startsWith(".") &&
        name.contains(".")) {
      return name.split(".").sublist(1).join(".");
    } else {
      return name;
    }
  }
}
