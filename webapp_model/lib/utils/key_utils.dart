class KeyUtils {
  static int listToKey(List values) {
    return values.map((v) => v.toString()).join().hashCode;
  }

  static int valueToKey(String value) {
    return value.hashCode;
  }
}
