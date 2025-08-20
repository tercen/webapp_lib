class IdLabel {
  final String id;
  final String? rev;
  final String label;
  final String? kind;

  IdLabel({required this.id, this.rev, required this.label, this.kind});


  @override
  bool operator ==(Object other) {
    return other is IdLabel && other.id == id;
  }
}