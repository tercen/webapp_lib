import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dropzone/flutter_dropzone.dart';
import 'package:list_picker/list_picker.dart';
import 'package:sci_tercen_client/sci_client.dart' as sci;
import 'package:webapp_components/abstract/component.dart';
import 'package:webapp_components/definitions/component.dart';
import 'package:webapp_components/mixins/component_base.dart';

import 'package:webapp_ui_commons/mixin/progress_log.dart';
import 'package:webapp_ui_commons/styles/styles.dart';
import 'package:webapp_utils/services/file_data_service.dart';

class UploadFile {
  String filename;
  bool uploaded;

  UploadFile(this.filename, this.uploaded);
}

class UploadFileComponent
    with ChangeNotifier, ComponentBase, ProgressDialog
    implements Component {
  late FilePickerResult result;

  Future<List<sci.ProjectDocument>> Function()? fetchProjectFiles;

  late DropzoneViewController dvController;
  Color dvBackground = Colors.white;
  final List<DropzoneFileInterface> htmlFileList = [];
  final List<PlatformFile> platformFileList = [];
  final List<UploadFile> filesToUpload = [UploadFile("Drag Files Here", false)];
  List<String>? allowedMime;

  final List<String> uploadedFileIds = [];
  final List<String> uploadedFilenames = [];

  final String projectId;
  final String fileOwner;
  final String folderId;
  final double maxHeight;
  final double? maxWidth;
  final bool multiFile;
  final bool showUploadButton;

  final List<String> options = [];
  final List<sci.ProjectDocument> optionDocs = [];

  UploadFileComponent(
      id, groupId, componentLabel, this.projectId, this.fileOwner,
      {this.folderId = "",
      this.allowedMime,
      this.maxHeight = 400,
      this.multiFile = true,
      this.maxWidth,
      this.showUploadButton = true,
      this.fetchProjectFiles}) {
    super.id = id;
    super.groupId = groupId;
    super.componentLabel = componentLabel;
  }

  Widget buildSingleFileWidget(BuildContext context) {
    return InkWell(
      onTap: () async {
        result = (await FilePicker.platform.pickFiles(allowMultiple: false))!;
        for (var f in result.files) {
          processSingleFileDrop(f);
        }
        notifyListeners();
      },
      child: Row(
        children: [
          Text(
            "Select local file    ",
            style: Styles()["text"],
          ),
          Icon(Icons.add_circle_outline_rounded)
        ],
      ),
    );
  }

  Future<void> loadOptions() async {
    if (fetchProjectFiles != null) {
      options.clear();
      optionDocs.clear();

      optionDocs.addAll(await fetchProjectFiles!());

      options.addAll(optionDocs.map((doc) => doc.name));
    }
  }

  Widget buildProjectFileWidget(BuildContext context) {
    return InkWell(
      onTap: () async {
        String filePath = (await showPickerDialog(
          context: context,
          label: "",
          items: options,
        ))!;
        if (filePath != "") {
          uploadedFilenames.add(filePath);
          uploadedFileIds
              .add(optionDocs.firstWhere((doc) => doc.name == filePath).id);

          if (filesToUpload[0].filename == "Drag Files Here") {
            filesToUpload.removeAt(0);
          }

          filesToUpload.add(UploadFile(filePath, true));
        }
        notifyListeners();
      },
      child: Row(
        children: [
          Text(
            "Select project file    ",
            style: Styles()["text"],
          ),
          Icon(Icons.add_circle_outline_rounded)
        ],
      ),
    );
  }

  bool isUploaded(String filename) {
    return uploadedFilenames.any((fname) => fname == filename);
  }

  List<Widget> buildDragNDropFileList() {
    List<Widget> wdgList = [];
    for (int i = 0; i < filesToUpload.length; i++) {
      if (filesToUpload[i].filename != "Drag Files Here") {
        Row entry = Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            isUploaded(filesToUpload[i].filename)
                ? const Icon(Icons.check)
                : InkWell(
                    child: const Icon(Icons.delete),
                    onTap: () {
                      filesToUpload.removeAt(i);
                      if (filesToUpload.isEmpty) {
                        filesToUpload.add(UploadFile("Drag Files Here", false));
                      }
                      notifyListeners();
                    },
                  ),
            Text(filesToUpload[i].filename, style: Styles()["text"])
          ],
        );
        wdgList.add(entry);
      } else {
        wdgList.add(Text(filesToUpload[i].filename, style: Styles()["text"]));
      }
    }

    return wdgList;
  }

  Widget buildDragNDropWidget(BuildContext context) {
    return Stack(
      children: [
        Container(
          constraints: maxWidth == null
              ? BoxConstraints(
                  minHeight: 100, minWidth: 100, maxHeight: this.maxHeight)
              : BoxConstraints(
                  minHeight: 100,
                  minWidth: 100,
                  maxWidth: maxWidth!,
                  maxHeight: this.maxHeight),
          child: DropzoneView(
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
            },
          ),
        ),
        Container(
            constraints: maxWidth == null
                ? BoxConstraints(
                    minHeight: 100, minWidth: 100, maxHeight: this.maxHeight)
                : BoxConstraints(
                    minHeight: 100,
                    minWidth: 100,
                    maxWidth: maxWidth!,
                    maxHeight: this.maxHeight),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.blueGrey),
              borderRadius: BorderRadius.circular(2.0),
              color: dvBackground,
            ),
            child: SizedBox(
                height: double.maxFinite,
                width: double.maxFinite,
                child: ListView(
                  scrollDirection: Axis.vertical,
                  children: buildDragNDropFileList(),
                )))
      ],
    );
  }

  Widget buildUploadActionWidget(BuildContext context) {
    var isEnabled = filesToUpload.isNotEmpty;
    if (showUploadButton) {
      return ElevatedButton(
          style: isEnabled
              ? Styles()["buttonEnabled"]
              : Styles()["buttonDisabled"],
          onPressed: () async {
            isEnabled ? await doUpload(context) : null;
            notifyListeners();
          },
          child: Text(
            "Upload",
            style: Styles()["textButton"],
          ));
    } else {
      return Container();
    }
  }

  Widget buildWidget(BuildContext context) {
    var spacer = const SizedBox(
      height: 10,
    );

    List<Widget> uploadWidgets = [buildSingleFileWidget(context), spacer];
    if (fetchProjectFiles != null) {
      uploadWidgets.addAll([buildProjectFileWidget(context), spacer]);
    }

    uploadWidgets.addAll([
      buildDragNDropWidget(context),
      spacer,
    ]);

    if (showUploadButton) {
      uploadWidgets.add(buildUploadActionWidget(context));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: uploadWidgets,
    );
  }

  @override
  Widget buildContent(BuildContext context) {
    if (fetchProjectFiles != null) {
      return FutureBuilder(
          future: loadOptions(),
          builder: (context, snapshot) {
            return buildWidget(context);
          });
    } else {
      return buildWidget(context);
    }
  }

  Future<void> doUpload(BuildContext context) async {
    if (showUploadButton) {
      openDialog(context);
      log("File upload in progress. Please wait.",
          dialogTitle: "File Uploading");
    }

    var fileService = FileDataService();

    for (int i = 0; i < htmlFileList.length; i++) {
      DropzoneFileInterface file = htmlFileList[i];

      if (showUploadButton) {
        log("Uploading ${file.name}", dialogTitle: "File Uploading");
      }
      var bytes = await dvController.getFileData(file);
      var fileId = await fileService.uploadFile(
          file.name, projectId, fileOwner, bytes,
          folderId: folderId);
      uploadedFileIds.add(fileId);
      uploadedFilenames.add(file.name);
    }

    for (int i = 0; i < platformFileList.length; i++) {
      PlatformFile file = platformFileList[i];
      var bytes = file.bytes!;
      if (showUploadButton) {
        log("Uploading ${file.name}", dialogTitle: "File Uploading");
      }

      var fileId = await fileService.uploadFile(
          file.name, projectId, fileOwner, bytes,
          folderId: folderId);
      uploadedFileIds.add(fileId);
      uploadedFilenames.add(file.name);
    }

    if (showUploadButton) {
      closeLog();
    }
  }

  void processSingleFileDrop(ev) {
    if (ev is DropzoneFileInterface) {
      updateFilesToUpload(ev);
    }

    if (ev is PlatformFile) {
      updateFilesToUploadSingle(ev);
    }
  }

  void updateFilesToUpload(DropzoneFileInterface wf) {
    if (filesToUpload[0].filename == "Drag Files Here") {
      filesToUpload.removeAt(0);
    }
    filesToUpload.add(UploadFile(wf.name, false));

    htmlFileList.add(wf);
  }

  void updateFilesToUploadSingle(PlatformFile wf) {
    if (filesToUpload[0].filename == "Drag Files Here") {
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
  bool isFulfilled() {
    if (showUploadButton == true) {
      return uploadedFileIds.isNotEmpty;
    } else {
      return filesToUpload.isNotEmpty &&
          filesToUpload[0].filename != "Drag Files Here";
    }
  }

  @override
  getComponentValue() {
    if (uploadedFileIds.isEmpty) {
      return filesToUpload.map((e) => e.filename).toList();
    } else {
      return uploadedFileIds;
    }
  }

  @override
  void setComponentValue(value) {
    // Not used
  }
}
