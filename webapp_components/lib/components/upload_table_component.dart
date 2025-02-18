import 'dart:convert';


import 'package:flutter/material.dart';


import 'package:file_picker/file_picker.dart';

import 'package:flutter_dropzone/flutter_dropzone.dart';
import 'package:webapp_components/components/upload_multi_file_component.dart';
import 'package:webapp_utils/services/file_data_service.dart';

import 'package:webapp_model/id_element.dart';

import 'dart:typed_data';
import 'package:sci_tercen_client/sci_client_service_factory.dart' as tercen;
import 'package:sci_tercen_client/sci_client.dart';


class UploadTableComponent extends UploadFileComponent {
  UploadTableComponent(super.id, super.groupId, super.componentLabel, super.projectId, super.fileOwner);

  @override
  Future<void> doUpload(BuildContext context) async{
    openDialog(context);
    log("File upload in progress. Please wait.", dialogTitle: "File Uploading");
    print("Uploading files. Owner is ${super.fileOwner}/$fileOwner");
    for( int i = 0; i < htmlFileList.length; i++ ){
      DropzoneFileInterface file = htmlFileList[i];
      
      log("Uploading ${file.name}", dialogTitle: "File Uploading");
      var bytes = await dvController.getFileData(file);
      var fileId = await uploadFile(file.name, projectId, fileOwner, bytes, folderId: folderId);
      uploadedFiles.add(IdElement(fileId, file.name));
    }

    for( int i = 0; i < platformFileList.length; i++ ){
      PlatformFile file = platformFileList[i];
      var bytes = file.bytes!;
      log("Uploading ${file.name}", dialogTitle: "File Uploading");

      var fileId = await uploadFile(file.name, projectId, fileOwner, bytes, folderId: folderId);
      uploadedFiles.add(IdElement(fileId, file.name));
    }


    closeLog();

  }

  @override
  List<IdElement> getValue() {
    if( uploadedFiles.isEmpty ){
      return filesToUpload.map((e) => IdElement(e.filename, e.filename) ).toList();
    }else{
      return uploadedFiles;
    }
    
  }

  bool isNumeric(String s) {
    return double.tryParse(s) != null;
  }

  bool isInt( String s){
    return int.tryParse(s) != null;
  }

  ColumnSchema columnFromCsvColumn( String colName, List<dynamic> values ){
    
    var dataType = "string";
    if(values.any((e) => !isNumeric(e))){
      dataType = values.any((e) => !isInt(e)) ? "double" : "int";
    }

    return ColumnSchema(  )
        ..name = colName
        ..id = colName
        ..type = dataType;
      
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


  Future<String> uploadFile(String filename, String projectId, String owner, Uint8List data, {String folderId = ""} ) async {
    var factory = tercen.ServiceFactory();

    var metadata = CSVFileMetadata()
      ..separator = ','
      ..quote = '"'
      ..contentType = 'text/csv'
      ..contentEncoding = utf8.name;


    var docToUpload = FileDocument()
        ..name = filename
        ..projectId = projectId
        ..folderId = folderId
        ..acl.owner = owner
        ..metadata = metadata;



    var file = await factory.fileService.upload(docToUpload, Stream.fromIterable([data]) );


    var parserParams = CSVParserParam()
    ..separator = ","
    ..quote = '"'
    ..hasHeaders = true
    ..encoding = utf8.name;
    
    var inputSchema = await _createFileSchema(file.id);



    
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


    await for (var evt in stream) {
      print(evt.toJson());
    }

    csvTask =
        await factory.taskService.get(csvTask.id) as CSVTask;

    print("FINISHED UPLOADING!");
    print(csvTask.toJson());
    // var sch = await factory.tableSchemaService.get(csvTask.schemaId);
    // sch.isHidden = false;
    // sch.isPublic = true;

    // await factory.tableSchemaService.update(sch);


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