class IdElement {
  final String id;
  final String label;

  IdElement(this.id, this.label);

  @override
  String toString() {
    return "${id}IdElement${label}";
  }


  @override
  bool operator ==(Object other) =>
      other is IdElement &&
      other.runtimeType == runtimeType &&
      other.id == id;

  @override
  int get hashCode => id.hashCode;
}