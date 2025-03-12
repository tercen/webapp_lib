class WorkflowSetting {
  final String name;
  final String value;
  final String type;
  final String description;
  final bool isSingleSelection;
  final List<String> options = [];

  WorkflowSetting( this.name, this.value, this.type, this.description, { List<String> opOptions = const [], this.isSingleSelection = false} ){
    if( opOptions.isNotEmpty ){
      options.addAll(opOptions);
    }
  }

}