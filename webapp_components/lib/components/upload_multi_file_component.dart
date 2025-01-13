import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dropzone/flutter_dropzone.dart';
import 'package:webapp_components/abstract/multi_value_component.dart';
import 'package:webapp_components/definitions/component.dart';
import 'package:webapp_components/mixins/component_base.dart';
import 'package:webapp_model/id_element.dart';
import 'package:webapp_ui_commons/mixin/progress_log.dart';
import 'package:webapp_ui_commons/styles/styles.dart';
import 'package:webapp_utils/services/file_data_service.dart';

class UploadFile {
  String filename;
  bool uploaded;

  UploadFile(this.filename, this.uploaded);
}

class UploadFileComponent with ChangeNotifier, ComponentBase, ProgressDialog implements MultiValueComponent {
  late FilePickerResult result;
  late DropzoneViewController dvController;
  Color dvBackground = Colors.white;
  final List<DropzoneFileInterface> htmlFileList = [];
  final List<PlatformFile> platformFileList = [];
  final List<UploadFile> filesToUpload = [UploadFile("Drag Files Here", false)];

  final List<IdElement> uploadedFiles = [];

  final String projectId;
  final String fileOwner;
  final String folderId;

  UploadFileComponent(this.projectId, this.fileOwner, {this.folderId = ""});

  Widget buildSingleFileWidget(BuildContext context){
    return Row(
      children: [
        InkWell(
          onTap: () async {
            result = (await FilePicker.platform.pickFiles(allowMultiple: false))!;
            for(var f in result.files){
              processSingleFileDrop(f);
            }
          },
          child: const Icon(Icons.add_circle_outline_rounded),
        )
      ],
    );
  }


  List<Widget> buildDragNDropFileList(){
    List<Widget> wdgList = [];
    for(int i = 0; i < filesToUpload.length; i++){
      if( filesToUpload[i].filename != "Drag Files Here"){
        Row entry = Row(
          children: [
            filesToUpload[i].uploaded 
                  ? const Icon(Icons.check) 
                  : InkWell(
                        child: const Icon(Icons.delete),
                        onTap: () {
                          filesToUpload.removeAt(i);  
                          notifyListeners();                         
                        },
                    ), 
            Text(filesToUpload[i].filename, style: Styles.text)
          ],
        );           
        wdgList.add(entry);
      }else{
        wdgList.add(Text(filesToUpload[i].filename, style: Styles.text));
      }
    }

    return wdgList;
  }


  Widget buildDragNDropWidget(BuildContext context){
    return Stack(
      children: [
        Container(
          constraints: BoxConstraints(minHeight: 100, minWidth: 200),
          decoration: BoxDecoration(border: Border.all(color: Colors.blueGrey), borderRadius: BorderRadius.circular(2.0),color: dvBackground,),
              child: ListView(
                scrollDirection: Axis.vertical,
                children: buildDragNDropFileList(),
              ),

        ),
        Container(
          constraints: BoxConstraints(minHeight: 100, minWidth: 200),
          child: DropzoneView(
            operation: DragOperation.copy,
            onCreated: (ctrl) => dvController = ctrl,
            onLeave: () {
              dvBackground = Colors.white;
              notifyListeners();
            },
            onHover: () {
              dvBackground = Colors.cyan.shade50;
              notifyListeners();
            },
            onDropFile:  (ev) async => processSingleFileDrop(ev),
            onDropFiles: (dynamic ev) => (List<dynamic> ev) => print('Drop multiple: $ev'),
          ),
        )
      ],
    );
  }

  

  Widget buildUploadActionWidget(BuildContext context){
    var isEnabled = filesToUpload.isNotEmpty;
    return ElevatedButton(
      style: isEnabled
          ? Styles.buttonEnabled
          : Styles.buttonDisabled,
      onPressed: () async{
        isEnabled ? await doUpload(context) : null;
      }, 
      child: const Text("Upload", style: Styles.textButton,));
  }

  @override
  Widget buildContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildSingleFileWidget(context),
        buildDragNDropWidget(context),
        buildUploadActionWidget(context)
      ],
    );
  }

  Future<void> doUpload(BuildContext context) async{
    openDialog(context);
    log("File upload in progress. Please wait.", dialogTitle: "File Uploading");
    
    var fileService = FileDataService();

    for( int i = 0; i < htmlFileList.length; i++ ){
      
      DropzoneFileInterface file = htmlFileList[i];
      log("Uploading ${file.name}", dialogTitle: "File Uploading");
      var bytes = await dvController.getFileData(file);

      var fileId = await fileService.uploadFile(file.name, projectId, fileOwner, bytes, folderId: folderId);
      uploadedFiles.add(IdElement(fileId, file.name));
    }

    for( int i = 0; i < platformFileList.length; i++ ){
      PlatformFile file = platformFileList[i];
      var bytes = file.bytes!;
      log("Uploading ${file.name}", dialogTitle: "File Uploading");

      var fileId = await fileService.uploadFile(file.name, projectId, fileOwner, bytes, folderId: folderId);
      uploadedFiles.add(IdElement(fileId, file.name));
    }
    closeLog();

  }

 
  void processSingleFileDrop(ev){
    if (ev is DropzoneFileInterface) {
      updateFilesToUpload(ev);
    } 

    if( ev is PlatformFile){
      updateFilesToUploadSingle(ev);
    }
    notifyListeners();
  }

  void updateFilesToUpload(DropzoneFileInterface wf){
    if( filesToUpload[0].filename == "Drag Files Here"){
      filesToUpload.removeAt(0);
    }
    filesToUpload.add(UploadFile(wf.name, false));

    htmlFileList.add(wf);
  }

  void updateFilesToUploadSingle(PlatformFile wf){
    if( filesToUpload[0].filename == "Drag Files Here"){
      filesToUpload.removeAt(0);
    }
    filesToUpload.add(UploadFile(wf.name, false));

    platformFileList.add(wf);
  }



  @override
  ComponentType getComponentType() {
    return ComponentType.table;
  }

  @override
  List<IdElement> getValue() {
    return filesToUpload.map((e) => IdElement(e.filename, e.filename) ).toList();
  }

  @override
  bool isFulfilled() {
    return filesToUpload.isNotEmpty;
  }

  @override
  void setValue(List<IdElement> value) {
    
  }

}