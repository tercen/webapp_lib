import 'dart:convert';
import 'dart:typed_data';
import 'package:sci_tercen_client/sci_client_service_factory.dart' as tercen;
import 'package:sci_tercen_client/sci_client.dart';

class FileDataService {
  static final FileDataService _singleton = FileDataService._internal();

  factory FileDataService() {
    return _singleton;
  }

  FileDataService._internal();

  Future<String> uploadFile(
      {required String filename,
      required projectId,
      required String owner,
      required Uint8List data,
      String folderId = ""}) async {
    final docToUpload = FileDocument()
      ..name = filename
      ..projectId = projectId
      ..metadata.contentType = "application/octet-stream"
      ..folderId = folderId
      ..acl.owner = owner;

    var file = await tercen.ServiceFactory()
        .fileService
        .upload(docToUpload, Stream.fromIterable([data]));
    return file.id;
  }

  Future<List<String>> downloadFileLinesAsString(String fileId,
      {int numLines = 5}) async {
    var factory = tercen.ServiceFactory();

    var splitter = LineSplitter()
        .bind(factory.fileService.download(fileId).transform(utf8.decoder))
        .take(numLines);

    List<String> lines = [];
    await splitter.forEach((e) {
      lines.add(e);
    });

    return lines;
  }

  Future<String> uploadFileAsTable(
      {required projectId,
      required String filename,
      required String owner,
      required Uint8List data,
      String folderId = ""}) async {
    var factory = tercen.ServiceFactory();
    var fileId = await uploadFile(
        projectId: projectId,
        filename: filename,
        owner: owner,
        data: data,
        folderId: folderId);
    var csvTask = CSVTask()
      ..state = InitState()
      ..owner = owner
      ..projectId = projectId
      ..fileDocumentId = fileId;

    csvTask = await factory.taskService.create(csvTask) as CSVTask;
    await factory.taskService.runTask(csvTask.id);
    await factory.taskService.waitDone(csvTask.id);
    csvTask = await factory.taskService.get(csvTask.id) as CSVTask;

    //FIXME Test to make sure folderId is truly being ignored during creation
    var schema = await factory.tableSchemaService.get(csvTask.schemaId);
    if (folderId != "") {
      schema.folderId = folderId;

      await factory.tableSchemaService.update(schema);
    }

    return schema.id;
  }


  Future<Schema> _createFileSchema(String fileId, {String separator = ","}) async {
    var fileService = FileDataService();
    var numLines = 5;
    var csvLines = await fileService.downloadFileLinesAsString(fileId, numLines: numLines);
    var headers = csvLines.first.split(separator);


    List<List<String>> columns = [];
    for( var line = 1; line< csvLines.length; line++){
      var lineVals = csvLines[line].split(separator);
      for( var col = 0; col < headers.length; col++){
        var v = lineVals[col];
        line == 1 ? columns.add([v]) : columns[col].add(v);
      }
    }

    
    var factory = tercen.ServiceFactory();
    var file = await factory.fileService.get(fileId);
    var sch = Schema()
    ..name = file.name
    ..projectId = file.projectId
    ..acl.owner = file.acl.owner;
    
    for( var col = 0; col < headers.length; col++){
      sch.columns.add( columnFromCsvColumn( headers[col], columns[col]  ) );
    }

    
    
    
    sch = await factory.tableSchemaService.create(sch);
    


    return sch;
  }

    bool isNumeric(String s) {
    return double.tryParse(s) != null;
  }

  bool isInt( String s){
    return int.tryParse(s) != null;
  }

  bool checkAll( List array, Function test ){
    var allEq = true;

    for( var v in array ){
      allEq = allEq && test(v);
    }
    return allEq;
  }
    ColumnSchema columnFromCsvColumn( String colName, List<dynamic> values ){
    
    var dataType = "string";
    print("Parsing ${values.first} - ${double.tryParse(values.first)}");
    
    if( checkAll(values, isNumeric) ){
      dataType = "double"; //checkAll(values, isInt) ? "int32" : "double";
    }


    return ColumnSchema(  )
        ..name = colName
        ..id = colName
        ..type = dataType;
      
  }

  String inferContentTypeByName( String filename ){
    String type = "text/csv";

    if( filename.toLowerCase().endsWith("tsv")){
      type = "text/tsv";
    }

    return type;
  }

  String getSeparator(String contentType){
    String sep = ',';
    if( contentType == "text/tsv"){
      sep = '\t';
    }

    return sep;
  }


  Future<String> uploadFileAsTable2({required String filename, required String projectId, required String owner, required Uint8List data, String folderId = ""} ) async {
    var factory = tercen.ServiceFactory();
    var contentType = inferContentTypeByName(filename);
    var metadata = CSVFileMetadata()
      ..separator = getSeparator(contentType)
      ..quote = '"'
      ..contentType = contentType
      ..contentEncoding = utf8.name;


    var docToUpload = FileDocument()
        ..name = filename
        ..projectId = projectId
        ..folderId = folderId
        ..acl.owner = owner
        ..metadata = metadata;



    var file = await factory.fileService.upload(docToUpload, Stream.fromIterable([data]) );


    var parserParams = CSVParserParam()
    ..separator = getSeparator(contentType)
    ..quote = '"'
    ..hasHeaders = true
    ..encoding = utf8.name;
    
    var inputSchema = await _createFileSchema(file.id, separator: getSeparator(contentType));



    
    var csvTask = CSVTask()
    ..fileDocumentId = file.id
    ..schema = inputSchema
    ..projectId = projectId
    ..owner = file.acl.owner
    ..params = parserParams
    ..state = InitState();



    csvTask =
        await factory.taskService.create(csvTask) as CSVTask;


    var stream = taskStream(csvTask.id);


    await for (var _ in stream) {
      // print(evt.toJson());
    }

    csvTask =
        await factory.taskService.get(csvTask.id) as CSVTask;


    return csvTask.schemaId;

  }

  Stream<TaskEvent> taskStream(String taskId) async* {
    var factory = tercen.ServiceFactory();
    bool startTask = true;
    var task = await factory.taskService.get(taskId);

    while (!task.state.isFinal) {
      var taskStream = factory.eventService
          .listenTaskChannel(taskId, startTask)
          .asBroadcastStream();

      startTask = false;
      await for (var evt in taskStream) {
        yield evt;
      }
      task = await factory.taskService.get(taskId);

    }

  }
}
