import 'dart:convert';


import 'package:flutter/material.dart';


import 'package:file_picker/file_picker.dart';

import 'package:flutter_dropzone/flutter_dropzone.dart';
import 'package:webapp_components/components/upload_multi_file_component.dart';
import 'package:webapp_utils/services/file_data_service.dart';

import 'dart:typed_data';
import 'package:sci_tercen_client/sci_client_service_factory.dart' as tercen;
import 'package:sci_tercen_client/sci_client.dart';


class UploadTableComponent extends UploadFileComponent {
  UploadTableComponent(super.id, super.groupId, super.componentLabel, super.projectId, super.fileOwner, {
    super.folderId, super.allowedMime, super.maxHeight = 400, super.multiFile = true, super.fetchProjectFiles,
    super.maxWidth, super.showUploadButton = true
  });

  @override
  Future<void> doUpload(BuildContext context) async{
    openDialog(context);
    log("File upload in progress. Please wait.", dialogTitle: "File Uploading");

    for( int i = 0; i < htmlFileList.length; i++ ){
      DropzoneFileInterface file = htmlFileList[i];
      
      log("Uploading ${file.name}", dialogTitle: "File Uploading");
      var bytes = await dvController.getFileData(file);
      var fileId = await uploadFileAsTable(file.name, projectId, fileOwner, bytes, folderId: folderId);
      uploadedFileIds.add(fileId);
      uploadedFilenames.add( file.name);
    }

    for( int i = 0; i < platformFileList.length; i++ ){
      PlatformFile file = platformFileList[i];
      var bytes = file.bytes!;
      log("Uploading ${file.name}", dialogTitle: "File Uploading");

      var fileId = await uploadFileAsTable(file.name, projectId, fileOwner, bytes, folderId: folderId);
      uploadedFileIds.add(fileId);
      uploadedFilenames.add( file.name);
    }


    closeLog();

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

    print("Adding column $colName of type $dataType ($values)");

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


  Future<String> uploadFileAsTable(String filename, String projectId, String owner, Uint8List data, {String folderId = ""} ) async {
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