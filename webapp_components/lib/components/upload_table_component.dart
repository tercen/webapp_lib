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
        ..type = dataType;
      
  }

  Future<void> _createFileSchema(String fileId, {String separator = ","}) async {
    var fileService = FileDataService();
    var numLines = 5;
    print("Creating schema");
    var csvLines = await fileService.downloadFileLinesAsString(fileId, numLines: numLines);
    print("LINES!");
    print(csvLines);
    var headers = csvLines.first.split(separator);
    print("HEADERS>$headers");
    var numCols= headers.length;
    print("A");
    var lineIt = Iterable<int>.generate(numLines-1);
    print("B");
    var values = lineIt.map((line) => csvLines[line+1].split(separator)).toList();
    print("C");
    print(values);
    var colValues = lineIt.map( (line) => Iterable<int>.generate(numCols).map((colIdx) =>  values[line+1][colIdx] ).toList() ).toList();
    

    print("HEADER 1");
    print(headers.first);
    print("COLUMN 1");
    print(colValues.first);
    

    // var sch = Schema();
    // sch.columns.add(element)
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
    
    await _createFileSchema(file.id);


    var csvTask = CSVTask()
    ..fileDocumentId = file.id
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

    print("TASK INFO");
    print(csvTask.toJson());
    var sch = await factory.tableSchemaService.get(csvTask.schemaId);
    sch.isHidden = false;
    sch.isPublic = true;

    await factory.tableSchemaService.update(sch);

    return sch.id;

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