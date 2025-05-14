import 'dart:convert';
import 'dart:typed_data';
import 'package:sci_tercen_client/sci_client_service_factory.dart' as tercen;
import 'package:sci_tercen_client/sci_client.dart';
import 'package:webapp_utils/services/app_user.dart';

class FileDataService{
  static final FileDataService _singleton = FileDataService._internal();
  
  factory FileDataService() {
    return _singleton;
  }
  
  FileDataService._internal();

  Future<String> uploadFile(String filename, String owner, Uint8List data, {String folderId = ""} ) async {
    var factory = tercen.ServiceFactory();

    FileDocument docToUpload = FileDocument()
        ..name = filename
        ..projectId = AppUser().projectId
        ..folderId = folderId
        ..acl.owner = owner;

    var file = await factory.fileService.upload(docToUpload, Stream.fromIterable([data]) );
    return file.id;

  }

  Future<List<String>> downloadFileLinesAsString(String fileId, {int numLines = 5} )  async {
    
    var factory = tercen.ServiceFactory();
    
    var splitter = LineSplitter().bind(factory.fileService.download(fileId).transform(utf8.decoder)  ).take(numLines);
    
    List<String> lines = [];
    await splitter.forEach( (e) {
      lines.add(e);
    });

    return lines;
  }

  Future<String> uploadFileAsTable(String filename,  String owner, Uint8List data, {String folderId = ""}) async{
    var factory = tercen.ServiceFactory();
    var fileId = await uploadFile(filename, owner, data, folderId: folderId);
    var csvTask = CSVTask()
      ..state = InitState()
      ..owner = owner
      ..projectId = AppUser().projectId
      ..fileDocumentId = fileId;

    csvTask = await factory.taskService.create(csvTask) as CSVTask;
    await factory.taskService.runTask(csvTask.id);
    await factory.taskService.waitDone(csvTask.id);
    csvTask = await factory.taskService.get(csvTask.id) as CSVTask;

    var schema = await factory.tableSchemaService.get(csvTask.schemaId);
    if(folderId != "" ){
      schema.folderId = folderId;

      await factory.tableSchemaService.update(schema);
    }

    return schema.id;
  }
}