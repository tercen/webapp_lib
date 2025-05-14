import 'package:sci_tercen_client/sci_client.dart' as sci;
import 'package:sci_tercen_client/sci_client_service_factory.dart' as tercen;
import 'package:tson/tson.dart' as tson;
import 'package:uuid/uuid.dart';
import 'package:webapp_ui_commons/mixin/progress_log.dart';
import 'package:webapp_utils/services/app_user.dart';
// Run an operator which requires a documentId as input
//FINISH this runner

typedef TableFetchCallback = Future<sci.Table> Function(
    String computationTaskId);

class IdOperatorRunner with ProgressDialog {
  final String opUrl;
  final String? opVersion;

  int latestTicket = 0;

  final Map<String, dynamic> cache = {};
  //   String projectId = widget.handler.getModelValue(ModelKey.project).id;
  //   String teamName = widget.handler.getModelValue(ModelKey.selectedTeam);
  IdOperatorRunner(this.opUrl, {this.opVersion});
  Future<sci.Document> _getLatestOperatorVersion(String url,
      {bool tagged = true}) async {
    var factory = tercen.ServiceFactory();
    var ops = await factory.documentService.findOperatorByUrlAndVersion(
        startKey: [url, "\uff00"], endKey: [url, ""], limit: 1000);

    var operator = sci.Document();

    var latestVersion = DateTime.parse('1974-03-20 00:00:00.000');
    for (var op in ops) {
      if( opVersion != null && op.version == opVersion){
        operator = op;
        break;
      }
      if (opVersion == null && (tagged == false || op.version.contains("."))) {
        var opVersion = DateTime.parse(op.lastModifiedDate.value);

        if (opVersion.compareTo(latestVersion) > 0) {
          latestVersion = opVersion;
          operator = op;
        }
      }
    }

    if( operator.id == ""){
      throw sci.ServiceError(500, "operator.not.found", "Operator with URL $url $opVersion has not been found in the library");
    }

    return operator;
  }

  Future<sci.RunComputationTask> _setupRun(
      String documentId) async {
    sci.Document op = await _getLatestOperatorVersion(opUrl);

    // Prepare the computation task
    sci.CubeQuery query = sci.CubeQuery();
    query.operatorSettings.operatorRef.operatorId = op.id;
    query.operatorSettings.operatorRef.operatorKind = op.kind;
    query.operatorSettings.operatorRef.name = op.name;
    query.operatorSettings.operatorRef.version = op.version;

    // Query Projection
    sci.Factor docFactor = sci.Factor()
      ..name = "documentId"
      ..type = "string";

    query.colColumns.add(docFactor);

    var uuid = const Uuid();
    // Data to feed projection
    sci.Table tbl = sci.Table();
    tbl.nRows = 1;

    sci.Column col = sci.Column()
      ..name = "documentId"
      ..type = "string"
      ..id = "documentId"
      ..nRows = 1
      ..size = -1
      ..values = tson.CStringList.fromList([uuid.v4()]);

    tbl.columns.add(col);

    col = sci.Column()
      ..name = ".documentId"
      ..type = "string"
      ..id = ".documentId"
      ..nRows = 1
      ..size = -1
      ..values = tson.CStringList.fromList([documentId]);

    tbl.columns.add(col);

    var id = uuid.v4();
    sci.InMemoryRelation rel = sci.InMemoryRelation()
      ..id = id
      ..inMemoryTable = tbl;

    query.relation = rel;
    query.axisQueries.add(sci.CubeAxisQuery());

    sci.RunComputationTask compTask = sci.RunComputationTask()
      ..state = sci.InitState()
      ..owner = AppUser().teamname
      ..query = query
      ..projectId = AppUser().projectId;

    return compTask;
  }

  Future<sci.Table> run(String documentId,
      TableFetchCallback? tableFetchCallback) async {
    // addToQueue(documentId);
    latestTicket += 1;

    sci.Table result = sci.Table();
    var factory = tercen.ServiceFactory();

    var task = await _setupRun(documentId);

    if (cache.containsKey(documentId)) {
      print("Returning cached result");
      return cache[documentId];
    }

    task = await factory.taskService.create(task) as sci.RunComputationTask;
    await factory.taskService.runTask(task.id);
    task =
        await factory.taskService.waitDone(task.id) as sci.RunComputationTask;

    if (tableFetchCallback != null) {
      // if( model != null){
      //   model.log("Fetching results");
      // }
      result = await tableFetchCallback(task.id);
      cache[documentId] = result;
    }

    return result;
  }
}
