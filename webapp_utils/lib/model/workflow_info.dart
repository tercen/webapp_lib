class WorkflowInfo {
  final String iid;
  final String name;
  final String url;
  final String version;
  bool installed = false;

  WorkflowInfo(this.iid, this.name, this.url, this.version);
}