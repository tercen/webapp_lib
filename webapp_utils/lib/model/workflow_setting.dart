class WorkflowSetting {
  final String name;
  final String value;
  final String type;
  final List<String> options = [];

  WorkflowSetting( this.name, this.value, this.type, { List<String> opOptions = const []} ){
    if( opOptions.isNotEmpty ){
      options.addAll(opOptions);
    }
  }

}