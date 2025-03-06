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
  List<String>? allowedMime;

  final List<IdElement> uploadedFiles = [];

  final String projectId;
  final String fileOwner;
  final String folderId;
  final double maxHeight;
  final double? maxWidth;
  final bool multiFile;
  final bool showUploadButton;

  UploadFileComponent(id, groupId, componentLabel, this.projectId, this.fileOwner, {
    this.folderId = "", this.allowedMime, this.maxHeight = 400, this.multiFile = true,
    this.maxWidth, this.showUploadButton = true}){
    super.id = id;
    super.groupId = groupId;
    super.componentLabel = componentLabel;

  }

  Widget buildSingleFileWidget(BuildContext context){
    return InkWell(
          onTap: () async {
            result = (await FilePicker.platform.pickFiles(allowMultiple: false))!;
            for(var f in result.files){
              processSingleFileDrop(f);
            }
            notifyListeners();
          },
          child: Row(
            children: [
              Text("Select file    ", style: Styles()["text"],),
              Icon(Icons.add_circle_outline_rounded)
            ],
          ),
        );
  }

  bool isUploaded( String filename ){
    return uploadedFiles.map((e) => e.label).any((fname) => fname == filename);
  }

  List<Widget> buildDragNDropFileList(){
    List<Widget> wdgList = [];
    for(int i = 0; i < filesToUpload.length; i++){
      if( filesToUpload[i].filename != "Drag Files Here"){
        
        Row entry =  Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            isUploaded(filesToUpload[i].filename)
                  ? const Icon(Icons.check) 
                  : InkWell(
                        child: const Icon(Icons.delete),
                        onTap: () {
                          filesToUpload.removeAt(i);  
                          if( filesToUpload.isEmpty){
                            filesToUpload.add(UploadFile("Drag Files Here", false));
                          }
                          notifyListeners();                         
                        },
                    ), 
            Text(filesToUpload[i].filename, style: Styles()["text"])
          ],
        );           
        wdgList.add(entry);
      }else{
        wdgList.add(Text(filesToUpload[i].filename, style: Styles()["text"]));
      }
    }

    return  wdgList;
  }


  Widget buildDragNDropWidget(BuildContext context){

    return Stack(
      children: [
        
          Container(
          constraints:  maxWidth == null ? BoxConstraints(minHeight: 100, minWidth: 100, maxHeight: this.maxHeight) : BoxConstraints(minHeight: 100, minWidth: 100, maxWidth: maxWidth!, maxHeight: this.maxHeight),
          child:  DropzoneView(
            mime: allowedMime,
            
            operation: DragOperation.copy,
            onCreated: (ctrl) => dvController = ctrl,

            onDropInvalid: (value) {
              dvBackground = Colors.white;
              notifyListeners();
            },
            onLeave: () {
              dvBackground = Colors.white;
              notifyListeners();
            },
            onHover: () {
              dvBackground = Colors.cyan.shade50;
              notifyListeners();
            },
            onDropFile: (ev) async {
              processSingleFileDrop(ev);
              dvBackground = Colors.white;
              notifyListeners();
            },
            onDropFiles: (dynamic ev) {
              (List<dynamic> ev) => print('Drop multiple: $ev');
              dvBackground = Colors.white;
              notifyListeners();
            } ,
          ),
        ),
        Container(
          constraints:  maxWidth == null ? BoxConstraints(minHeight: 100, minWidth: 100, maxHeight: this.maxHeight) : BoxConstraints(minHeight: 100, minWidth: 100, maxWidth: maxWidth!, maxHeight: this.maxHeight),
          decoration: BoxDecoration(border: Border.all(color: Colors.blueGrey), borderRadius: BorderRadius.circular(2.0),color: dvBackground,),
          child: SizedBox(
            height: double.maxFinite,
            width: double.maxFinite,
            child: ListView(

                scrollDirection: Axis.vertical,
                children: buildDragNDropFileList(),
              ))
        )
      ],
    );

  }


  
  

  Widget buildUploadActionWidget(BuildContext context){
    var isEnabled = filesToUpload.isNotEmpty;
    if( showUploadButton ){
      return ElevatedButton(
      style: isEnabled
          ? Styles()["buttonEnabled"]
          : Styles()["buttonDisabled"],
      onPressed: () async{
        isEnabled ? await doUpload(context) : null;
        notifyListeners();
      }, 
      child:  Text("Upload", style: Styles()["textButton"],));

    }else{
      return Container();
    }

  }

  @override
  Widget buildContent(BuildContext context) {
    var spacer = const SizedBox(height: 10,);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildSingleFileWidget(context),
        spacer,
        buildDragNDropWidget(context),
        spacer,
        buildUploadActionWidget(context)
      ],
    );
  }

  Future<void> doUpload(BuildContext context) async{
    if( showUploadButton ){
      openDialog(context);
      log("File upload in progress. Please wait.", dialogTitle: "File Uploading");
    }
    
    var fileService = FileDataService();

    for( int i = 0; i < htmlFileList.length; i++ ){
      
      DropzoneFileInterface file = htmlFileList[i];
      
      if( showUploadButton ){
        log("Uploading ${file.name}", dialogTitle: "File Uploading");
      }
      var bytes = await dvController.getFileData(file);
      var fileId = await fileService.uploadFile(file.name, projectId, fileOwner, bytes, folderId: folderId);
      uploadedFiles.add(IdElement(fileId, file.name));
    }

    for( int i = 0; i < platformFileList.length; i++ ){
      PlatformFile file = platformFileList[i];
      var bytes = file.bytes!;
      if( showUploadButton ){
        log("Uploading ${file.name}", dialogTitle: "File Uploading");
      }

      var fileId = await fileService.uploadFile(file.name, projectId, fileOwner, bytes, folderId: folderId);
      uploadedFiles.add(IdElement(fileId, file.name));
    }

    if( showUploadButton ){
      closeLog();
    }

  }

 
  void processSingleFileDrop(ev){
    if (ev is DropzoneFileInterface) {
      updateFilesToUpload(ev);
    } 

    if( ev is PlatformFile){
      updateFilesToUploadSingle(ev);
    }
    
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
    if( uploadedFiles.isEmpty ){
      return filesToUpload.map((e) => IdElement(e.filename, e.filename) ).toList();
    }else{
      return uploadedFiles;
    }
    
  }

  @override
  bool isFulfilled() {
    if( showUploadButton == true ){
      return uploadedFiles.isNotEmpty;
    }else{
      return filesToUpload.isNotEmpty && filesToUpload[0].filename != "Drag Files Here";
    }
  }

  @override
  void setValue(List<IdElement> value) {
    
  }

}